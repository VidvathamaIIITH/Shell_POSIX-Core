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
#include <arpa/inet.h>
#include <unistd.h>

#define BUFFER_SIZE 15000
#define NM_PORT 8080
char nm_ip[INET_ADDRSTRLEN];

void handle_stream(int sock) {
    char buffer[BUFFER_SIZE];
    ssize_t bytes_read;
    
    // Open a temporary file to store the audio content
    FILE *temp_file = fopen("temp_audio.mp3", "wb");
    if (!temp_file) {
        perror("Failed to open temporary file");
        return;
    }

    // Read all data from the socket into the buffer and write it to the temporary file
    while ((bytes_read = read(sock, buffer, sizeof(buffer))) > 0) {
        fwrite(buffer, 1, bytes_read, temp_file);
    }
    
    // Close the temporary file
    fclose(temp_file);
    
    // Now, call mpv to play the file
    printf("Streaming audio from server...\n");
    pid_t pid = fork();

    if (pid == 0) {  // Child process
        // Execute mpv to play the audio from the temporary file
        execlp("mpv", "mpv", "--no-video", "temp_audio.mp3", (char *)NULL);
        perror("exec failed");
        exit(1);
    } else if (pid > 0) {
        // Parent waits for the child process to finish
        wait(NULL);
    } else {
        perror("Fork failed");
    }
    
    // Optionally, delete the temporary file after use
    remove("temp_audio.mp3");

    printf("Audio streaming finished.\n");
}

// Function to communicate with NM and get SS details
void contact_nm(const char *request, char *response) {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_in nm_addr;
    nm_addr.sin_family = AF_INET;
    nm_addr.sin_port = htons(NM_PORT);
    inet_pton(AF_INET, nm_ip, &nm_addr.sin_addr);

    if (connect(sock, (struct sockaddr *)&nm_addr, sizeof(nm_addr)) < 0) {
        perror("Connection to NM failed");
        close(sock);
        exit(EXIT_FAILURE);
    }

    // Send the request to the NM
    if (send(sock, request, strlen(request), 0) < 0) {
        perror("Send to NM failed");
        close(sock);
        exit(EXIT_FAILURE);
    }

    // Read the response in chunks
    int bytes_received;
    while ((bytes_received = recv(sock, response + strlen(response), BUFFER_SIZE - strlen(response) - 1, 0)) > 0) {
        response[strlen(response) + bytes_received] = '\0'; // Null-terminate the buffer
    }

    if (bytes_received < 0) {
        perror("Error reading from NM");
    }

    close(sock);
}


// Function to communicate with SS
void contact_ss(const char *ip, int port, const char *command) {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_in ss_addr;
    ss_addr.sin_family = AF_INET;
    ss_addr.sin_port = htons(port);
    inet_pton(AF_INET, ip, &ss_addr.sin_addr);

    if (connect(sock, (struct sockaddr *)&ss_addr, sizeof(ss_addr)) < 0) {
        perror("Connection to SS failed");
        close(sock);
        exit(EXIT_FAILURE);
    }

    send(sock, command, strlen(command), 0);

    if (strncmp(command, "STREAM", 6) == 0){
        handle_stream(sock);
    } else {
        char buffer[BUFFER_SIZE];
        memset(buffer, 0, BUFFER_SIZE);
        while (recv(sock, buffer, BUFFER_SIZE, 0) > 0) {
            printf("%s", buffer);
            if (strstr(buffer, "STOP")) break; // Stop packet received
            memset(buffer, 0, BUFFER_SIZE);
        } printf("\n\n");
    }

    close(sock);
}

void execute_command(const char *command) {
    char response[BUFFER_SIZE] = {NULL};
    contact_nm(command, response);

    if (strstr(response, "IP")) {
        char ip[INET_ADDRSTRLEN];
        int port;
        sscanf(response, "IP: %s Port: %d", ip, &port);
        contact_ss(ip, port, command);
    } else {
        printf("%s\n", response);
    }
}

int main(int argc, char *argv[]) {

    // Ensure Naming Server IP is passed as argument
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <Naming_Server_IP>\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    int i = 0;
    while(argv[1][i] != '\0'){
        nm_ip[i] = argv[1][i];
        i++;
    } nm_ip[i]='\0';

    char command[BUFFER_SIZE];
    printf("NFS Client Ready. Enter commands:\n");

    while (1) {
        printf("> ");
        fgets(command, BUFFER_SIZE, stdin);
        command[strcspn(command, "\n")] = 0; // Remove newline

        if (strcmp(command, "exit") == 0) break;

        execute_command(command);
    }

    return 0;
}
