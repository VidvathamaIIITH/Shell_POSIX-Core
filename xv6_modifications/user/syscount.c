#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/syscall.h"
#include <stddef.h>

char *syscall_names[] = {
    [SYS_fork]    = "fork",
    [SYS_exit]    = "exit",
    [SYS_wait]    = "wait",
    [SYS_pipe]    = "pipe",
    [SYS_read]    = "read",
    [SYS_kill]    = "kill",
    [SYS_exec]    = "exec",
    [SYS_fstat]   = "fstat",
    [SYS_chdir]   = "chdir",
    [SYS_dup]     = "dup",
    [SYS_getpid]  = "getpid",
    [SYS_sbrk]    = "sbrk",
    [SYS_sleep]   = "sleep",
    [SYS_uptime]  = "uptime",
    [SYS_open]    = "open",
    [SYS_write]   = "write",
    [SYS_mknod]   = "mknod",
    [SYS_unlink]  = "unlink",
    [SYS_link]    = "link",
    [SYS_mkdir]   = "mkdir",
    [SYS_close]   = "close",
    [SYS_waitx]   = "waitx",
    [SYS_getSysCount] = "sys_getSysCount"
};

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage: syscount <mask> <command> [args...]\n");
        exit(1);
    }

    int mask = atoi(argv[1]); // Convert mask to integer
    if (mask <= 0) {
        printf("Invalid mask value.\n");
        exit(1);
    }
    // Execute the command with its arguments
    int pid = fork();
    if (pid < 0) {
        printf("Fork failed.\n");
        exit(1);
    } else if (pid == 0) {
        exec(argv[2], &argv[2]); // Run the command
        printf("exec failed\n");
        exit(1);
    } else {
        wait(NULL);
        int count = 0;
        count = getSysCount(mask); // Get the syscall count
        int syscall_num = -1;
        for (int i = 0; i < 31; i++) {
            if (mask == (1 << i)) {  // Check which bit in the mask is set
                syscall_num = i;
                break;
            }
        }
        char *name = NULL;
        if (syscall_num > 0 && syscall_num < 31 && syscall_names[syscall_num] != NULL) {
            name = syscall_names[syscall_num];
        }
        printf("PID %d called %s %d times.\n", pid, name, count);
    }

    exit(0);
}
