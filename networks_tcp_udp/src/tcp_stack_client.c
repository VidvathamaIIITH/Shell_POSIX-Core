#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/time.h>

#define PORT 8080
#define CHUNK_SIZE 512
#define TIMEOUT 0.1 // 100 milliseconds

struct data_packet {
    int sequence_number;
    int total_chunks;
    char data[CHUNK_SIZE];
};

// Function to simulate random ACK loss (skip every 3rd ACK)
int simulate_ack_loss(int seq) {
    return (seq % 3 != 2); // Skip ACK for sequence numbers divisible by 3 (for testing)
}

int main() {
    int sockfd;
    struct sockaddr_in servaddr;
    socklen_t len = sizeof(servaddr);
    struct data_packet packet;
    char message[CHUNK_SIZE * 5] = "This is a large message that needs to be split into chunks and sent using UDP.";
    int total_chunks = (strlen(message) / CHUNK_SIZE) + 1;
    int ack = -1;

    // Create UDP socket
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(PORT);
    servaddr.sin_addr.s_addr = INADDR_ANY;

    printf("Sending data to server...\n");

    for (int i = 0; i < total_chunks; i++) {
        // Prepare the packet
        packet.sequence_number = i;
        packet.total_chunks = total_chunks;
        strncpy(packet.data, message + i * CHUNK_SIZE, CHUNK_SIZE);

        // Send the packet
        sendto(sockfd, &packet, sizeof(packet), MSG_CONFIRM, (const struct sockaddr*)&servaddr, len);
        printf("Sent chunk %d of %d\n", i + 1, total_chunks);

        // Wait for ACK
        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = TIMEOUT * 1000000; // 100ms timeout
        setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

        if (recvfrom(sockfd, &ack, sizeof(ack), MSG_WAITALL, (struct sockaddr*)&servaddr, &len) < 0) {
            printf("Timeout! Retransmitting chunk %d\n", i + 1);
            i--; // Resend the current chunk
        } else {
            printf("Received ACK for chunk %d\n", ack + 1);
        }
    }

    printf("All data sent successfully.\n");

    close(sockfd);
    return 0;
}
