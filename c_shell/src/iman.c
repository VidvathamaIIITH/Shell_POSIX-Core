/* ============================================================================
 *  Shell_POSIX-Core  -  Author: vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *  Unauthorized copying or false claim of authorship is prohibited.
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

void get_man_page(const char *command_name) {
    int sockfd;
    struct sockaddr_in server_addr;
    struct hostent *server;
    char request[BUFFER_SIZE], response[BUFFER_SIZE_RESPONSE];
    char *host = "man.he.net";
    
    // Create socket
    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    // Get server information
    if ((server = gethostbyname(host)) == NULL) {
        fprintf(stderr, "Error: No such host\n");
        exit(EXIT_FAILURE);
    }

    // Prepare server address structure
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    memcpy(&server_addr.sin_addr.s_addr, server->h_addr, server->h_length);

    // Connect to the server
    if (connect(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("Connection failed");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    // Create HTTP GET request
    snprintf(request, sizeof(request),
             "GET /?topic=%s&section=all HTTP/1.1\r\n"
             "Host: %s\r\n"
             "Connection: close\r\n\r\n",
             command_name, host);

    // Send the request
    if (send(sockfd, request, strlen(request), 0) < 0) {
        perror("Send failed");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    // Receive and print the response (skip the headers)
    int received;
    int header_end = 0;
    while ((received = recv(sockfd, response, sizeof(response) - 1, 0)) > 0) {
        response[received] = '\0';
        
        // Debugging: Print each received chunk
        printf("Chunk received (%d bytes):\n%s\n", received, response);

        // Find the end of the headers if not already done
        if (!header_end) {
            char *body_start = strstr(response, "\r\n\r\n");
            if (body_start) {
                header_end = 1;
                printf("%s", body_start + 4); // Skip past the headers
            }
        } else {
            printf("%s", response);
        }
    }

    if (received < 0) {
        perror("Receive failed");
    }

    // Close the socket
    close(sockfd);
}

void handle_iMan(char *args, int pipeo){
    error = 0;
    char *listArgs[10] = {NULL};
    char delims[] = " ";
    int i = 0, fd;
    int output_redirect = 0, double_output_redirect = 0;
    char *output_file = NULL;
    char *token = strtok(args, delims);
    while (token != NULL) {
        if (strcmp(token, ">")==0){
            output_redirect = 1;
            token = strtok(NULL, delims);
            if (token != NULL)
                output_file = strdup(token);
        }
        else if (strcmp(token, ">>")==0){
            double_output_redirect = 1;
            token = strtok(NULL, delims);
            if (token != NULL)
                output_file = strdup(token);
        }
        else if (!output_redirect && !double_output_redirect && strcmp(token, "*") != 0) {
            if (i < 1){
                listArgs[i] = strdup(token);        
                i++;
            }
        }
        token = strtok(NULL, delims);
    }
    listArgs[i] = NULL;
    if (pipeo){
        user_pipe = 1;
        total_pipes--;
        //if (output_file) free(output_file); // cmd >> file | CANNOT BE SUPPORRTED
        output_file = strdup(pipe_file);
    }
    int saved_stdout = dup(STDOUT_FILENO);
    if ((user_pipe || output_redirect) && output_file != NULL){
        printf("%s\n", output_file);
        int fd = open(output_file, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd < 0){
            perror("failed to open/create redirected file\n");
            return;
        }
        dup2(fd, STDOUT_FILENO);
        close(fd);
    }
    else if (double_output_redirect && output_file != NULL){
        int fd = open(output_file, O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (fd < 0){
            perror("failed to open/create redirected file\n");
            return;
        }
        dup2(fd, STDOUT_FILENO);
        close(fd);
    }

    get_man_page(listArgs[0]);

    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);
    for (int j = 0; j < 10; j++)
        if (listArgs[j]) free(listArgs[j]);
    if (output_file) free(output_file);
}

