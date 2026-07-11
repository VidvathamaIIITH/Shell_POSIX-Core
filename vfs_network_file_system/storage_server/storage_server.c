#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <ifaddrs.h>
#include <pthread.h>
#include <errno.h>
#include "../common/error.h"

#define NM_PORT 8080              // Naming Server port
#define BUFFER_SIZE 1024          // Buffer size for messages
#define MAX_FILES 50              // Max number of files to store

unsigned int SS_PORT = 0;             // Storage Server port for client operations -> would be updated by the OS

char ss_ip[INET_ADDRSTRLEN]; // IPv4 address of the storage server
char accessible_paths[50*257];

// Structure to store file data in the Storage Server
typedef struct {
    char *filename;
    char data[BUFFER_SIZE];
    int in_use;
    int dir;
    int reg;
} FileEntry;

// Global array to store files
FileEntry file_storage[MAX_FILES];
int num_files = 0;

// Mutex for thread safety
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

// Function declarations
void* handle_client(void* client_socket); int err = 0;
void register_with_naming_server(const char* nm_ip, const char* accessible_paths);
void extract_and_store_files(char *accessible_paths);
int check_path(const char *path);
int add_file(const char* filename, const char* content);
int read_file(const char* filename, char* buffer);

// Main function to start the Storage Server
int main(int argc, char* argv[]) {
    int server_socket, client_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_len = sizeof(client_addr);

    // Ensure Naming Server IP is passed as argument
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <Naming_Server_IP>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    printf("ENTER accessible paths for the NM server: (! to stop)\n");
    int c, i=0;
    while ((c = getchar()) != '!'){
        if (c != '\n')
            accessible_paths[i++] = c;
        else accessible_paths[i++] = ' ';
    } accessible_paths[i]='\0';
    extract_and_store_files(accessible_paths);

    struct ifaddrs *ifaddr, *ifa;
    if (getifaddrs(&ifaddr) == 0) {
        for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr && ifa->ifa_addr->sa_family == AF_INET) {
                struct sockaddr_in *sa = (struct sockaddr_in *)ifa->ifa_addr;
                if (sa->sin_addr.s_addr != htonl(INADDR_LOOPBACK)) { // Ignore loopback
                    inet_ntop(AF_INET, &sa->sin_addr, ss_ip, sizeof(ss_ip));
                    break; // Use the first non-loopback address found
                }
            }
        }
        freeifaddrs(ifaddr);
    }

     // Initialize socket for client interactions
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(0);

    // Bind the socket to the specified port
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("Socket bind failed");
        close(server_socket);
        exit(EXIT_FAILURE);
    }

    socklen_t addr_len = sizeof(server_addr);
    // Get assigned port
    if (getsockname(server_socket, (struct sockaddr *)&server_addr, &addr_len) == -1) {
        perror("getsockname failed");
        close(server_socket);
        exit(1);
    }

    SS_PORT = ntohs(server_addr.sin_port); // Update the variable with the assigned port

    // Register with the Naming Server, providing accessible paths
    register_with_naming_server(argv[1], accessible_paths);

    printf("Storage Server started at IP: %s, Port: %d\n", ss_ip, SS_PORT);
   
    // Listen for incoming connections
    if (listen(server_socket, 5) < 0) {
        perror("Listen failed");
        close(server_socket);
        exit(EXIT_FAILURE);
    }

    // Accept and handle clients in a loop
    while (1) {
        client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
        if (client_socket < 0) {
            perror("Client connection failed");
            continue;
        }

        // Create a thread to handle each client
        pthread_t thread_id;
        pthread_create(&thread_id, NULL, handle_client, (void*)&client_socket);
        pthread_detach(thread_id);
    }

    close(server_socket);
    return 0;
}

int check_path(const char *path) {
    struct stat path_stat;

    // Get file status
    if (stat(path, &path_stat) != 0) {
        perror("stat failed");
        return;
    }

    // Check if it's a directory
    if (S_ISDIR(path_stat.st_mode)) {
        return 1;
    } 
    // Check if it's a regular file
    else if (S_ISREG(path_stat.st_mode)) {
        return 0;
    } 
    // Handle other types of files
    else {
        return 2;
    }
}

void extract_and_store_files(char *accessible_paths) {
    char *token;
    const char *delimiter = " ";
    char *paths; paths = strdup(accessible_paths);

    // Tokenize the input string
    token = strtok(paths, delimiter);
    while (token != NULL) {
        if (num_files >= MAX_FILES) {
            fprintf(stderr, "Maximum file storage limit reached\n");
            break;
        }
        
        // Allocate memory for the filename and populate FileEntry 
        FileEntry *entry = &file_storage[num_files];
        entry->filename = strdup(token);
        if (entry->filename == NULL) {
            fprintf(stderr, "Memory allocation failed for filename\n");
            exit(EXIT_FAILURE);
        }
        entry->reg = 1;
        entry->in_use = 0;   // Initialize in_use flag
        entry->dir = check_path(entry->filename);
        num_files++;

        // Get the next token
        token = strtok(NULL, delimiter);
    }
    free(paths);
}

// Function to register the Storage Server with the Naming Server
void register_with_naming_server(const char* nm_ip, const char* accessible_paths2) {
    int sock;
    struct sockaddr_in nm_addr;
    char buffer[BUFFER_SIZE];

    // Create socket for communication with the Naming Server
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    nm_addr.sin_family = AF_INET;
    nm_addr.sin_port = htons(NM_PORT);
    if (inet_pton(AF_INET, nm_ip, &nm_addr.sin_addr) <= 0) {
        fprintf(stderr, "Invalid Naming Server IP address\n");
        close(sock);
        exit(EXIT_FAILURE);
    }

    // Connect to the Naming Server
    if (connect(sock, (struct sockaddr*)&nm_addr, sizeof(nm_addr)) < 0) {
        perror("Connection to Naming Server failed");
        close(sock);
        exit(EXIT_FAILURE);
    }

    // Send registration message including IP, ports, and accessible paths
    snprintf(buffer, BUFFER_SIZE, "REGISTER %s %d %d %s", ss_ip, NM_PORT, SS_PORT, accessible_paths2);
    write(sock, buffer, strlen(buffer));
    
    // Receive confirmation
    read(sock, buffer, BUFFER_SIZE);
    printf("Naming Server: %s\n", buffer);

    close(sock);
}

// Function to handle client requests to the Storage Server
void* handle_client(void* client_socket) {
    int sock = *(int*)client_socket;
    char buffer[BUFFER_SIZE] = {NULL};
    char command[BUFFER_SIZE] = {NULL}, filename[256] = {NULL}, content[BUFFER_SIZE] = {NULL}, path[512] = {NULL}, misc[100] = {NULL};

    memset(buffer, 0, BUFFER_SIZE);
    read(sock, buffer, BUFFER_SIZE);
    // Parse the client command
    sscanf(buffer, "%s", command);

    pthread_mutex_lock(&mutex);  // Ensure thread safety

    if (strcmp(command, "CREATE") == 0 && sscanf(buffer, "%s %s %s %s", command, misc, path, filename) > 0){
        err = 0;
        FileEntry *f = malloc(sizeof(FileEntry));
        if (f == NULL){
            fprintf(stderr, "malloc failed\n");
            exit(EXIT_FAILURE);
        }
        if (path[0] == '~') {
            const char *home = getenv("HOME");
            if (home == NULL) {
                fprintf(stderr, "Cannot determine home directory\n");
                send_error(sock, ERR_FILE_NOT_FOUND, "File/folder creation failed. Cannot determine home directory\n");
                free(f);
                return;
            }
            // Construct full path
            char expanded_path[1024];
            if (path[1] == '/')
                snprintf(expanded_path, sizeof(expanded_path), "%s%s", home, path + 1); // Skip the '~'
            else snprintf(expanded_path, sizeof(expanded_path), "%s/%s", home, path + 1);
            strcpy(path, expanded_path);
        } else if (path[0] == '.') {
            char cwd[1024]; // Buffer to store the current working directory
            if (getcwd(cwd, sizeof(cwd)) == NULL) {
                perror("getcwd failed");
                send_error(sock, ERR_FILE_NOT_FOUND, "File/folder creation failed. Cannot determine current working directory\n");
                free(f);
                return;
            }
            // Construct full path
            char expanded_path[1024];
            if (path[1] == '/')
                snprintf(expanded_path, sizeof(expanded_path), "%s%s", cwd, path + 1); // Skip the '.'
            else snprintf(expanded_path, sizeof(expanded_path), "%s/%s", cwd, path + 1);
            strcpy(path, expanded_path);
        }
        strcat(path, "/");
        strcat(path, filename);
        f->filename = strdup(path);
        f->reg = 0;
        f->in_use = 0;
        file_storage[num_files++] = *f;
        if (strcmp(misc, "FILE") == 0){
            f->dir = 0;
            int pid = fork();
            if (pid < 0)
                printf("file creation failed\n");
            else if (pid == 0){
                char *arg[3]={"/usr/bin/touch", file_storage[num_files-1].filename, NULL};
                if (execve(arg[0], arg, NULL) < 0){
                    free(&file_storage[num_files-1]);
                    num_files--;
                    send_error(sock, ERR_FILE_ALREADY_EXISTS, "File/folder creation failed. Exec failed\n");
                    err = 1;
                    exit(EXIT_FAILURE);
                }
            }
            wait(NULL);
        } else if (strcmp(misc, "FOLDER") == 0){
            f->dir = 1;
            int pid = fork();
            if (pid < 0)
                printf("file creation failed\n");
            else if (pid == 0){
                char *arg[3]={"/usr/bin/mkdir", file_storage[num_files-1].filename,NULL};
                if (execve(arg[0], arg, NULL) < 0){
                    free(&file_storage[num_files-1]);
                    num_files--;
                    send_error(sock, ERR_FILE_ALREADY_EXISTS, "File/folder creation failed. Exec failed\n");
                    err = 1;
                    exit(EXIT_FAILURE);
                }
            }
            wait(NULL);
        }
        if (!err) write(sock, "File/folder created successfully\n", strlen("File/folder created successfully\n"));
    }

    else if (strcmp(command, "DELETE") == 0 && sscanf(buffer, "%s %s %s %s", command, misc, path, filename) > 0) {
        err = 0;
        FileEntry *f = malloc(sizeof(FileEntry));
        if (f == NULL) {
            fprintf(stderr, "malloc failed\n");
            exit(EXIT_FAILURE);
        }
        char *check = strdup(path);
        if (!filename[0]) filename[0] = '\0';
        if (filename[0] != '\0') strcat(check, "/");
        strcat(check, filename);
        if (path[0] == '~') {
            const char *home = getenv("HOME");
            if (home == NULL) {
                fprintf(stderr, "Cannot determine home directory\n");
                free(f);
                send_error(sock, ERR_FILE_NOT_FOUND, "File/folder deletion failed. Cannot determine home directory\n");
                err = 1;
                exit(EXIT_FAILURE);
            }
            // Construct full path
            char expanded_path[1024];
            if (path[1] == '/')
                snprintf(expanded_path, sizeof(expanded_path), "%s%s", home, path + 1); // Skip the '~'
            else snprintf(expanded_path, sizeof(expanded_path), "%s/%s", home, path + 1);
            strcpy(path, expanded_path);
        } else if (path[0] == '.') {
            char cwd[1024]; // Buffer to store the current working directory
            if (getcwd(cwd, sizeof(cwd)) == NULL) {
                perror("getcwd failed");
                send_error(sock, ERR_FILE_NOT_FOUND, "File/folder deletion failed. Cannot determine working directory\n");
                free(f);
                return;
            }
            // Construct full path
            char expanded_path[1024];
            if (path[1] == '/')
                snprintf(expanded_path, sizeof(expanded_path), "%s%s", cwd, path + 1); // Skip the '.'
            else snprintf(expanded_path, sizeof(expanded_path), "%s/%s", cwd, path + 1);
            strcpy(path, expanded_path);
        }
        //if (!filename[0]) filename[0] = '\0';
        if (filename[0] != '\0') strcat(path, "/");
        strcat(path, filename);
        printf("The file or folder to delete is %s\n", path);
        f->filename = strdup(path);
        f->in_use = 0;
        int i;
        err=1;
        for (i=0; i<num_files; i++){
            //printf("check : %s  file : %s\n", check, file_storage[i].filename);
            if (file_storage[i].reg){
                if (strcmp(check, file_storage[i].filename) == 0 && file_storage[i].in_use != -1){
                    file_storage[i].in_use = -1;
                    file_storage[i].reg = 0;
                    err=0;
                    free(check);
                    break;
                }
            } else {
                if (strcmp(f->filename, file_storage[i].filename) == 0 && file_storage[i].in_use != -1){
                    file_storage[i].in_use = -1;
                    err=0;
                    free(check);
                    break;
                }
            }
        }
        // Check if we are deleting a file or folder
        if (strcmp(misc, "FILE") == 0 && !err) {
            int pid = fork();
            if (pid < 0) {
                printf("File deletion failed\n");
            } else if (pid == 0) {
                // Use /usr/bin/rm for file deletion
                char *arg[3] = {"/usr/bin/rm", f->filename, NULL};
                if (execve(arg[0], arg, NULL) < 0) {
                    fprintf(stderr, "Failed to delete file %s\n", f->filename);
                    free(f);
                    send_error(sock, ERR_FILE_NOT_FOUND, "File deletion failed. Exec failed\n");
                    err = 1;
                    exit(EXIT_FAILURE); // Ensure the child exits
                }
            }
            wait(NULL); // Wait for the child process to complete
        } else if (strcmp(misc, "FOLDER") == 0 && !err) {
            int pid = fork();
            if (pid < 0) {
                printf("Folder deletion failed\n");
            } else if (pid == 0) {
                // Use /usr/bin/rmdir for folder deletion
                char *arg[3] = {"/usr/bin/rmdir", f->filename, NULL};
                if (execve(arg[0], arg, NULL) < 0) {
                    fprintf(stderr, "Failed to delete folder %s\n", f->filename);
                    free(f);
                    send_error(sock, ERR_FILE_NOT_FOUND, "Folder deletion failed. Exec failed\n");
                    err = 1;
                    exit(EXIT_FAILURE); // Ensure the child exits
                }
            }
            wait(NULL); // Wait for the child process to complete
        }
        if (!err) write(sock, "File/folder deleted successfully\n", strlen("File/folder deleted successfully\n"));
        else {free(check); write(sock, "File/folder deletion failed\n", strlen("File/folder deletion failed\n"));}
        free(f);
    }

    else if (strcmp(command, "IS_DIR") == 0 && sscanf(buffer, "%s %s", command, path) > 0){
        for (int i=0; i<num_files; i++){
            if (strcmp(path, file_storage[i].filename) == 0 && file_storage[i].in_use != -1){
                if (file_storage[i].dir){
                    write(sock, "YES", strlen("YES"));
                } else write(sock, "NO", strlen("NO"));
                break;
            }
        }
    }

    else if (strcmp(command, "LIST_DIR") == 0 && sscanf(buffer, "%s %s", command, path) > 0) {
        char file_list[MAX_FILES * 257] = {0};  // Initialize the buffer
        int ch = 0;
        int found_files = 0;
        // Construct full path
        char expanded_path[1024];
        if (path[0] == '~') {
            const char *home = getenv("HOME");
            if (home == NULL) {
                fprintf(stderr, "Cannot determine home directory\n");
                send_error(sock, ERR_FILE_NOT_FOUND, "File/folder copying failed. Cannot determine home directory\n");
            }
            if (path[1] == '/')
                snprintf(expanded_path, sizeof(expanded_path), "%s%s", home, path + 1); // Skip the '~'
            else snprintf(expanded_path, sizeof(expanded_path), "%s/%s", home, path + 1);
        } 
        else if (path[0] == '.') {
            char cwd[1024]; // Buffer to store the current working directory
            if (getcwd(cwd, sizeof(cwd)) == NULL) {
                perror("getcwd failed");
                send_error(sock, ERR_FILE_NOT_FOUND, "File/folder copying failed. Cannot determine current working directory\n");
            }
            if (path[1] == '/')
                snprintf(expanded_path, sizeof(expanded_path), "%s%s", cwd, path + 1); // Skip the '.'
            else snprintf(expanded_path, sizeof(expanded_path), "%s/%s", cwd, path + 1);
        }
        for (int i = 0; i < num_files; i++) {
            // Check if the file belongs to the directory and is not deleted
            if ((strncmp(file_storage[i].filename, path, strlen(path)) == 0 && 
                file_storage[i].in_use != -1 && file_storage[i].filename[strlen(path)] == '/' &&
                file_storage[i].filename[strlen(path)] != '\0') || (strncmp(file_storage[i].filename, expanded_path, strlen(expanded_path)) == 0 && 
                file_storage[i].in_use != -1 && file_storage[i].filename[strlen(expanded_path)] == '/' &&
                file_storage[i].filename[strlen(expanded_path)] != '\0')) {
                if (found_files > 0) {
                    file_list[ch++] = '\n';  // Add newline separator between file names
                }
                strcpy(&file_list[ch], file_storage[i].filename);
                ch += strlen(file_storage[i].filename);
                found_files++;
            }
        }
        printf("file list is %s\n", file_list);
        if (found_files > 0) {
            write(sock, file_list, ch);  // Send the file list to the client
        } else {
            send_error(sock, ERR_EMPTY_DIR, "No files in directory\n");
        }
    }

    else if (strcmp(command, "COPYSRC") == 0 && sscanf(buffer, "%s %s", command, path) > 0) {

        printf("the src path is %s\n", path);
        FILE *file = fopen(path, "r"); // Open the file in read mode
        if (!file) {
            // If the file doesn't exist or cannot be opened
            send_error(sock, ERR_FILE_NOT_FOUND, "File not found or can't be opened\n");
            write(sock, "\nFILE_TRANSFER_COMPLETE\n", strlen("\nFILE_TRANSFER_COMPLETE\n"));
            return;
        }
        // Buffer for file content
        char file_buffer[1024];
        size_t bytes_read;
        int total_bytes_sent = 0;

        // Read the file content in chunks and send it to the NM server
        while ((bytes_read = fread(file_buffer, 1, sizeof(file_buffer), file)) > 0) {
            // Send the current chunk to the NM server
            int bytes_sent = write(sock, file_buffer, bytes_read);
            if (bytes_sent < 0) {
                // Handle transmission error
                perror("ERROR: Failed to send file content");
                send_error(sock, ERR_PACKET_LOST, "File content couldn't be sent\n");
                fclose(file);
                write(sock, "\nFILE_TRANSFER_COMPLETE\n", strlen("\nFILE_TRANSFER_COMPLETE\n"));
                return;
            }
            total_bytes_sent += bytes_sent;
        }

        // Notify NM server that the file transfer is complete
        write(sock, "\nFILE_TRANSFER_COMPLETE\n", strlen("\nFILE_TRANSFER_COMPLETE\n"));

        // Close the file
        fclose(file);

        // Log success
        printf("Successfully sent %d bytes from file '%s' to the NM server\n", total_bytes_sent, path);
    }

    else if (strcmp(command, "COPYDEST") == 0 && sscanf(buffer, "%s %s %s", command, path, filename) > 0) {

        const char *remaining = buffer + strlen(command) + strlen(path) + strlen(filename) + 3; // +3 for spaces
        printf("%s %s\n",filename, buffer);
        strncpy(content, remaining, BUFFER_SIZE - 1);
        strcat(path, "/");
        strcat(path, filename);
        // Fork a child process to execute shell command
        pid_t pid = fork();

        if (pid == 0) { // Child process
            // Redirect standard input to send content to the file
            int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
            if (fd < 0) {
                perror("Failed to open file");
                send_error(sock, ERR_FILE_NOT_FOUND, "File/folder copying failed. Cannot open file\n");
                exit(1);
            }

            // Write content directly using exec and echo
            char escaped_content[15000];
            snprintf(escaped_content, sizeof(escaped_content), "'%s'", content);
            char cmd[15000];
            snprintf(cmd, sizeof(cmd), "echo %s > %s", escaped_content, path);
            execl("/bin/sh", "sh", "-c", cmd, NULL);
            perror("exec failed");
            send_error(sock, ERR_FILE_ALREADY_EXISTS, "File/folder copying failed. Cannot write content\n");
            write(sock, "File copy failed\n", strlen("File copy failed\n"));
            close(fd);
            return;
        } else if (pid > 0) { // Parent process
            // Wait for the child process to complete
            int status;
            waitpid(pid, &status, 0);
            if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
                printf("File %s successfully created with content.\n", path);
            }
            if (path[0] == '~') {
                const char *home = getenv("HOME");
                if (home == NULL) {
                    fprintf(stderr, "Cannot determine home directory\n");
                    send_error(sock, ERR_FILE_NOT_FOUND, "File/folder copying failed. Cannot determine home directory\n");
                    return;
                }
                // Construct full path
                char expanded_path[1024];
                if (path[1] == '/')
                    snprintf(expanded_path, sizeof(expanded_path), "%s%s", home, path + 1); // Skip the '~'
                else snprintf(expanded_path, sizeof(expanded_path), "%s/%s", home, path + 1);
                strcpy(path, expanded_path);
            } else if (path[0] == '.') {
                char cwd[1024]; // Buffer to store the current working directory
                if (getcwd(cwd, sizeof(cwd)) == NULL) {
                    perror("getcwd failed");
                    send_error(sock, ERR_FILE_NOT_FOUND, "File/folder copying failed. Cannot determine current working directory\n");
                    return;
                }
                // Construct full path
                char expanded_path[1024];
                if (path[1] == '/')
                    snprintf(expanded_path, sizeof(expanded_path), "%s%s", cwd, path + 1); // Skip the '.'
                else snprintf(expanded_path, sizeof(expanded_path), "%s/%s", cwd, path + 1);
                strcpy(path, expanded_path);
            }
            FileEntry *f = malloc(sizeof(FileEntry));
            f->filename = strdup(path);
            f->reg = 0;
            f->in_use = 0;
            f->dir = 0;
            file_storage[num_files++] = *f;
            write(sock, "File copied successfully\n", strlen("File copied successfully\n"));
        }
        else {
            printf("Failed to create file %s.\n", path);
        }
    }

    else if (strcmp(command, "READ") == 0 && sscanf(buffer, "%s %s", command, path) > 0) {
        // Open the file for reading
        int fd = open(path, O_RDONLY);
        if (fd < 0) {
            perror("Failed to open file");
            write(sock, "Error: File not found or cannot be opened\n", strlen("Error: File not found or cannot be opened\n"));
            return;
        }

        // Read the file in chunks and send to the client
        char read_buffer[BUFFER_SIZE];
        ssize_t bytes_read;
        while ((bytes_read = read(fd, read_buffer, sizeof(read_buffer) - 1)) > 0) {
            read_buffer[bytes_read] = '\0'; // Null-terminate the buffer
            if (write(sock, read_buffer, bytes_read) < 0) {
                perror("Failed to send file content to client");
                send_error(sock, ERR_PACKET_LOST, "File/folder reading failed. Cannot send content.\n");
                close(fd);
                return;
            }
        }

        if (bytes_read < 0) {
            perror("Failed to read from file");
            send_error(sock, ERR_FILE_NOT_FOUND, "Failed to read from file\n");
        } else {
            // End of file reached, indicate completion to the client
            write(sock, "STOP", strlen("STOP"));
        }

        close(fd); // Close the file descriptor 
    }

    else if (strcmp(command, "STAT") == 0 && sscanf(buffer, "%s %s", command, path) > 0) {
        struct stat file_stat;

        // Get file information using stat()
        if (stat(path, &file_stat) == -1) {
            perror("Failed to retrieve file information");
            send_error(sock, ERR_PERMISSION_DENIED, "Cannot retrieve file information\n");
            return;
        }

        // Extract file size and access permissions
        char response[BUFFER_SIZE];
        snprintf(response, sizeof(response),
                "File: %s\nSize: %ld bytes\nPermissions: %c%c%c%c%c%c%c%c%c\n",
                path,
                file_stat.st_size,
                (file_stat.st_mode & S_IRUSR) ? 'r' : '-',
                (file_stat.st_mode & S_IWUSR) ? 'w' : '-',
                (file_stat.st_mode & S_IXUSR) ? 'x' : '-',
                (file_stat.st_mode & S_IRGRP) ? 'r' : '-',
                (file_stat.st_mode & S_IWGRP) ? 'w' : '-',
                (file_stat.st_mode & S_IXGRP) ? 'x' : '-',
                (file_stat.st_mode & S_IROTH) ? 'r' : '-',
                (file_stat.st_mode & S_IWOTH) ? 'w' : '-',
                (file_stat.st_mode & S_IXOTH) ? 'x' : '-');

        // Send file information to the client
        if (write(sock, response, strlen(response)) < 0) {
            perror("Failed to send file information to client");
            send_error(sock, ERR_PACKET_LOST, "Failed to read file permissions. Can't send content\n");
            return;
        }
    }

    else if (strcmp(command, "STREAM") == 0 && sscanf(buffer, "%s %s", command, path) > 0) {
        FILE *file = fopen(path, "rb"); // Open the file in binary mode
        if (file == NULL) {
            perror("Failed to open file");
            send_error(sock, ERR_FILE_NOT_FOUND, "Cannot open audio file\n");
            return;
        }

        char buffer[BUFFER_SIZE];
        size_t bytes_read;

        // Read file and send data in chunks
        while ((bytes_read = fread(buffer, 1, sizeof(buffer), file)) > 0) {
            if (write(sock, buffer, bytes_read) < 0) {
                send_error(sock, ERR_PACKET_LOST, "Failed to stream audio\n");
                perror("Failed to send file chunk");
                break;
            }
        }

        fclose(file); // Close the file after streaming
        printf("File streaming completed for %s\n", path);
    }

    else if (strcmp(command, "WRITE") == 0 && sscanf(buffer, "%s %s", command, path) > 0) {
        char content[BUFFER_SIZE];

        // Extract the content that starts right after the path (space after path)
        const char *remaining = buffer + strlen(command) + strlen(path) + 2; // +2 for space after path
        strncpy(content, remaining, BUFFER_SIZE - 1);
        content[BUFFER_SIZE - 1] = '\0'; // Null-terminate content

        // Open the file for writing (create if not exist, truncate if exists)
        int fd = open(path, O_WRONLY | O_APPEND, 0644);
        if (fd < 0) {
            perror("Failed to open file for writing");
            send_error(sock, ERR_FILE_NOT_FOUND, "Cannot open file for writing\n");
            return;
        }

        // Write the content to the file
        if (write(fd, content, strlen(content)) != strlen(content)) {
            perror("Failed to write data to file");
            close(fd);
            send_error(sock, ERR_DISK_FULL, "Failed to write data to file\n");
            return;
        }

        // Notify client about successful writing
        write(sock, "File successfully written\n", strlen("File successfully written\n"));
        close(fd);
    }

    pthread_mutex_unlock(&mutex);  // Release lock
    close(sock);
    return NULL;
}
