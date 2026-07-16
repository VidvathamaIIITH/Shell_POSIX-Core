# Shell_POSIX-Core - POSIX Shell

A modular command-line interpreter written in C, reproducing the essential
behaviour of a POSIX shell and extending it with a rich set of custom built-in
commands. The interpreter is decomposed into focused source files, each owning a
single command or subsystem, coordinated through a single shared interface
header.

---

**Author:** vidvathamaiiith
**Copyright:** (c) vidvathamaiiith. All Rights Reserved.
**Watermark:** vidvathamaiiith

This module is the work and intellectual property of vidvathamaiiith. Every
source file is watermarked, and the author's identity is displayed at start-up.
Unauthorized copying or false claim of authorship is prohibited.

---

## Architecture

All shared configuration, data types, global state declarations, and function
prototypes are centralised in `include/shell.h`. The concrete storage for the
shell's shared global state lives in a single definition unit, `src/globals.c`.
Every other translation unit implements one responsibility:

| File | Responsibility |
| --- | --- |
| `src/main.c` | Entry point, input loop, tokenizer, and command dispatch |
| `src/globals.c` | Definitions for all shared global state |
| `src/queue.c` | Circular queue backing the persistent command history |
| `src/hop.c` | `hop` - directory navigation |
| `src/reveal.c` | `reveal` - directory listing |
| `src/seek.c` | `seek` - recursive search |
| `src/log.c` | `log` - persistent history management |
| `src/proclore.c` | `proclore` - process inspection |
| `src/activities.c` | `activities` - background process listing |
| `src/signals.c` | `ping`, `fg`, `bg`, and signal utilities |
| `src/neonate.c` | `neonate` - most-recent-process monitor |
| `src/iman.c` | `iMan` - manual pages fetched over TCP |
| `src/sys.c` | External command execution, redirection, and pipes |
| `src/sysinfo.c` | `sysinfo` - system and shell diagnostics |
| `src/mark.c` | `mark` - persistent directory bookmarks |
| `src/calc.c` | `calc` - inline arithmetic evaluator |

## Execution and Parsing

- External command execution through `execvp`, supporting arbitrary-length
  argument lists.
- Foreground (blocking) and background (`&`, non-blocking) execution, with
  asynchronous reaping of completed background children.
- Multi-stage pipelines chaining standard output to standard input through an
  arbitrary number of sequential pipes.
- Output redirection (`>`), append redirection (`>>`), and input redirection
  (`<`), all interoperable with pipelines.
- Alias resolution from the `.myshrc` configuration file.

## Built-in Commands

### Navigation and Filesystem

- `hop [path ...]` - change directory. Supports absolute and relative paths,
  `.`, `..`, `~` (home), and `-` (previous directory).
- `reveal [-a] [-l] [path]` - list directory contents. `-a` includes hidden
  entries; `-l` prints detailed metadata. Output is colour-coded for
  directories, executables, and regular files.
- `seek [-d] [-f] [-e] <name> [dir]` - search recursively. `-d` matches
  directories only, `-f` matches files only, and `-e` auto-enters a single
  directory match or prints a single file match.
- `mark` - persistent directory bookmarks:
  - `mark <name>` saves the current directory under a label.
  - `mark -g <name>` navigates to a bookmarked directory.
  - `mark -d <name>` deletes a bookmark.
  - `mark -l` lists all bookmarks.
  Bookmarks persist across sessions and integrate with the shell's directory
  state, so `hop -` continues to work after a jump.

### Processes and Signals

- `proclore [pid]` - report a process's PID, state, process group, virtual
  memory size, and executable path.
- `activities` - list all background processes spawned by the shell, sorted by
  name, showing running or stopped state.
- `ping <pid> <signal>` - send an arbitrary signal to a process.
- `fg <pid>` - bring a background or stopped process to the foreground.
- `bg <pid>` - resume a stopped process in the background.
- `neonate -n <seconds>` - periodically print the most recently created process
  on the system until interrupted with `x`.

### History, Diagnostics, and Utilities

- `log`, `log execute <index>`, `log purge` - persistent command history that
  survives across sessions.
- `iMan <command>` - fetch and display a manual page over a raw TCP socket.
- `sysinfo` - a live diagnostics dashboard combining `/proc` telemetry (system
  uptime, load average, physical memory utilisation) with the shell's own
  bookkeeping (children spawned, children still alive, and history depth).
- `calc <expression>` - evaluate an arithmetic expression with full operator
  precedence. Supports `+`, `-`, `*`, `/`, `%`, `^` (power), unary sign,
  parentheses, and floating-point numbers. Example: `calc (3+4)*2 - 10/4`.

The `reveal`, `seek`, `log`, `proclore`, `activities`, `sysinfo`, `mark`, and
`calc` commands all cooperate with the shell's redirection and pipeline
machinery, so their output can be redirected to a file or piped into another
command.

## Signal Handling

- `SIGINT` (Ctrl+C) interrupts only the foreground process; the shell ignores
  it for itself.
- `SIGTSTP` (Ctrl+Z) suspends the foreground process and moves it to the
  background in a stopped state.
- `SIGCHLD` is handled asynchronously to reap background children and announce
  their termination.
- End-of-input (Ctrl+D) shuts the shell down gracefully, terminating attached
  background processes and flushing the command history to disk.

## Build and Run

```bash
cd c_shell
make
./shell
```

The shell targets a Linux or POSIX environment. On Windows, build and run it
inside the Windows Subsystem for Linux. The build uses GCC with `-Wall` and
links against the math library.

## Configuration

Aliases are declared in `.myshrc`, one per line, and are loaded automatically at
start-up. Persistent state is stored in author-watermarked dotfiles in the
shell's home directory: command history, directory bookmarks, and the temporary
buffer used to implement built-in pipelines.

## Authorship

Authored and owned by vidvathamaiiith. Every source file carries an authorship
header, and the watermark `vidvathamaiiith` is embedded throughout the code and
displayed at runtime. Unauthorized copying or misrepresentation of authorship is
prohibited.
