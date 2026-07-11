# Operating Systems and Networks (OSN)

This repository contains an exhaustively restructured and meticulously modularized collection of 4 major projects completed for the Operating Systems and Networks coursework. The codebase has been cleaned up, functionality isolated into specific folders, and detailed features are thoroughly documented.

---

## 1. [Custom C Shell](./c_shell)
A modular C-based shell supporting system and custom built-in commands, input/output redirection, background process execution, and signal handling. The previously monolithic codebase has been strictly separated into functional C files (e.g. `hop.c`, `seek.c`, `signals.c`).

### Comprehensive Feature Set:
- **Core Execution**: Uses `execvp` for system commands, managing arbitrary length arguments.
- **Process Management**: Supports Foreground and Background (`&`) processes.
- **Pipelining**: Supports unlimited chaining of standard outputs to inputs via sequential pipes (`|`).
- **Redirection**: Seamless integration of stdout redirection (`>`), append redirection (`>>`), and stdin redirection (`<`).
- **Alias Resolution**: Automatically parses `.myshrc` to map shorthand aliases to complex commands.
- **Built-in `hop`**: `cd` alternative supporting absolute, relative, `.`, `..`, `~` (home), and `-` (previous) paths.
- **Built-in `reveal`**: `ls` alternative with `-a` (hidden) and `-l` (detailed metadata) flags, featuring color-coded output.
- **Built-in `seek`**: Recursive find with `-d` (dirs), `-f` (files), and `-e` (execute/enter) flags.
- **Built-in `log`**: Command history manager with execution (`log execute <index>`) and clear (`log purge`) support.
- **Built-in `proclore`**: Dumps process PID, Status, Group, VM size, and path.
- **Built-in `activities`**: Lists all active shell background processes sorted by PID.
- **Built-in `ping`**: Sends explicit OS signals (`kill` wrapper).
- **Built-in `fg` & `bg`**: Manages state transitions of processes between foreground (blocking) and background (running).
- **Built-in `neonate`**: Tracks and prints the most recently created system PID periodically.
- **Built-in `iMan`**: Fetches man pages via TCP sockets from `man.he.net`.
- **Signal Handlers**: Safely intercepts `SIGINT` (Ctrl+C), `SIGTSTP` (Ctrl+Z), and reaps background children asynchronously with `SIGCHLD`.

---

## 2. [Network File System (VFS)](./vfs_network_file_system)
A fully functional Virtual Network File System architecture with distinct Client, Naming Server, and Storage Server implementations. 

### Comprehensive Feature Set:
- **Naming Server (NM)**: Central coordinator running on port 8080, handling concurrent client and SS requests via pthreads.
- **Dynamic Registration**: Storage Servers independently boot and register their accessible IP/Port and Paths with the NM.
- **LRU & Hashmap**: The NM utilizes a dual Hashmap/LRU Cache algorithm to resolve paths to Storage Servers in O(1) expected time.
- **Atomic Writes**: `WRITE` commands implement strict mutual exclusion locking to prevent concurrent corruption.
- **Streaming Audio**: `STREAM` command fetches audio packets in binary chunks and invokes `mpv` to play them live on the Client.
- **Distributed Copying**: `COPY <dir1> <dir2>` fetches all files from one SS and replicates them to a target SS automatically.
- **Universal Paths**: Supports standard absolute, relative (`./`), Linux root (`/`), and home (`~`) path resolutions.
- **File Manipulation**: `CREATE` and `DELETE` fully supported for both FILE and FOLDER types.
- **Metadata**: `STAT` retrieves file size, permissions, and modification times across the network.
- **Logging**: The NM tracks all incoming network requests and connection metadata in `log.txt`.
- **Error Handling**: Standardized error codes passed from SS to NM to Client gracefully upon failure.

---

## 3. [TCP over UDP Network Stack](./networks_tcp_udp)
A networking project guaranteeing reliable TCP-like transmission over a connectionless UDP interface, paired with a networked game.

### Comprehensive Feature Set:
- **Custom TCP Headers**: `data_packet` wrapper injecting `sequence_number` and `total_chunks` metadata into UDP packets.
- **Fragmentation**: Messages are split into fixed 512-byte chunks prior to sending.
- **Acknowledgments (ACK)**: Receiver sends explicit ACKs for successfully resolved chunks.
- **Timeout & Retransmission**: Senders utilize `setsockopt(SO_RCVTIMEO)` for 100ms timeout windows, retransmitting unacknowledged chunks dynamically.
- **Loss Simulation**: Injectable `simulate_ack_loss` functions to test stack reliability.
- **Multiplayer Tic-Tac-Toe**: A networked terminal game allowing two distinct clients to play against each other concurrently through the custom server logic, complete with move validation, board state broadcasting, and replay prompts.

---

## 4. [xv6 OS Modifications & Concurrency](./xv6_modifications)
A unified xv6 kernel source tree injected with advanced custom scheduling disciplines and paired with user-space concurrency primitives. 

### Comprehensive Feature Set:
- **Lottery Based Scheduling (LBS)**: A proportional-share kernel scheduler using random ticket pulls.
- **System Call `settickets()`**: A custom syscall injected into the OS to dynamically adjust a process's ticket allocation and CPU share.
- **Multi-Level Feedback Queue (MLFQ)**: A dynamic priority scheduler with multiple queues. Degrades CPU-bound processes to lower queues and promotes I/O-bound processes.
- **Priority Boosting**: The MLFQ scheduler tracks `ticks_since_last_boost` to periodically elevate all processes, aggressively preventing starvation.
- **Lazy Sort**: A user-space `pthread` sorting algorithm splitting arrays into thread-managed chunks and merging them concurrently.
- **Lazy Read Write**: A user-space Reader-Writer implementation utilizing `mutex` locks and condition variables to safely control shared state manipulation without deadlocks.

---
*Run `make` inside the respective directories to compile their targets (or `make qemu` for xv6).*
