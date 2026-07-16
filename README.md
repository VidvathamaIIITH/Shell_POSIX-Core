# Shell_POSIX-Core

A unified, low-level systems programming suite spanning operating systems and
computer networks, engineered in C. Shell_POSIX-Core brings together four
substantial subsystems under a single, cleanly organised repository: a modular
POSIX shell, a distributed virtual file system, a reliable transport protocol
built on top of UDP, and a set of xv6 kernel extensions with accompanying
user-space concurrency primitives.

---

**Author:** vidvathamaiiith
**Copyright:** (c) vidvathamaiiith. All Rights Reserved.
**Watermark:** vidvathamaiiith

This repository, including its source code, architecture, and documentation, is
the work and intellectual property of vidvathamaiiith. Every module is
watermarked with the author's identity. Unauthorized copying, redistribution,
or any false claim of authorship over any part of this project is prohibited.

---

## Table of Contents

1. [Overview](#overview)
2. [Repository Layout](#repository-layout)
3. [Component 1 - POSIX Shell (c_shell)](#component-1---posix-shell-c_shell)
4. [Component 2 - Distributed Virtual File System](#component-2---distributed-virtual-file-system)
5. [Component 3 - Reliable Transport over UDP](#component-3---reliable-transport-over-udp)
6. [Component 4 - xv6 Kernel Extensions and Concurrency](#component-4---xv6-kernel-extensions-and-concurrency)
7. [Build Prerequisites](#build-prerequisites)
8. [Quick Start](#quick-start)
9. [Authorship and License](#authorship-and-license)

---

## Overview

The suite is intentionally broad. It exercises the full stack of systems
engineering: process control and signal handling at the shell layer, socket
programming and protocol design at the network layer, distributed coordination
and caching at the file-system layer, and scheduler design and synchronisation
at the kernel layer. Each component is self-contained, has its own build system,
and can be compiled and evaluated independently.

The codebase is deliberately modular. Responsibilities are separated into
focused translation units with a shared interface header, so that behaviour is
easy to locate, reason about, and extend.

## Repository Layout

```
Shell_POSIX-Core/
├── c_shell/                     POSIX shell (interpreter, builtins, signals)
│   ├── include/shell.h          Shared types, configuration, and prototypes
│   ├── src/                     One translation unit per responsibility
│   ├── .myshrc                  Alias configuration read at start-up
│   └── Makefile
├── vfs_network_file_system/     Naming server, storage servers, and client
│   ├── naming_server/
│   ├── storage_server/
│   ├── client/
│   ├── common/                  Shared headers (errors, logging, tuning)
│   └── Makefile
├── networks_tcp_udp/            Reliable transport over UDP and a network game
│   ├── src/
│   └── Makefile
├── xv6_modifications/           xv6-riscv with custom schedulers + concurrency
│   ├── kernel/                  Kernel sources (schedulers, syscalls)
│   ├── user/                    User programs and tests
│   ├── concurrency/             User-space threading primitives
│   └── Makefile
└── README.md                    This document
```

---

## Component 1 - POSIX Shell (c_shell)

A modular command interpreter written in C that reproduces the essential
behaviour of a POSIX shell and extends it with a suite of custom built-in
commands. The interpreter is split across focused source files, each owning a
single command or subsystem, coordinated through the shared `include/shell.h`
interface.

### Execution and Parsing

- System command execution through `execvp`, supporting arbitrary-length
  argument lists.
- Foreground execution with blocking waits, and background execution using the
  `&` suffix with asynchronous reaping.
- Multi-stage pipelines: standard output of one command is chained into the
  standard input of the next through an arbitrary number of sequential pipes.
- Input and output redirection: truncating output (`>`), appending output
  (`>>`), and input redirection (`<`), all interoperable with pipelines.
- Alias resolution driven by the `.myshrc` configuration file, mapping short
  aliases to full command lines.

### Built-in Commands

- `hop` - directory navigation equivalent to `cd`, supporting absolute paths,
  relative paths, `.`, `..`, `~` (home), and `-` (previous directory).
- `reveal` - directory listing equivalent to `ls`, with `-a` (include hidden
  entries) and `-l` (detailed metadata) flags, and colour-coded output
  distinguishing directories, executables, and regular files.
- `seek` - recursive search equivalent to `find`, with `-d` (directories only),
  `-f` (files only), and `-e` (auto-enter or print a single match).
- `log` - persistent command history that survives across sessions, with
  `log` (display), `log execute <index>` (re-run a historical command), and
  `log purge` (clear history).
- `proclore` - detailed inspection of a process: PID, state, process group,
  virtual memory size, and executable path.
- `activities` - lists all background processes spawned by the shell, sorted by
  name, showing running or stopped state.
- `ping <pid> <signal>` - sends an arbitrary operating-system signal to a
  process.
- `fg <pid>` and `bg <pid>` - move a stopped or background process to the
  foreground, or resume a stopped process in the background.
- `neonate -n <seconds>` - periodically prints the most recently created
  process on the system until interrupted.
- `iMan <command>` - fetches a manual page over a raw TCP socket connection to
  an online manual service.
- `sysinfo` - a live diagnostics dashboard that fuses operating-system telemetry
  read from the `/proc` virtual filesystem (uptime, load average, physical
  memory utilisation) with the shell's own internal bookkeeping (children
  spawned, children still alive, and command-history depth).
- `mark` - persistent directory bookmarks. Tag any directory with a label and
  return to it later from anywhere, with bookmarks stored across sessions.
  Supports `mark <name>`, `mark -g <name>`, `mark -d <name>`, and `mark -l`.
- `calc` - an inline arithmetic evaluator with full operator precedence,
  supporting `+`, `-`, `*`, `/`, `%`, `^` (power), unary sign, parentheses, and
  floating-point values (for example, `calc (3+4)*2 - 10/4`).

### Signal Handling

- `SIGINT` (Ctrl+C) interrupts only the current foreground process; the shell
  itself is unaffected.
- `SIGTSTP` (Ctrl+Z) suspends the current foreground process and moves it to the
  background in a stopped state.
- `SIGCHLD` is handled asynchronously to reap background children and report
  their termination.
- End-of-input (Ctrl+D) terminates the shell gracefully, cleaning up all
  attached background processes and flushing the command history to disk.

### Build and Run

```bash
cd c_shell
make
./shell
```

---

## Component 2 - Distributed Virtual File System

A distributed file system composed of three cooperating roles: a Naming Server
that acts as the central coordinator, one or more Storage Servers that hold the
actual data, and a Client that issues operations. The Naming Server resolves
logical paths to the Storage Server that owns them, and brokers every request.

### Feature Set

- Central Naming Server that serves concurrent client and storage-server
  requests using POSIX threads.
- Dynamic registration: Storage Servers boot independently and register their
  reachable address and the set of paths they export with the Naming Server.
- Fast path resolution using a hash map combined with an LRU cache, resolving a
  path to its owning Storage Server in expected constant time.
- Atomic writes protected by mutual exclusion to prevent concurrent corruption.
- Audio streaming: binary media is fetched in chunks and played back live on the
  client.
- Distributed copy: files are replicated from one Storage Server to another
  across the network.
- Universal path handling: absolute, relative, root, and home-relative forms are
  all supported.
- File and folder creation and deletion, and metadata retrieval (size,
  permissions, modification time) across the network.
- Request and connection logging on the Naming Server.
- Standardised error propagation from Storage Server to Naming Server to Client.

### Build and Run

```bash
cd vfs_network_file_system
make
# In separate terminals:
./naming_server/naming_server
./storage_server/storage_server
./client/client
```

---

## Component 3 - Reliable Transport over UDP

A reliable, connection-style transport layer implemented on top of the
connectionless UDP interface, together with a networked multiplayer game that
exercises the transport end to end.

### Feature Set

- Custom packet framing that injects sequence numbers and total-chunk metadata
  into each datagram.
- Message fragmentation into fixed-size chunks prior to transmission.
- Explicit acknowledgements for every successfully received chunk.
- Timeout and retransmission using a receive-timeout socket option, so
  unacknowledged chunks are resent.
- Configurable loss simulation to test the reliability layer under adverse
  conditions.
- A multiplayer terminal game in which two clients play against each other
  through the server, complete with move validation, board broadcasting, and
  replay prompts.

### Build and Run

```bash
cd networks_tcp_udp
make                      # builds the TCP client and server
# UDP and custom-stack variants compile directly, for example:
gcc -Wall -o src/server_udp src/server_udp.c
gcc -Wall -o src/client_udp src/client_udp.c
```

---

## Component 4 - xv6 Kernel Extensions and Concurrency

A build of the xv6-riscv teaching kernel extended with additional scheduling
disciplines and custom system calls, paired with user-space concurrency
programs that demonstrate multithreading primitives.

### Feature Set

- Lottery-Based Scheduling: a proportional-share CPU scheduler that selects the
  next process by drawing a random ticket.
- A custom `settickets` system call that lets a process adjust its ticket
  allocation, and therefore its share of the CPU, at runtime.
- Multi-Level Feedback Queue scheduling: a dynamic-priority scheduler with
  multiple queues that demotes CPU-bound processes and promotes I/O-bound ones.
- Priority boosting that periodically elevates all processes to prevent
  starvation.
- A user-space concurrent sort that splits an array into per-thread chunks and
  merges them.
- A user-space reader-writer implementation using mutexes and condition
  variables to coordinate shared state without deadlock.

### Build and Run

```bash
cd xv6_modifications
make qemu                 # requires a RISC-V toolchain and QEMU
```

The kernel and file-system image are produced entirely from source by the build,
so a clean checkout compiles into a fresh, self-contained system.

---

## Build Prerequisites

- A Linux or POSIX environment. On Windows, the Windows Subsystem for Linux
  (WSL) provides a suitable environment for the shell, the file system, and the
  transport components.
- GCC and GNU Make for the shell, the file system, and the transport project.
- For the xv6 component: a RISC-V cross toolchain (`riscv64-unknown-elf-` or
  `riscv64-linux-gnu-`) and QEMU (`qemu-system-riscv64`).

The shell links against the math library and is built with warnings enabled
(`-Wall`). All components are compiled from source with their respective
`make` targets.

## Quick Start

```bash
# POSIX shell
cd c_shell && make && ./shell

# Distributed file system
cd vfs_network_file_system && make

# Reliable transport over UDP
cd networks_tcp_udp && make

# xv6 kernel extensions (RISC-V toolchain + QEMU required)
cd xv6_modifications && make qemu
```

## Authorship and License

This project, in its entirety, is authored and owned by vidvathamaiiith.

- All source files carry an authorship and copyright header identifying
  vidvathamaiiith as the author.
- The project name, architecture, documentation, and implementation are the
  intellectual property of vidvathamaiiith.
- The string `vidvathamaiiith` is embedded as a watermark throughout the source
  tree and is surfaced at runtime (for example, in the shell start-up banner and
  in the `sysinfo` diagnostics output).

Unauthorized copying, redistribution, sublicensing, or misrepresentation of the
authorship of this work is not permitted without the express written consent of
vidvathamaiiith.
