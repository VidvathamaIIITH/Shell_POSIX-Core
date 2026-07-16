# Shell_POSIX-Core - Distributed Virtual File System

A modular distributed file system built from scratch, composed of a central
Naming Server, one or more distributed Storage Servers, and a lightweight
Client.

---

**Author:** vidvathamaiiith
**Copyright:** (c) vidvathamaiiith. All Rights Reserved.
**Watermark:** vidvathamaiiith

This module is the work and intellectual property of vidvathamaiiith. Every
source file is watermarked. Unauthorized copying or false claim of authorship is
prohibited.

---

## Architecture

- Naming Server: the central coordinator, running on a fixed port (8080). It
  serves concurrent connections from both Storage Servers and Clients using
  multithreading, and maintains a directory of every file across the network.
- Storage Server: registers with the Naming Server at start-up, advertising its
  address and the paths it manages, and serves read, write, and file-management
  requests directly from Clients.
- Client: contacts the Naming Server to resolve the Storage Server that owns a
  target path, then connects directly to that Storage Server to carry out the
  operation.

## Supported Operations

- `READ <path>` - stream the contents of a file to the client.
- `WRITE <path>` - write data to a file. Writes are atomic and lock the file
  against concurrent access.
- `STREAM <path>` - stream binary audio in chunks and play it back live on the
  client.
- `CREATE <FILE|FOLDER> <path> <name>` - create a file or directory.
- `DELETE <FILE|FOLDER> <path>` - delete a file or directory.
- `COPY <dir1> <dir2>` - replicate all files from a source directory on one
  Storage Server into a target directory on another, transferring across the
  network.
- `STAT <path>` - return file metadata: size, permissions, and timestamps.
- `LIST` - list all paths managed across the network.

## Advanced Mechanisms

- Fast routing: a hash map combined with an LRU cache resolves a path to its
  owning Storage Server in expected constant time.
- Path resolution: absolute, root, relative (`./`), and home-relative (`~`)
  paths are all supported.
- Logging: the Naming Server records every request, the initiator's address, and
  the outcome in `log.txt`.
- Error handling: a standardised set of network-aware error codes is defined in
  `common/error.h` and propagated cleanly from Storage Server to Naming Server to
  Client.

## Build and Run

```bash
cd vfs_network_file_system
make

# Terminal 1: Naming Server
./naming_server/naming_server

# Terminal 2: Storage Server
./storage_server/storage_server <NM_IP>

# Terminal 3: Client
./client/client <NM_IP>
```

All components target a Linux or POSIX environment and are built with `-pthread`.

## Authorship

Authored and owned by vidvathamaiiith. Unauthorized copying or misrepresentation
of authorship is prohibited.
