/* ============================================================================
 *  Shell_POSIX-Core
 *  Author  : vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *  Unauthorized copying or false claim of authorship is prohibited.
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <ifaddrs.h>
#include <pthread.h>
#include "../common/efficiency.h"
#include <errno.h>
#include <time.h>
#include "../common/error.h"
#include "../common/log.h"

#define PORT 8080
#define BUFFER_SIZE 15000
#define MAX_STORAGE_SERVERS 10
#define MAX_FILES 50

// Global arrays for storage servers and file metadata
StorageServer storage_servers[MAX_STORAGE_SERVERS];
FileMetadata file_metadata[MAX_FILES];
int storage_server_count = 0;
int file_metadata_count = 0;

char reply_ss_to_nms[BUFFER_SIZE]; int content = 0; char msg[BUFFER_SIZE];

// Mutex for thread safety
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

// Function declarations
void* handle_client(void* client_socket);
void register_storage_server(char* ip, int nm_port, int port, char **paths, int path_count);
int send_command_to_storage_server(char* ip, int port, char* command);
StorageServer* find_storage_server(char* ip, int port);
FileMetadata* find_file_metadata(char* filename);
void add_file_metadata(char* filename, StorageServer* server);
void remove_storage_server(StorageServer* server);

// Main function to set up the Naming Server
int main() {

    // Initialize hashmap and LRU cache
    initializeHashmap();
    initializeLRUCache();
    initialize_log();

    int server_socket, client_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_len = sizeof(client_addr);
    char nm_ip[INET_ADDRSTRLEN];

    // Initialize the Naming Server socket
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    // Bind the socket to the specified port
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("Socket bind failed");
        close(server_socket);
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections
    if (listen(server_socket, 5) < 0) {
        perror("Listen failed");
        close(server_socket);
        exit(EXIT_FAILURE);
    }

    struct ifaddrs *ifaddr, *ifa;
    if (getifaddrs(&ifaddr) == 0) {
        for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr && ifa->ifa_addr->sa_family == AF_INET) {
                struct sockaddr_in *sa = (struct sockaddr_in *)ifa->ifa_addr;
                if (sa->sin_addr.s_addr != htonl(INADDR_LOOPBACK)) { // Ignore loopback
                    inet_ntop(AF_INET, &sa->sin_addr, nm_ip, sizeof(nm_ip));
                    break; // Use the first non-loopback address found
                }
            }
        }
        freeifaddrs(ifaddr);
    }

    printf("Naming Server started at IP: %s, Port: %d\n", nm_ip, PORT);
    snprintf(msg, 499, "Naming Server started at IP: %s, Port: %d\n", nm_ip, PORT);
    log_message(msg);
    memset(msg, 0, 500);

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

void get_remote_ip(int sock, const char *str) {
    struct sockaddr_in addr;
    socklen_t addr_len = sizeof(addr);

    if (getpeername(sock, (struct sockaddr *)&addr, &addr_len) == -1) {
        perror("getpeername failed");
        return;
    }

    char ip[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &addr.sin_addr, ip, sizeof(ip));
    snprintf(msg, BUFFER_SIZE, "Request from client IP: %s, Port: %d %s\n", ip, ntohs(addr.sin_port), str);
    log_message(msg);
}

// Function to handle client requests
void* handle_client(void* client_socket) {
    int sock = *(int*)client_socket;
    char buffer[BUFFER_SIZE];
    char command[BUFFER_SIZE], filename[100] = {NULL}, ip[INET_ADDRSTRLEN], accessible_paths[50*257], accessible_path[256], misc[100];
    char src_path[256], dest_path[256];
    int nm_port, port;
    char **paths = malloc(MAX_PATHS * sizeof(char *));
    if (paths == NULL){
        fprintf(stderr, "malloc failed\n");
        exit(EXIT_FAILURE);
    }
    int path_count = 0;

    memset(buffer, 0, BUFFER_SIZE);
    read(sock, buffer, BUFFER_SIZE);

    get_remote_ip(sock, buffer);
    // Parse the client command
    sscanf(buffer, "%s", command);
    
    pthread_mutex_lock(&mutex);  // Ensure thread safety
    memset(reply_ss_to_nms, 0, BUFFER_SIZE);

    if (strcmp(command, "REGISTER") == 0 && sscanf(buffer, "%s %s %d %d %12849[^\n]", command, ip, &nm_port, &port, accessible_paths) > 0) {
        // Extract accessible paths from buffer
        char delims[] = " ";
        path_count = 0;
        paths[path_count] = strtok(accessible_paths, delims);
        while (paths[path_count] != NULL){
            paths[++path_count] = strtok(NULL, delims);
        }
        register_storage_server(ip, nm_port, port, paths, path_count);
        write(sock, "Storage Server Registered\n", strlen("Storage Server Registered\n"));
        path_count = 0;
        free(paths);
    }

    else if (strcmp(command, "CREATE") == 0 && sscanf(buffer, "%s %s %s %s", command, misc, accessible_path, filename) > 0) {
        StorageServer* server = searchWithCache(accessible_path);
        if (server) {
            snprintf(buffer, BUFFER_SIZE, "CREATE %s %s %s", misc, accessible_path, filename);
            if (send_command_to_storage_server(server->ip, server->port, buffer) == -1){
                send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                pthread_mutex_unlock(&mutex);  // Release lock
                close(sock);
                return NULL;
            }
            write(sock, reply_ss_to_nms, strlen(reply_ss_to_nms));
            if (strstr(reply_ss_to_nms, "success")){
                strcat(accessible_path, "/");
                strcat(accessible_path, filename);
                hashmapInsert(accessible_path, server);
            }
        } else {
            // Seed the random number generator
            srand(time(NULL));
            // Generate a random integer between 0 and storage_server_count
            int random_index = rand() % (storage_server_count + 1);
            StorageServer* server = &storage_servers[random_index];
            if (server){
                snprintf(buffer, BUFFER_SIZE, "CREATE %s %s %s", misc, accessible_path, filename);
                if (send_command_to_storage_server(server->ip, server->port, buffer) == -1){
                    send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                    pthread_mutex_unlock(&mutex);  // Release lock
                    close(sock);
                    return NULL;
                }
                write(sock, reply_ss_to_nms, strlen(reply_ss_to_nms));
                if (strstr(reply_ss_to_nms, "success")){
                strcat(accessible_path, "/");
                strcat(accessible_path, filename);
                hashmapInsert(accessible_path, server);
                addToCache(accessible_path, server);
            }
            }
            else write(sock, "Storage Server not found\n", strlen("Storage Server not found\n"));
        }
    } 

    else if (strcmp(command, "DELETE") == 0 && sscanf(buffer, "%s %s %s %s", command, misc, accessible_path, filename) > 0) {
        StorageServer* server = searchWithCache(accessible_path);
        if (server) {
            if (!filename[0]){filename[0]='\0';}
            snprintf(buffer, BUFFER_SIZE, "DELETE %s %s %s", misc, accessible_path, filename);
            if (send_command_to_storage_server(server->ip, server->port, buffer) == -1){
                send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                pthread_mutex_unlock(&mutex);  // Release lock
                close(sock);
                return NULL;
            }
            write(sock, reply_ss_to_nms, strlen(reply_ss_to_nms));
            if (strstr(reply_ss_to_nms, "success")){
                if (filename[0] != '\0') strcat(accessible_path, "/");
                strcat(accessible_path, filename);
                deletePath(accessible_path);
            }
        } else {
            write(sock, "Storage Server not found\n", strlen("Storage Server not found\n"));
        }
    } 

    else if (strcmp(command, "COPY") == 0 && sscanf(buffer, "%s %s %s", command, src_path, dest_path) > 0) {
        StorageServer* src_server = searchWithCache(src_path);
        StorageServer* dest_server = searchWithCache(dest_path);
        if (src_server && dest_server) {
            // Check if src_path is a directory
            snprintf(buffer, BUFFER_SIZE, "IS_DIR %s", src_path);
            if (send_command_to_storage_server(src_server->ip, src_server->port, buffer) == -1){
                send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                pthread_mutex_unlock(&mutex);  // Release lock
                close(sock);
                return NULL;
            }
            if (strstr(reply_ss_to_nms, "YES")) {
                // Fetch the list of files in the directory
                snprintf(buffer, BUFFER_SIZE, "LIST_DIR %s", src_path);
                if (send_command_to_storage_server(src_server->ip, src_server->port, buffer) == -1){
                    send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                    pthread_mutex_unlock(&mutex);  // Release lock
                    close(sock);
                    return NULL;
                }

                if (strstr(reply_ss_to_nms, "ERROR")) {
                    write(sock, "Failed to fetch directory contents\n", strlen("Failed to fetch directory contents\n"));
                    pthread_mutex_unlock(&mutex);
                    close(sock);
                    return NULL;
                }

                // Parse the file list from reply
                char* list = strrchr(reply_ss_to_nms, '>');
                char* file_list = strdup(list+2);
                char* file = strtok(file_list, "\n");

                // setting up the directory in dest folder
                char *copy_d = strrchr(src_path, '/');
                char *copy_dir = strdup(copy_d + 1);
                snprintf(buffer, BUFFER_SIZE, "CREATE FOLDER %s %s", dest_path, copy_dir);
                if (send_command_to_storage_server(dest_server->ip, dest_server->port, buffer) == -1){
                    send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                    pthread_mutex_unlock(&mutex);  // Release lock
                    close(sock);
                    return NULL;
                }
                write(sock, reply_ss_to_nms, strlen(reply_ss_to_nms));
                if (strstr(reply_ss_to_nms, "success")){
                    strcat(dest_path, "/");
                    strcat(dest_path, copy_dir);
                    hashmapInsert(dest_path, dest_server);
                    addToCache(dest_path, dest_server);
                } else {write(sock, "Directory creation failed\n", strlen("Directory creation failed\n"));
                    pthread_mutex_unlock(&mutex);
                    free(file_list);
                    close(sock);
                    return NULL;
                }

                while (file != NULL) {
                    content = 1;
                    // Issue COPY for each file
                    printf("the file is %s\n", file);
                    snprintf(buffer, BUFFER_SIZE, "COPYSRC %s", file);
                    if (send_command_to_storage_server(src_server->ip, src_server->port, buffer) == -1){
                        send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                        pthread_mutex_unlock(&mutex);  // Release lock
                        close(sock);
                        return NULL;
                    }
                    // Check for errors during COPY
                    if (strstr(reply_ss_to_nms, "ERROR")) {
                        write(sock, "Error copying file\n", strlen("Error copying file\n"));
                    } else {
                        content = 0;
                        char *name = strdup(strrchr(file, '/')+1);
                        snprintf(buffer, BUFFER_SIZE, "COPYDEST %s %s %s", dest_path, name, reply_ss_to_nms);
                        if (send_command_to_storage_server(dest_server->ip, dest_server->port, buffer) == -1){
                            send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                            pthread_mutex_unlock(&mutex);  // Release lock
                            close(sock);
                            return NULL;
                        }
                        if (strstr(reply_ss_to_nms, "success")){
                            char full_path[512]; // Buffer for the full path
                            snprintf(full_path, sizeof(full_path), "%s/%s", dest_path, name); // Construct the full path
                            hashmapInsert(full_path, dest_server);
                            addToCache(full_path, dest_server);
                        }
                        write(sock, reply_ss_to_nms, strlen(reply_ss_to_nms));
                    }

                    file = strtok(NULL, "\n");
                }
                free(copy_dir);
                free(file_list);

                write(sock, "Directory copied successfully\n", strlen("Directory copied successfully\n"));
            } else if (strstr(reply_ss_to_nms, "NO")) {
                char *file = strdup(src_path);
                content = 1;
                // Issue COPY single file
                snprintf(buffer, BUFFER_SIZE, "COPYSRC %s", file);
                if (send_command_to_storage_server(src_server->ip, src_server->port, buffer) == -1){
                    send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                    pthread_mutex_unlock(&mutex);  // Release lock
                    close(sock);
                    return NULL;
                }

                // Check for errors during COPY
                if (strstr(reply_ss_to_nms, "ERROR")) {
                    write(sock, "Error copying file\n", strlen("Error copying file\n"));
                } else {
                    content = 0;
                    const char *name = strdup(strrchr(file, '/')+1);
                    snprintf(buffer, BUFFER_SIZE, "COPYDEST %s %s %s", dest_path, name, reply_ss_to_nms);
                    if (send_command_to_storage_server(dest_server->ip, dest_server->port, buffer) == -1){
                        send_error(sock, ERR_SERVER_UNAVAILABLE, "Server has gone down or is not reachable currently\n");
                        pthread_mutex_unlock(&mutex);  // Release lock
                        close(sock);
                        return NULL;
                    }
                    if (strstr(reply_ss_to_nms, "success")){
                        char full_path[512]; // Buffer for the full path
                        snprintf(full_path, sizeof(full_path), "%s/%s", dest_path, name); // Construct the full path
                        hashmapInsert(full_path, dest_server);
                        addToCache(full_path, dest_server);
                    }
                    write(sock, reply_ss_to_nms, strlen(reply_ss_to_nms));
                }
                free(file);
            } else {
                write(sock, "Error determining if source is directory\n", strlen("Error determining if source is directory\n"));
            }
        } else {
            write(sock, "Storage Server not found\n", strlen("Storage Server not found\n"));
        }
        content = 0;
    }

    else if (strcmp(command, "LIST") == 0) {
        char *allPaths;
        allPaths = printAllPaths();
        printf("%s\n", allPaths);
        write(sock, allPaths, strlen(allPaths));
        free(allPaths);
    }

    else if (strcmp(command, "READ") == 0 && sscanf(buffer, "%s %s", command, accessible_path) > 0){
        StorageServer* server = searchWithCache(accessible_path);
        if (server){
            snprintf(buffer, BUFFER_SIZE, "IP: %s Port: %d", server->ip, server->port);
            //printf("ip and port sent %s\n", buffer);
            write(sock, buffer, strlen(buffer));
            addToCache(accessible_path, server);
        } else {write(sock, "Error: File Not Found\n", strlen("Error: File Not Found\n"));}
    }

    else if (strcmp(command, "STAT") == 0 && sscanf(buffer, "%s %s", command, accessible_path) > 0){
        StorageServer* server = searchWithCache(accessible_path);
        if (server){
            snprintf(buffer, BUFFER_SIZE, "IP: %s Port: %d", server->ip, server->port);
            write(sock, buffer, strlen(buffer));
            addToCache(accessible_path, server);
        } else { write(sock, "Error: File Not Found\n", strlen("Error: File Not Found\n"));}
    }

    else if (strcmp(command, "STREAM") == 0 && sscanf(buffer, "%s %s", command, accessible_path) > 0){
        StorageServer* server = searchWithCache(accessible_path);
        if (server){
            snprintf(buffer, BUFFER_SIZE, "IP: %s Port: %d", server->ip, server->port);
            write(sock, buffer, strlen(buffer));
            addToCache(accessible_path, server);
        } else { write(sock, "Error: File Not Found\n", strlen("Error: File Not Found\n"));}
    }

    else if (strcmp(command, "WRITE") == 0 && sscanf(buffer, "%s %s", command, accessible_path) > 0){
        StorageServer* server = searchWithCache(accessible_path);
        if (server){
            snprintf(buffer, BUFFER_SIZE, "IP: %s Port: %d", server->ip, server->port);
            write(sock, buffer, strlen(buffer));
            addToCache(accessible_path, server);
        } else { write(sock, "Error: File Not Found\n", strlen("Error: File Not Found\n"));}
    }

    else {
        send_error(sock, ERR_INVALID_REQUEST, "Invalid request\n");
    }

    pthread_mutex_unlock(&mutex);  // Release lock
    close(sock);
    return NULL;
}

int send_command_to_storage_server(char* ip, int port, char* command) {
    int sock;
    struct sockaddr_in server_addr;
    char buffer[BUFFER_SIZE];

    // Create socket
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("Socket creation failed");
        return -1;
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    if (inet_pton(AF_INET, ip, &server_addr.sin_addr) <= 0) {
        perror("Invalid IP address");
        close(sock);
        return -1;
    }
    printf("IP %s and port %d\n", ip, port);
    // Connect to the storage server
    if (connect(sock, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("Connection to storage server failed");
        close(sock);
        return -1;
    }

    // Send the command
    write(sock, command, strlen(command));

    // Receive response
    if (!content){
        memset(buffer, 0, BUFFER_SIZE);
        read(sock, buffer, BUFFER_SIZE);
        printf("Response from %s:%d -> %s\n", ip, port, buffer);
        snprintf(reply_ss_to_nms, BUFFER_SIZE, "Response from %s:%d -> %s\n", ip, port, buffer);
        log_message(reply_ss_to_nms);
    } else {
        // Initialize reply buffer
        reply_ss_to_nms[0] = '\0'; // Start with an empty string

        char chunk_buffer[1024]; // Buffer to hold incoming data
        int bytes_received;
        int total_bytes_received = 0;

        // Loop to read chunks of data until "FILE_TRANSFER_COMPLETE" is received
        while ((bytes_received = read(sock, chunk_buffer, sizeof(chunk_buffer) - 1)) > 0) {
            chunk_buffer[bytes_received] = '\0'; // Null-terminate the received chunk
            
            // Check if the current chunk contains "FILE_TRANSFER_COMPLETE"
            char *end_marker = strstr(chunk_buffer, "FILE_TRANSFER_COMPLETE");
            if (end_marker) {
                // Append only the part before the end marker
                strncat(reply_ss_to_nms, chunk_buffer, end_marker - chunk_buffer);
                total_bytes_received += (end_marker - chunk_buffer);
                break;
            }

            // Append the entire chunk to reply_ss_to_nms
            strncat(reply_ss_to_nms, chunk_buffer, bytes_received);
            total_bytes_received += bytes_received;
        }

        // Log the result (optional)
        if (total_bytes_received > 0) {
            log_message(reply_ss_to_nms);
            printf("Received %d bytes of file content from storage server %s\n", total_bytes_received, reply_ss_to_nms);
        } else {
            printf("No file content received or an error occurred\n");
        }
    }
    //printf("reply : %s\n", reply_ss_to_nms);
    close(sock);
    return 0;
}

// Register a storage server
void register_storage_server(char* ip, int nm_port, int port, char **paths, int path_count) {
    if (storage_server_count < MAX_STORAGE_SERVERS) {
        strncpy(storage_servers[storage_server_count].ip, ip, INET_ADDRSTRLEN);
        storage_servers[storage_server_count].nm_port = nm_port;
        storage_servers[storage_server_count].port = port;
        storage_servers[storage_server_count].active = 1;
        storage_servers[storage_server_count].path_count = path_count;
        for (int i = 0; i < path_count; i++) {
            strncpy(storage_servers[storage_server_count].accessible_paths[i], paths[i], MAX_PATH_LENGTH);
            hashmapInsert(paths[i], &storage_servers[storage_server_count]);
        }
        storage_server_count++;
        printf("Registered Storage Server with IPv4 address %s, NM port %d, cleint port %d and %d accessible paths that are - \n", ip, nm_port, port, path_count);
        for(int i=0; i<path_count; i++){
            printf("%s\n", storage_servers[storage_server_count-1].accessible_paths[i]);
        }
        printf("\n");
    } else {
        printf("Max storage servers reached\n");
    }
}

// Find a registered storage server
StorageServer* find_storage_server(char* ip, int port) {
    for (int i = 0; i < storage_server_count; i++) {
        if (strcmp(storage_servers[i].ip, ip) == 0 && storage_servers[i].port == port && storage_servers[i].active) {
            return &storage_servers[i];
        }
    }
    return NULL;
}

// Add file metadata to the system
void add_file_metadata(char* filename, StorageServer* server) {
    if (file_metadata_count < MAX_FILES) {
        strncpy(file_metadata[file_metadata_count].filePath, filename, 100);
        file_metadata[file_metadata_count].server = server;
        file_metadata_count++;
        printf("Added file %s to %s:%d\n", filename, server->ip, server->port);
    } else {
        printf("Max file metadata entries reached\n");
    }
}

// Find file metadata by filename
FileMetadata* find_file_metadata(char* filename) {
    for (int i = 0; i < file_metadata_count; i++) {
        if (strcmp(file_metadata[i].filePath, filename) == 0) {
            return &file_metadata[i];
        }
    }
    return NULL;
}

// Remove a storage server and all associated files
void remove_storage_server(StorageServer* server) {
    server->active = 0;
    for (int i = 0; i < file_metadata_count; i++) {
        if (file_metadata[i].server == server) {
            printf("Removing file %s from metadata\n", file_metadata[i].filePath);
            file_metadata[i] = file_metadata[--file_metadata_count];
            i--;  // Check this index again after swapping
        }
    }
}
