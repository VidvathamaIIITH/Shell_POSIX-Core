# Custom C Shell

A custom shell implementation in C. The entire codebase has been meticulously modularized into distinct functional components inside `src/` and `include/`.

## Exhaustive Feature List

### Core Execution & Parsing
- **Modular Design**: Broken down into specific files for each built-in (`hop.c`, `seek.c`, `reveal.c`, etc.) with a unified `shell.h` header.
- **System Commands**: `execvp` based system command execution supporting arbitrary length arguments.
- **Process Management**: Support for Foreground (blocking wait) and Background processes (non-blocking, appended with `&`).
- **Pipelining**: Support for multiple sequential pipes (`|`) chaining standard outputs to inputs.
- **Redirection**: Handles standard output redirection (`>`), append redirection (`>>`), and input redirection (`<`). Interoperates successfully with pipes.
- **Alias Resolution**: Automatically parses `.myshrc` to map shorthand aliases to complex commands.

### Built-in Commands
- **`hop` (cd equivalent)**:
  - Changes the shell's working directory.
  - Supports absolute paths, relative paths, `.` (current), `..` (parent), `~` (home directory of shell), and `-` (previous directory).
- **`reveal` (ls equivalent)**:
  - Lists directory contents.
  - Flags: `-a` (show hidden files starting with `.`), `-l` (show detailed file statistics: permissions, links, user, group, size, time).
  - Uses color coding: Green for executables, Blue for directories, White for regular files.
- **`seek` (find equivalent)**:
  - Recursively searches for files or directories by name.
  - Flags: `-d` (search directories only), `-f` (search files only), `-e` (execute/enter directly if exactly one match is found).
- **`log` (history equivalent)**:
  - Maintains a persistent history of executed commands across sessions.
  - Commands: `log` (display history), `log execute <index>` (re-execute a specific historical command), `log purge` (clear history).
- **`proclore`**:
  - Displays detailed process information: PID, Status (R/S/Z/etc.), Process Group, Virtual Memory size, and executable path.
- **`activities`**:
  - Lists all currently spawned background processes associated with the shell, sorted by PID, showing their running/stopped state.
- **`ping <pid> <signal_num>`**:
  - Sends a specific OS signal to a given process ID.
- **`fg <pid>`**:
  - Brings a running or stopped background process to the foreground, handing over terminal control and waiting for its completion.
- **`bg <pid>`**:
  - Changes the state of a stopped background process to running (in the background).
- **`neonate -n <time_sec>`**:
  - Prints the PID of the most recently created process on the system every `time_sec` seconds until the user presses 'x'.
- **`iMan <command>`**:
  - Fetches and displays the man page for a given command by making a socket connection to `man.he.net`.

### Signal Handling
- **`SIGINT` (Ctrl+C)**: Interrupts only the current foreground process; the shell itself catches and ignores it.
- **`SIGTSTP` (Ctrl+Z)**: Pushes the current foreground process to the background and changes its state to Stopped.
- **`SIGCHLD`**: Asynchronous handler that waits on background children to reap zombies and prints an alert when a background process terminates normally or abnormally.
- **`SIGQUIT` (Ctrl+D)**: Gracefully terminates the shell and kills all attached background processes.

## Build & Run
```bash
cd 01_c_shell
make
./shell
```
