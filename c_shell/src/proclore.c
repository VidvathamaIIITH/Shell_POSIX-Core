#include "../include/shell.h"

void handle_proclore(char *args, int pipeo){
    
    error = 0;
    pid_t processPid;
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
    if (pipeo){
        user_pipe = 1;
        total_pipes--;
        output_file = strdup(pipe_file);
    }
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
    
    if (strlen(args) == 0){
        processPid = shellPid;
    } 
    else {
        processPid = atoi(listArgs[0]);
    }
    char path[256];
    char buffer[256];

    // 1. Process Status
    snprintf(path, sizeof(path), "/proc/%d/stat", processPid);
    FILE *statFile = fopen(path, "r");
    if (statFile == NULL) {
        perror("Failed to open stat file");
        error = 1;
        return;
    }
        
    // Read the stat file (important fields: 3rd for status, 5th for PGID)
    char comm[256];
    char state;
    pid_t pgid;
    long unsigned int vsize;
    fscanf(statFile, "%*d %s %c %*d %d", comm, &state, &pgid);
    fclose(statFile);

    int p = 0;
    while(background_processes[p].pidBg != processPid){ p++ ;if (p==100) break; }
    
    if (p < 100)
        printf("\nProcess Status: %c+\n", state);
    else printf("\nProcess Status: %c\n", state);
    printf("Process Group ID: %d\n", pgid);

    // 2. Virtual Memory
    snprintf(path, sizeof(path), "/proc/%d/status", processPid);
    FILE *statusFile = fopen(path, "r");
    if (statusFile == NULL) {
        perror("Failed to open status file");
        error = 1;
        return;
    }

    while (fgets(buffer, sizeof(buffer), statusFile)) {
        if (strncmp(buffer, "VmSize:", 7) == 0) {
            printf("Virtual Memory Size: %s", buffer + 7);
            break;
        }
    }
    fclose(statusFile);

    // 3. Executable Path
    snprintf(path, sizeof(path), "/proc/%d/exe", processPid);
    ssize_t len = readlink(path, buffer, sizeof(buffer) - 1);
    if (len == -1) {
        perror("Failed to read executable path");
        error = 1;
        return;
    }
    buffer[len] = '\0';
    printf("Executable Path: %s\n\n", buffer);

    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);
    for (int j = 0; j < 10; j++)
        if (listArgs[j]) free(listArgs[j]);
    if (output_file) free(output_file);  
}

