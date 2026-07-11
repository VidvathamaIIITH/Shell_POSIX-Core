#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>

#define PORT 8080
#define MAXLINE 1024

void playGame(int sock, struct sockaddr_in* server_addr, socklen_t addr_len) {
    char buffer[MAXLINE];
    int n;
    
    while (1) {
        memset(buffer, 0, sizeof(buffer));

        // Receive message from server (this could be a prompt to make a move or a board update)
        n = recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *)server_addr, &addr_len);
        buffer[n] = '\0';
        printf("%s", buffer);

        if (strstr(buffer, "Closing") != NULL) {
            break;
        }
        
        // If prompted to make a move
        if (strstr(buffer, "Player") && strstr(buffer, "turn")) {
            memset(buffer, 0, sizeof(buffer));

            // Take input from user (row and column)
            printf("Enter row and column (e.g., 0 1): ");
            fgets(buffer, sizeof(buffer), stdin);

            // Send the move to the server
            sendto(sock, buffer, strlen(buffer), 0, (struct sockaddr *)server_addr, addr_len);
        }

        // Check for game end conditions (either win, draw, or replay)
        if (strstr(buffer, "wins") || strstr(buffer, "draw")) {
            memset(buffer, 0, sizeof(buffer));

            // Wait for the server to ask for replay
            n = recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *)server_addr, &addr_len);
            buffer[n] = '\0';
            printf("%s", buffer);

            // Send replay choice (yes or no)
            fgets(buffer, sizeof(buffer), stdin);
            sendto(sock, buffer, strlen(buffer), 0, (struct sockaddr *)server_addr, addr_len);
            continue;
        }
    }
}

int main() {
    int sockfd;
    struct sockaddr_in server_addr;
    socklen_t addr_len = sizeof(server_addr);
    char buffer[MAXLINE];

    // Create socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    printf("Connecting to the game server...\n");

    // Send an initial message to the server to signal player connection
    sendto(sockfd, NULL, 0, 0, (struct sockaddr *)&server_addr, addr_len);
    printf("Connected. Waiting for the other player...\n");

    // Start the game loop
    playGame(sockfd, &server_addr, addr_len);

    // Close the socket after the game
    close(sockfd);
    return 0;
}
