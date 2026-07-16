/* ============================================================================
 *  Shell_POSIX-Core  -  Author: vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *  Unauthorized copying or false claim of authorship is prohibited.
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

void handle_signals(char *args, int pipeo){
    error = 0;
    char *listArgs[10] = {NULL};
    char delims[] = " ";
    int i = 0, fd;
    int output_redirect = 0, double_output_redirect = 0;
    char *output_file = NULL;
    char *token = strtok(args, delims);
    while (token != NULL) {
        if (strcmp(token, ">")==0){
            output_redirect = 1;
            token = strtok(NULL, delims);
            if (token != NULL)
                output_file = strdup(token);
        }
        else if (strcmp(token, ">>")==0){
            double_output_redirect = 1;
            token = strtok(NULL, delims);
            if (token != NULL)
                output_file = strdup(token);
        }
        else if (!output_redirect && !double_output_redirect && strcmp(token, "*")!=0) {
            listArgs[i] = strdup(token);        
            i++;
        }
        token = strtok(NULL, delims);
    }
    listArgs[i] = NULL;
    int saved_stdout = dup(STDOUT_FILENO);
    if ((user_pipe || output_redirect) && output_file != NULL){
        int fd = open(output_file, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd < 0){
            perror("failed to open/create redirected file\n");
            return;
        }
        dup2(fd, STDOUT_FILENO);
        close(fd);
    }
    else if (double_output_redirect && output_file != NULL){
        int fd = open(output_file, O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (fd < 0){
            perror("failed to open/create redirected file\n");
            return;
        }
        dup2(fd, STDOUT_FILENO);
        close(fd);
    }
    if (pipeo){
        user_pipe = 1;
        total_pipes--;
        output_file = strdup(pipe_file);
    }
    if (i != 2){error = 1; return;}
    int target_pid = atoi(listArgs[0]);
    int signal_num = atoi(listArgs[1]) % 32;
    
    // Send the signal to the process
    if (kill(target_pid, signal_num) == 0) {
        printf("Sent signal %d to process with pid %d\n", signal_num, target_pid);
    } else {
        // Handle the error
        if (errno == ESRCH) {
            printf("No such process found.\n");
        } else if (errno == EPERM) {
            printf("No permission to send signal to process %d.\n", target_pid);
        }
    }

    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);
    for (int j = 0; j < 10; j++)
        if (listArgs[j]) free(listArgs[j]);
    if (output_file) free(output_file);
}

int is_gui_process(pid_t pid) {
    char environ_path[256];
    snprintf(environ_path, sizeof(environ_path), "/proc/%d/environ", pid);

    // Open the environment file for the process
    int fd = open(environ_path, O_RDONLY);
    if (fd == -1) {
        perror("Failed to open environ file");
        return 0;  // Assume it's not a GUI process if we can't open the file
    }

    // Read the environment variables
    char buffer[4096];  // Environment file is usually small
    ssize_t bytes_read = read(fd, buffer, sizeof(buffer) - 1);
    close(fd);

    if (bytes_read <= 0) {
        perror("Failed to read environ file");
        return 0;
    }
    buffer[bytes_read] = '\0';  // Null-terminate the environment content

    // Check for the DISPLAY or WAYLAND_DISPLAY environment variable
    if (strstr(buffer, "DISPLAY=") || strstr(buffer, "WAYLAND_DISPLAY=")) {
        return 1;  // The process is likely a GUI-based application
    }

    return 0;  // No evidence of GUI (DISPLAY not set)
}

void handle_fg(char *args) {
    int statu;
    char *listArgs[10];
    char delims[] = " ";
    int i = 0;
    listArgs[i] = strtok(args, delims);
    while (listArgs[i] != NULL) {
        //printf("%s\n", listArgs[i]);
        i++;
        listArgs[i] = strtok(NULL, delims);
    }
    if (i>1){error = 1; return;}
    pid_t pid = atoi(listArgs[0]);
    
    // Check if the process exists by sending signal 0
    if (kill(pid, 0) == -1) {
        if (errno == ESRCH) {
            printf("No such process found\n");
            return;
        } else {
            perror("Error checking process");
            return;
        }
    }
    pid_t shell_pgid = getpgrp(); 
    int terminal = 0;
    // Check if the process is connected to a terminal
    if (is_gui_process(pid)) {
        terminal = 1;
        // Bring the process group of the process to the foreground
        if (tcsetpgrp(STDIN_FILENO, pid) == -1) {
            perror("tcsetpgrp");
            return;
        }
    }
    //printf("terminal %d\n", terminal);
    // Send the process a SIGCONT signal to continue if it's stopped
    if (kill(pid, SIGCONT) == -1) {
        perror("Error sending SIGCONT");
        return;
    }

    // Wait for the process to terminate or stop
    if (waitpid(pid, &statu, WUNTRACED) == -1) {
        perror("waitpid");
    }

    // Restore the terminal control back to the shell process group if it was given
    if (terminal) {
        if (tcsetpgrp(STDIN_FILENO, shell_pgid) == -1) {
            perror("tcsetpgrp");
        }
    }

    // Check if the process stopped or terminated
    if (WIFSTOPPED(statu)) {
        printf("Process %d has been stopped\n", pid);
    } else if (WIFEXITED(statu)) {
        printf("Process %d terminated with status %d\n", pid, WEXITSTATUS(statu));
    } else if (WIFSIGNALED(statu)) {
        printf("Process %d was terminated by signal %d\n", pid, WTERMSIG(statu));
    }
}

void handle_bg(char *args) {
    int status;
    char *listArgs[10];
    char delims[] = " ";
    int i = 0;
    listArgs[i] = strtok(args, delims);
    while (listArgs[i] != NULL) {
        //printf("%s\n", listArgs[i]);
        i++;
        listArgs[i] = strtok(NULL, delims);
    }
    if (i>1){error = 1; return;}
    pid_t pid = atoi(listArgs[0]);

    // Check if the process exists by sending signal 0
    if (kill(pid, 0) == -1) {
        if (errno == ESRCH) {
            printf("No such process found\n");
            return;
        } else {
            perror("Error checking process");
            return;
        }
    }

    // Send the process a SIGCONT signal to continue if it's stopped
    if (kill(pid, SIGCONT) == -1) {
        perror("Error sending SIGCONT");
        return;
    }
}

