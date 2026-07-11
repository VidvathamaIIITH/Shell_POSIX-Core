#include "../include/shell.h"

int is_process_running(pid_t pid) {
    char path[40];
    sprintf(path, "/proc/%d/status", pid);
    
    FILE* file = fopen(path, "r");
    if (!file) {
        return 0;  // Process does not exist
    }
    char line[100];
    while (fgets(line, sizeof(line), file)) {
        if (strncmp(line, "State:", 6) == 0) {
            // State is in the format: State:  R (running) or T (stopped) etc.
            char state = line[7];
            fclose(file);
            if (state == 'R' || state == 'S') {
                return 1;  // Running or sleeping both show up as running
            } else if (state == 'T') {
                return 2;  // Stopped
            }
            break;
        }
    }
    
    
    return 0;  // Process exists but is neither running nor stopped
}

int compare_cmds(const void *a, const void *b) {
    struct bgProcs *procA = (struct bgProcs *)a;
    struct bgProcs *procB = (struct bgProcs *)b;
    return strcmp(procA->procName, procB->procName);
}

void handle_activities(char *args, int pipeo){

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
    if (i>0){
        error = 1;
        return;
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
    if (pipeo){
        user_pipe = 1;
        total_pipes--;
        output_file = strdup(pipe_file);
    }
    for(int n=0; n<num_procs; n++){
        spawned_processes[n].status = is_process_running(spawned_processes[n].pidBg);
    }

    // Sort the array based on the cmd field (lexicographically)
    qsort(spawned_processes, num_procs, sizeof(struct bgProcs), compare_cmds);
    for (int i = 0; i < num_procs; i++) {
        if (spawned_processes[i].status == 1 || spawned_processes[i].status == 2) {
            if (spawned_processes[i].status == 1)
                printf("%-10d: %-20s - Running\n", spawned_processes[i].pidBg, spawned_processes[i].procName);
            else printf("%-10d : %-20s - Stopped\n", spawned_processes[i].pidBg, spawned_processes[i].procName);
        }
    }

    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);
    for (int j = 0; j < 10; j++)
        if (listArgs[j]) free(listArgs[j]);
    if (output_file) free(output_file);

}

