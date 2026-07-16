# Shell_POSIX-Core - xv6 Kernel Extensions

This directory contains the unified xv6 source codebase with custom kernel modifications for scheduling algorithms and concurrency features.

---

**Author of the modifications and concurrency work:** vidvathamaiiith
**Copyright:** (c) vidvathamaiiith for all modifications. All Rights Reserved.
**Watermark:** vidvathamaiiith

The scheduling extensions, the custom system call, and the user-space
concurrency programs in this directory are the work of vidvathamaiiith. The
underlying xv6 base is the Unix-like teaching operating system from MIT (see the
`LICENSE` file); this project extends it. Unauthorized copying or false claim of
authorship over the modifications is prohibited.

---

## Overview
xv6 is a simple, Unix-like teaching operating system developed at MIT. While it provides a basic kernel, filesystem, and simple Round-Robin scheduler, it lacks advanced scheduling policies, user-space threading primitives, and robust concurrency mechanisms out of the box. This project extensively modifies xv6 to address these gaps by implementing new scheduling disciplines and adding advanced concurrency paradigms.

## Exhaustive Feature List

### 1. Custom Scheduling Algorithms
The kernel's `proc.c` and scheduler loop were heavily modified to support multiple scheduling disciplines, configurable at compile-time via `make qemu SCHEDULER=<policy>`.

- **Lottery Based Scheduling (LBS)**:
  - A proportional-share scheduler where processes are given "tickets".
  - The scheduler picks a random ticket, and the process holding that ticket wins the CPU.
  - **`settickets(int number)`**: A newly added custom system call that allows a user process to request a specific number of tickets, changing its CPU share dynamically.
  
- **Multi-Level Feedback Queue (MLFQ)**:
  - A dynamic priority scheduler with multiple queues (e.g., 4 or 5 priority levels).
  - Processes use their time slice and are subsequently demoted to a lower priority queue if they consume it fully (CPU-bound) or remain at a high priority if they yield early (I/O-bound).
  - **Aging / Priority Boosting**: To prevent starvation, the scheduler tracks `ticks_since_last_boost` and periodically promotes all processes back to the highest priority queue.

### 2. Concurrency Primitives (User Space)
Located in `concurrency/`, these user-space programs (compiled with pthreads) were designed alongside the xv6 modifications to explore concurrency limits.

- **Lazy Sort (`lazy_sort.c`)**:
  - A custom multithreaded sorting implementation.
  - Splits an array into chunks and uses worker threads to sort chunks concurrently.
  - Implements thread synchronization and merging logic to combine the sorted chunks efficiently.
- **Lazy Read Write (`lazy_read_write.c`)**:
  - Implements a Reader-Writer lock scenario.
  - Ensures mutual exclusion for writers while allowing concurrent access for multiple readers.
  - Utilizes mutexes and condition variables to prevent race conditions and manage state sharing safely without deadlocks.

## Build
Run `make qemu` to launch the OS emulator with the default Round Robin scheduler.
To use custom schedulers:
```bash
make qemu SCHEDULER=LBS
make qemu SCHEDULER=MLFQ
```
