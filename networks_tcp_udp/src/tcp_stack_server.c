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

#define PORT 8080
#define CHUNK_SIZE 512
#define MAX_CHUNKS 100

struct data_packet {
    int sequence_number;
    int total_chunks;
    char data[CHUNK_SIZE];
};

int main() {
    int sockfd;
    struct sockaddr_in servaddr, cliaddr;
    struct data_packet packet;
    socklen_t len = sizeof(cliaddr);
    char* received_data[MAX_CHUNKS] = {NULL};
    int received_chunks = 0;
    int expected_chunks = 0;

    // Create UDP socket
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&servaddr, 0, sizeof(servaddr));
    memset(&cliaddr, 0, sizeof(cliaddr));

    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = INADDR_ANY;
    servaddr.sin_port = htons(PORT);

    // Bind the socket with the server address
    if (bind(sockfd, (const struct sockaddr*)&servaddr, sizeof(servaddr)) < 0) {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }

    printf("Server is ready to receive data...\n");

    while (1) {
        recvfrom(sockfd, &packet, sizeof(packet), MSG_WAITALL, (struct sockaddr*)&cliaddr, &len);
        printf("Received chunk %d of %d\n", packet.sequence_number, packet.total_chunks);

        if (packet.sequence_number >= MAX_CHUNKS) {
            printf("Packet sequence number exceeds max chunk limit!\n");
            continue;
        }

        // Store the chunk in its corresponding position
        if (received_data[packet.sequence_number] == NULL) {
            received_data[packet.sequence_number] = strdup(packet.data);
            received_chunks++;
        }

        expected_chunks = packet.total_chunks;

        // Send ACK for the received chunk
        sendto(sockfd, &packet.sequence_number, sizeof(packet.sequence_number), MSG_CONFIRM, (const struct sockaddr*)&cliaddr, len);

        // Check if all chunks are received
        if (received_chunks == expected_chunks) {
            printf("All chunks received. Reassembling data...\n");
            for (int i = 0; i < expected_chunks; i++) {
                printf("%s", received_data[i]);
                free(received_data[i]); // Free the allocated memory for each chunk
            }
            printf("\nData received completely.\n");
            break;
        }
    }

    close(sockfd);
    return 0;
}
