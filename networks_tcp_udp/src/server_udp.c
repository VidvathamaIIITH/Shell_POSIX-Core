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
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>

#define PORT 8080

char board[3][3];
int currentPlayer = 1;

void initializeBoard() {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            board[i][j] = ' ';
        }
    }
}

void printBoard(int sock, struct sockaddr_in* addr1, struct sockaddr_in* addr2, socklen_t addr_len) {
    char buffer[1024];
    memset(buffer, 0, sizeof(buffer));

    // Building the board string
    snprintf(buffer, sizeof(buffer),
             "\n %c | %c | %c \n"
             "---+---+---\n"
             " %c | %c | %c \n"
             "---+---+---\n"
             " %c | %c | %c \n\n", 
             board[0][0], board[0][1], board[0][2], 
             board[1][0], board[1][1], board[1][2], 
             board[2][0], board[2][1], board[2][2]);

    // Send the formatted board to both players
    sendto(sock, buffer, strlen(buffer), 0, (struct sockaddr *)addr1, addr_len);
    sendto(sock, buffer, strlen(buffer), 0, (struct sockaddr *)addr2, addr_len);
}

int checkWin() {
    // Check rows and columns
    for (int i = 0; i < 3; i++) {
        if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != ' ')
            return currentPlayer;
        if (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i] != ' ')
            return currentPlayer;
    }
    // Check diagonals
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != ' ')
        return currentPlayer;
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != ' ')
        return currentPlayer;

    return 0; // No winner yet
}

int checkDraw() {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (board[i][j] == ' ')
                return 0; // Not a draw yet
        }
    }
    return 1; // It's a draw
}

int isValidMove(int row, int col) {
    if (row >= 0 && row < 3 && col >= 0 && col < 3 && board[row][col] == ' ')
        return 1;
    return 0;
}

void handleMove(int sock, struct sockaddr_in* addr, struct sockaddr_in* addr_other, socklen_t addr_len) {
    char buffer[1024];
    int row, col;

    while (1) {
        memset(buffer, 0, sizeof(buffer));
        // Inform the current player to make a move
        snprintf(buffer, sizeof(buffer), "Player %d's turn (Enter row and column): \n", currentPlayer);
        sendto(sock, buffer, strlen(buffer), 0, (struct sockaddr *)addr, addr_len);

        // Inform the other player to wait
        sendto(sock, "Waiting for opponent's move...\n", 31, 0, (struct sockaddr *)addr_other, addr_len);

        // Receive and parse move from the current player
        memset(buffer, 0, sizeof(buffer));
        recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *)addr, &addr_len);
        if (sscanf(buffer, "%d %d", &row, &col) != 2) {
            sendto(sock, "Invalid input format. Please enter row and column as two numbers.\n", 67, 0, (struct sockaddr *)addr, addr_len);
            continue;
        }
        
        // Validate the move
        if (isValidMove(row, col)) {
            // Update the board
            board[row][col] = (currentPlayer == 1) ? 'X' : 'O';
            // Print the updated board for both players
            printBoard(sock, addr, addr_other, addr_len);
            break;
        } else {
            sendto(sock, "Invalid move. Try again.\n", 25, 0, (struct sockaddr *)addr, addr_len);
        }
    }
}

int promptReplay(int sock, struct sockaddr_in* addr, socklen_t addr_len) {
    char buffer[1024];
    memset(buffer, 0, sizeof(buffer));

    // Send replay prompt
    sendto(sock, "Would you like to play again? (yes/no): \n", 40, 0, (struct sockaddr *)addr, addr_len);

    // Receive response
    recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *)addr, &addr_len);

    if (strncmp(buffer, "yes", 3) == 0) {
        return 1;
    } else {
        return 0;
    }
}

int main() {
    int sockfd;
    struct sockaddr_in server_addr, player1_addr, player2_addr;
    socklen_t addr_len = sizeof(struct sockaddr_in);

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }

    printf("Waiting for players to connect...\n");

    // Receive connection details from Player 1
    recvfrom(sockfd, NULL, 0, 0, (struct sockaddr *)&player1_addr, &addr_len);
    printf("Player 1 connected.\n");

    // Receive connection details from Player 2
    recvfrom(sockfd, NULL, 0, 0, (struct sockaddr *)&player2_addr, &addr_len);
    printf("Player 2 connected.\n");

    int playAgain = 1;

    while (playAgain) {
        initializeBoard();
        printBoard(sockfd, &player1_addr, &player2_addr, addr_len);

        while (1) {
            handleMove(sockfd, &player1_addr, &player2_addr, addr_len);
            if (checkWin()) {
                sendto(sockfd, "Player 1 wins!\n", 15, 0, (struct sockaddr *)&player1_addr, addr_len);
                sendto(sockfd, "Player 1 wins!\n", 15, 0, (struct sockaddr *)&player2_addr, addr_len);
                break;
            } else if (checkDraw()) {
                sendto(sockfd, "It's a draw!\n", 13, 0, (struct sockaddr *)&player1_addr, addr_len);
                sendto(sockfd, "It's a draw!\n", 13, 0, (struct sockaddr *)&player2_addr, addr_len);
                break;
            }

            currentPlayer = 2;

            handleMove(sockfd, &player2_addr, &player1_addr, addr_len);
            if (checkWin()) {
                sendto(sockfd, "Player 2 wins!\n", 15, 0, (struct sockaddr *)&player1_addr, addr_len);
                sendto(sockfd, "Player 2 wins!\n", 15, 0, (struct sockaddr *)&player2_addr, addr_len);
                break;
            } else if (checkDraw()) {
                sendto(sockfd, "It's a draw!\n", 13, 0, (struct sockaddr *)&player1_addr, addr_len);
                sendto(sockfd, "It's a draw!\n", 13, 0, (struct sockaddr *)&player2_addr, addr_len);
                break;
            }

            currentPlayer = 1;
        }

        // After game ends, prompt for replay
        int replay1 = promptReplay(sockfd, &player1_addr, addr_len);
        int replay2 = promptReplay(sockfd, &player2_addr, addr_len);

        if (replay1 && replay2) {
            sendto(sockfd, "Both players agreed. Restarting...\n", 35, 0, (struct sockaddr *)&player1_addr, addr_len);
            sendto(sockfd, "Both players agreed. Restarting...\n", 35, 0, (struct sockaddr *)&player2_addr, addr_len);
            currentPlayer = 1;
        } else {
            sendto(sockfd, "One or both players declined. Game over.\n", 41, 0, (struct sockaddr *)&player1_addr, addr_len);
            sendto(sockfd, "One or both players declined. Game over.\n", 41, 0, (struct sockaddr *)&player2_addr, addr_len);
            playAgain = 0;
        }
    }

    close(sockfd);
    return 0;
}
