#include "../include/shell.h"

void handle_sys(char *cmd, char *args, int bg, int pipei, int pipeo){

    error = 0;
    if (prevSysCmd) free(prevSysCmd);
    prevSysCmd = strdup(cmd);
    if (pipeo && bg){
        perror("invalid use of pipe\n");
        error = 1;
        return;
    }
    char *listArgs[10] = {NULL};
    char delims[] = " ";
    int i = 0;
    int output_redirect = 0, double_output_redirect = 0, input_redirect = 0;
    char *input_file = NULL, *output_file = NULL;
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
        else if (strcmp(token, "<")==0){
            input_redirect = 1;
            token = strtok(NULL, delims);
            if (token != NULL)
                input_file = strdup(token);
        }
        else if (!input_redirect && !output_redirect && !double_output_redirect) {
            if (token[0]=='"' && token[strlen(token)-1]!='"'){
                listArgs[i] = strdup(&token[1]);
            }
            else if (token[0]!='"' && token[strlen(token)-1]=='"'){
                listArgs[i] = malloc(strlen(token));
                if (listArgs[i] == NULL){
                    perror("malloc failed\n");
                    return;
                }
                strncpy(listArgs[i], token, strlen(token)-1);
                listArgs[i][strlen(token)-1] = '\0';
            }
            else if (token[0]=='"' && token[strlen(token)-1]=='"'){
                listArgs[i] = malloc(strlen(token)-1);
                if (listArgs[i] == NULL){
                    perror("malloc failed\n");
                    return;
                }
                strncpy(listArgs[i], &token[1], strlen(token)-2);  
                listArgs[i][strlen(token)-2] = '\0';
            }  
            else{
                listArgs[i] = strdup(token);
            }          
            i++;
        }
        token = strtok(NULL, delims);
    }
    listArgs[i] = NULL;
    i--;

    if (user_pipe && pipei){
        if (input_file) free(input_file);
        input_file = strdup(pipe_file);
    }

    pid_t pid = fork();
    if (pid < 0){
        perror("couldn't execute sys cmd. fork failed.\n");
        error = 1;
        return;
    }
    else if (pid == 0){
        if (bg) setpgid(0, 0);
        /*if ((strcmp(cmd, "vim")==0 || (strcmp(cmd, "vi")==0 || strcmp(cmd, "nano")==0 || strcmp(cmd, "./shell_main")==0 )) && bg == 1){
            int devnull = open("/dev/null", O_RDWR);
                dup2(devnull, STDIN_FILENO);
                dup2(devnull, STDOUT_FILENO);
                dup2(devnull, STDERR_FILENO);
                close(devnull);
        }*/
        if (user_pipe || (input_redirect && input_file != NULL)){
            int fd = open(input_file, O_RDONLY, 0644);
            if (fd < 0){
                perror("No such input file found!\n");
                return;
            }
            //clearerr(stdin);
            dup2(fd, STDIN_FILENO);
            close(fd);
        }
        if (output_redirect && output_file != NULL){
            int fd = open(output_file, O_WRONLY | O_CREAT | O_TRUNC, 0644);
            if (fd < 0){
                perror("failed to open/create redirected file\n");
                return;
            }
            //fflush(stdout);
            dup2(fd, STDOUT_FILENO);
            close(fd);
        }
        else if (double_output_redirect && output_file != NULL){
            int fd = open(output_file, O_WRONLY | O_CREAT | O_APPEND, 0644);
            if (fd < 0){
                perror("failed to open/create redirected file\n");
                return;
            }
            //fflush(stdout);
            dup2(fd, STDOUT_FILENO);
            close(fd);
        }
        if ((pipei || pipeo) && !user_pipe) {
            if (pipe_counter > 0) {
                close(pipes[cmd_num][pipe_counter-1][1]);
                clearerr(stdin);
                if (dup2(pipes[cmd_num][pipe_counter-1][0], STDIN_FILENO) == -1) {
                    perror("dup2 (input) failed");
                    exit(EXIT_FAILURE);
                }
                close(pipes[cmd_num][pipe_counter-1][0]);
            }
            if (pipe_counter < total_pipes) {
                fflush(stdout);
                close(pipes[cmd_num][pipe_counter][0]);
                //printf("%s %d\n", cmd, cmd_num);
                if (dup2(pipes[cmd_num][pipe_counter][1], STDOUT_FILENO) == -1) {
                    perror("dup2 (output) failed");
                    exit(EXIT_FAILURE);
                }
                close(pipes[cmd_num][pipe_counter][1]);
            }
        }
        //printf("cmd %s, listargs %s\n", cmd, listArgs[0]);
        if (execvp(cmd, listArgs) == -1) {
            perror("exec failed\n");
            if (pipei || pipeo){
                perror("invalid pipe command\n");
            }
            error = 1;
            exit(EXIT_FAILURE);
        }
    }
    else{
        if (user_pipe) user_pipe = 0;
        spawned_processes[num_procs].pidBg = pid;
        spawned_processes[num_procs].procName = strdup(cmd);
        num_procs++;
        if (bg == 0){
            current_fg_proc = pid;
            if (pipei || pipeo) {
                if (pipe_counter > 0){
                    close(pipes[cmd_num][pipe_counter-1][0]);
                    close(pipes[cmd_num][pipe_counter-1][1]);
                }
                if (pipe_counter < total_pipes) 
                    close(pipes[cmd_num][pipe_counter][1]);
            }
            sys = 1;
            if (pipei || pipeo) {pipe_counter++;}
            if (pipei && !pipeo){
                cmd_num++;
                total_pipes = pipe_count_pc[cmd_num];
                pipe_counter = 0;
            }
            gettimeofday(&start, NULL);
            int proc_status;
            waitpid(pid, &proc_status, WUNTRACED | WCONTINUED);
            if (WIFSTOPPED(proc_status)) {
                background_processes[num_bg].pidBg = pid;
                background_processes[num_bg].procName = strdup(cmd);
                num_bg++;
            }
            current_fg_proc = 0;
            gettimeofday(&end, NULL);
            double time = (end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec)/1000000.0;
            elapsedTime = (int)(time + 0.5);
            current_fg_proc = 0;
        }
        else{
            if (pipei || pipeo) {
                if (pipe_counter > 0){
                    close(pipes[cmd_num][pipe_counter-1][0]);
                    close(pipes[cmd_num][pipe_counter-1][1]);
                }
                if (pipe_counter < total_pipes) 
                    close(pipes[cmd_num][pipe_counter][1]);
            }
            if (pipei && !pipeo){
                cmd_num++;
                total_pipes = pipe_count_pc[cmd_num];
                pipe_counter = 0;
            }
            background_processes[num_bg].pidBg = pid;
            background_processes[num_bg].procName = strdup(cmd);
            num_bg++;
            printf("[%d] %d\n\n", num_bg, pid);
        }
    }
    if (output_file) free(output_file);
    if (input_file) free(input_file);
    for(int j=0; j<10; j++)
        if (listArgs[j] != NULL) free(listArgs[j]);
    return;
}

