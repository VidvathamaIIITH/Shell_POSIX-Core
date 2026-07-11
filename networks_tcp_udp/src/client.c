// tcp_client.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>

#define PORT 8080

int main() {
    int sock = 0;
    struct sockaddr_in serv_addr;
    char buffer[1024] = {0};

    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        printf("\n Socket creation error \n");
        return -1;
    }

    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(PORT);

    if (inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr) <= 0) {
        printf("\nInvalid address/ Address not supported \n");
        return -1;
    }

    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
        printf("\nConnection Failed \n");
        return -1;
    }

    
    while (1) {
        memset(buffer, 0, sizeof(buffer)); 
        if (recv(sock, buffer, 1024, 0) > 0) {
            printf("%s", buffer);
            fflush(stdout);  // Ensure printed messages are flushed to the console
        }

        if (strstr(buffer, "Closing") != NULL) {
            break;
        }

        if (strstr(buffer, "wins") != NULL || strstr(buffer, "draw") != NULL) {
            continue;
        }
        
        if (strstr(buffer, "play again?") != NULL) {
            char response[10];
            memset(response, 0, sizeof(response));
            scanf("%s", response);
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer, "%s", response);
            send(sock, buffer, strlen(buffer), 0);
            printf("%s\n", buffer);
            continue;
        }

        int row, col;
        if (strstr(buffer, "Player") != NULL && strstr(buffer, "turn") != NULL) {
            scanf("%d %d", &row, &col);
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer, "%d %d", row, col);
            send(sock, buffer, strlen(buffer), 0);
        }
    }

    close(sock);
    return 0;
}
