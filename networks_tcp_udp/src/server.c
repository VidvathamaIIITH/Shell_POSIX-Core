// tcp_server.c
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

void printBoard(int conn1, int conn2) {
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
    send(conn1, buffer, strlen(buffer), 0);
    send(conn2, buffer, strlen(buffer), 0);
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

void handleMove(int conn, int conn_other) {
    char buffer[1024];
    int row, col;

    while (1) {
        memset(buffer, 0, sizeof(buffer));
        // Inform the current player to make a move
        snprintf(buffer, sizeof(buffer), "Player %d's turn (Enter row and column): \n", currentPlayer);
        send(conn, buffer, strlen(buffer), 0);

        // Inform the other player to wait
        send(conn_other, "Waiting for opponent's move...\n", 31, 0);

        // Receive and parse move from the current player
        memset(buffer, 0, sizeof(buffer));
        recv(conn, buffer, sizeof(buffer), 0);
        if (sscanf(buffer, "%d %d", &row, &col) != 2) {
            send(conn, "Invalid input format. Please enter row and column as two numbers.\n", 67, 0);
            continue;
        }
        
        // Validate the move
        if (isValidMove(row, col)) {
            // Update the board
            board[row][col] = (currentPlayer == 1) ? 'X' : 'O';
            // Print the updated board for both players
            printBoard(conn, conn_other);
            break;
        } else {
            send(conn, "Invalid move. Try again.\n", 25, 0);
        }
    }
}



int promptReplay(int conn) {
    char buffer[1024];
    memset(buffer, 0, sizeof(buffer));
    printf("sending\n");
    send(conn, "Would you like to play again? (yes/no): \n", 40, 0);
    printf("sent\n");
    //fflush(stdout);
    if (recv(conn, buffer, 1024, 0) > 0) {
            printf("%s\n", buffer);
            fflush(stdout);  // Ensure printed messages are flushed to the console
        }
    if (strncmp(buffer, "yes", 3) == 0) {
        return 1;
    } else {
        return 0;
    }
}


int main() {
    int server_fd, conn1, conn2;
    struct sockaddr_in address;
    int addrlen = sizeof(address);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd == 0) {
        perror("Socket failed");
        exit(EXIT_FAILURE);
    }

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }

    if (listen(server_fd, 2) < 0) {
        perror("Listen failed");
        exit(EXIT_FAILURE);
    }

    printf("Waiting for players to connect...\n");

    conn1 = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen);
    if (conn1 < 0) {
        perror("Accept failed");
        exit(EXIT_FAILURE);
    }
    printf("Player 1 connected.\n");

    conn2 = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen);
    if (conn2 < 0) {
        perror("Accept failed");
        exit(EXIT_FAILURE);
    }
    printf("Player 2 connected.\n");

    int playAgain = 1;

    while (playAgain) {
        initializeBoard();
        printBoard(conn1, conn2);

        while (1) {
            handleMove(conn1, conn2);
            if (checkWin()) {
                send(conn1, "Player 1 wins!\n", 15, 0);
                send(conn2, "Player 1 wins!\n", 15, 0);
                break;
            } else if (checkDraw()) {
                send(conn1, "It's a draw!\n", 13, 0);
                send(conn2, "It's a draw!\n", 13, 0);
                break;
            }

            currentPlayer = 2;

            handleMove(conn2, conn1);
            if (checkWin()) {
                send(conn1, "Player 2 wins!\n", 15, 0);
                send(conn2, "Player 2 wins!\n", 15, 0);
                break;
            } else if (checkDraw()) {
                send(conn1, "It's a draw!\n", 13, 0);
                send(conn2, "It's a draw!\n", 13, 0);
                break;
            }

            currentPlayer = 1;
        }

        // After game ends, prompt for replay
        int replay1 = promptReplay(conn1);
        int replay2 = promptReplay(conn2);

        if (replay1 && replay2) {
            send(conn1, "Both players agreed. Restarting...\n", 35, 0);
            send(conn2, "Both players agreed. Restarting...\n", 35, 0);
            currentPlayer = 1;
        } else if (replay1 && !replay2) {
            send(conn1, "Opponent declined to play again. Closing connection.\n", 54, 0);
            send(conn2, "You declined to play again. Closing connection.\n", 50, 0);
            playAgain = 0;
        } else if (!replay1 && replay2) {
            send(conn1, "You declined to play again. Closing connection.\n", 50, 0);
            send(conn2, "Opponent declined to play again. Closing connection.\n", 54, 0);
            playAgain = 0;
        } else {
            send(conn1, "Both players declined. Closing connection.\n", 45, 0);
            send(conn2, "Both players declined. Closing connection.\n", 45, 0);
            playAgain = 0;
        }
    }

    close(conn1);
    close(conn2);
    close(server_fd);
    return 0;
}
