# Shell_POSIX-Core - Reliable Transport over UDP

This component contains two related networking projects:

1. A reliable data-transfer protocol implemented entirely on top of
   connectionless UDP sockets.
2. A multiplayer terminal game that exercises the networking layer end to end.

---

**Author:** vidvathamaiiith
**Copyright:** (c) vidvathamaiiith. All Rights Reserved.
**Watermark:** vidvathamaiiith

This module is the work and intellectual property of vidvathamaiiith. Every
source file is watermarked. Unauthorized copying or false claim of authorship is
prohibited.

---

## 1. Reliable Transport over UDP (`tcp_stack_client.c`, `tcp_stack_server.c`)

A connection-style, reliable transport layer built on UDP.

- Custom packet framing: each datagram is wrapped in a `data_packet` structure
  carrying a sequence number and total-chunk metadata.
- Fragmentation: messages are split into fixed-size chunks (for example, 512
  bytes) before transmission.
- Reliable delivery: the receiver returns an acknowledgement for each
  successfully received chunk, identified by its sequence number.
- Timeouts: the sender arms a receive timeout on its socket using `setsockopt`
  with `SO_RCVTIMEO` (100 ms).
- Retransmission: if an acknowledgement does not arrive within the timeout
  window, or is deliberately dropped by the loss-simulation hook, the sender
  retransmits the affected chunk.
- Reassembly: the receiver tracks the expected number of chunks and reconstructs
  the complete, ordered message.

## 2. Multiplayer Game (`client.c`, `server.c`, `client_udp.c`, `server_udp.c`)

A networked, two-player terminal game.

- A complete game engine managing board state, win detection, and draw
  detection.
- A server that manages both players, alternates turns, and broadcasts the
  updated board to both clients after each valid move.
- Strict move validation that rejects out-of-bounds or already-occupied
  positions.
- A replay loop that offers a rematch and resets the board when both players
  agree.

## Build and Run

```bash
cd networks_tcp_udp
make                          # builds the TCP client and server

# Multiplayer game (run each in a separate terminal):
./src/server
./src/client

# Reliable transport over UDP:
gcc -Wall -o src/tcp_stack_server src/tcp_stack_server.c
gcc -Wall -o src/tcp_stack_client src/tcp_stack_client.c
./src/tcp_stack_server
./src/tcp_stack_client
```

All components target a Linux or POSIX environment. On Windows, build and run
them inside the Windows Subsystem for Linux.

## Authorship

Authored and owned by vidvathamaiiith. Unauthorized copying or misrepresentation
of authorship is prohibited.
