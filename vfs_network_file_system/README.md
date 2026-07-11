# Network File System (VFS)

A highly modular and robust virtual network file system designed from scratch, featuring a central Naming Server, distributed Storage Servers, and a lightweight Client application.

## Exhaustive Feature List

### Architectural Components
- **Naming Server (NM)**: 
  - Central coordinator running on a static port (8080).
  - Handles concurrent connections from both Storage Servers and Clients using robust multithreading.
  - Maintains a central directory of all accessible files across the network.
- **Storage Server (SS)**: 
  - Dynamically registers with the NM upon startup, supplying its IP, Port, and a list of accessible paths it manages.
  - Handles direct read, write, and file manipulation requests from Clients.
- **Client**: 
  - Connects to the NM to resolve the IP and Port of the SS holding the target file.
  - Connects directly to the respective SS to execute the operation.

### Supported Operations
- **`READ <path>`**: Streams the contents of the specified file from the SS to the Client's terminal.
- **`WRITE <path>`**: Allows the client to write data to a file. Write operations are **atomic** and strictly lock the file against concurrent accesses.
- **`STREAM <path>`**: Specialized operation for audio files. Returns binary audio packets from the SS which the Client reaps into a temporary file and automatically invokes `mpv` to play.
- **`CREATE <FILE|FOLDER> <path> <name>`**: Creates a new file or directory at the specified accessible path. If the path doesn't exist on any SS, a random SS is chosen.
- **`DELETE <FILE|FOLDER> <path>`**: Deletes the specified file or folder from the managing SS.
- **`COPY <dir1> <dir2>`**: Performs a complex file-by-file data transfer across the network. Copies all accessible files in `dir1` (source SS) into a newly created `dir2/dir1` directory (target SS), managing network transfer automatically.
- **`STAT <path>`**: Returns detailed file metadata from the SS (size, permissions, creation/modification timestamps).
- **`LIST`**: Dumps a list of all universally accessible paths managed by the NM.

### Advanced Mechanisms
- **LRU Caching & Hashing (NM)**: To optimize routing, the NM implements an LRU (Least Recently Used) cache alongside a Hashmap to achieve O(1) expected time for resolving which SS manages a given path.
- **Path Resolution**: Supports absolute paths, Linux root `/`, and relative paths (`./`, `~`).
- **Comprehensive Logging**: The NM maintains a continuous book-keeping log in `log.txt`, recording all incoming requests, the IP and Port of the initiator, and the outcome of the operation.
- **Robust Error Handling**: A standardized set of network-aware error codes (`error.h`) is defined. If a client queries an invalid path, the NM returns a specific error code without initiating a connection to any SS.

## Build & Run
```bash
cd 02_vfs_network_file_system
make

# Terminal 1: Run Naming Server
./naming_server/naming_server

# Terminal 2: Run Storage Server
./storage_server/storage_server <NM_IP>

# Terminal 3: Run Client
./client/client <NM_IP>
```
