# TCP over UDP Network Stack & Multiplayer Tic-Tac-Toe

This project contains two distinct networking features:
1. A reliable data transfer protocol implemented entirely over connectionless UDP sockets.
2. A multiplayer Tic-Tac-Toe game leveraging standard network sockets.

## Exhaustive Feature List

### 1. Custom TCP-over-UDP Stack (`tcp_stack_client.c`, `tcp_stack_server.c`)
- **Custom Packet Structure**: Data is wrapped in a `data_packet` struct containing a `sequence_number` and `total_chunks` metadata header.
- **Data Chunking**: Messages are automatically fragmented into fixed-size chunks (e.g., 512 bytes) before transmission.
- **Reliable Transmission**:
  - Requires the receiver to send back Acknowledgement packets (ACKs) containing the sequence number of the successfully received chunk.
  - Implements dynamic socket receive timeouts using `setsockopt` and `SO_RCVTIMEO` (set to 100ms).
- **Retransmission Logic**: If an ACK is not received within the timeout window (or if an ACK is artificially lost via `simulate_ack_loss`), the sender explicitly retransmits the dropped chunk.
- **Reconstruction**: The receiver tracks `expected_chunks` and continuously listens until all ordered chunks arrive.

### 2. Multiplayer Tic-Tac-Toe (`client.c`, `server.c`, `client_udp.c`, `server_udp.c`)
- **Game Engine**: A fully functional Tic-Tac-Toe engine managing board state (`initializeBoard`, `printBoard`, `checkWin`, `checkDraw`).
- **Concurrent/Networked Players**: 
  - The server manages connections for Player 1 and Player 2.
  - Alternates turns (`currentPlayer`), broadcasting the updated board state to both clients after each valid move.
- **Validation**: Enforces strict move validation (`isValidMove`) rejecting out-of-bounds or overwritten coordinates.
- **Replayability**: Contains a unified `promptReplay` loop asking clients if they want to rematch, resetting board state if both agree.

## Build & Run
```bash
cd 04_networks_tcp_over_udp
make

# For the Tic-Tac-Toe Game:
./src/server
./src/client  # run in two separate terminals

# For testing TCP over UDP reliability:
gcc src/tcp_stack_server.c -o src/tcp_stack_server
gcc src/tcp_stack_client.c -o src/tcp_stack_client
./src/tcp_stack_server
./src/tcp_stack_client
```
