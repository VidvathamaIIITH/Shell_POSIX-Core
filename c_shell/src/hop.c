#include "../include/shell.h"

void handle_hop(char *args, int pipeo) {

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
    if (pipeo){
        user_pipe = 1;
        total_pipes--;
        //if (output_file) free(output_file); // cmd >> file | CANNOT BE SUPPORRTED
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

    char *path = NULL;

    if (strlen(args)==0 || i==0){
        if (prevDir) free(prevDir);
            prevDir = strdup(currentDir);
            if (currentDir) free(currentDir);
            currentDir = strdup(homeDir);
            path = strdup(homeDir);
            printf("%s\n\n", path);
            if (chdir(path) == -1) {
                perror("Directory change failed");
                error = 1;
            }
            if (path) free(path);
        dup2(saved_stdout, STDOUT_FILENO);
        close(saved_stdout);
        return;
    }

    int abs = 0, dot=0;
    for (int j = 0; j < i; j++) {
        path = NULL;

        if (strcmp(listArgs[j], ".") == 0) {
            printf("%s\n\n", currentDir);
        }
        else if (strcmp(listArgs[j], "~") == 0) {
            // Case for hop ~
            if (prevDir) free(prevDir);
            prevDir = strdup(currentDir);
            if (currentDir) free(currentDir);
            currentDir = strdup(homeDir);
            path = strdup(homeDir);

        } else if (strcmp(listArgs[j], "-") == 0) {
            // Case for hop -
            if (prevDir == NULL) {
                fprintf(stderr, "No previous directory to hop to.\n");
                return;
            }
            char *temp = currentDir;
            currentDir = prevDir;
            prevDir = temp;
            if (path) free(path);
            path = strdup(currentDir);

        } else if (strcmp(listArgs[j], "..") == 0) {
            // Case for hop ..
            dot = 1;
            char cwd[1024];
            if (getcwd(cwd, sizeof(cwd)) == NULL) {
                perror("getcwd() error");
                exit(1);
            }
            if (prevDir) free(prevDir);
            prevDir = strdup(currentDir);
            if (currentDir) free(currentDir);
            currentDir = strdup(cwd);
            char *lastSlash = strrchr(currentDir, '/');
            char *slash = "/";
            if (strcmp(lastSlash, currentDir)==0) path = strdup(slash);
            else if (lastSlash != NULL) {
                *lastSlash = '\0';
                path = strdup(currentDir);
            }

        } else {
            abs  = 1;
            // Case for hop to an absolute or relative path, including ~/Documents
            if (listArgs[j][0] == '~') {
                char expandedPath[1024];
                snprintf(expandedPath, sizeof(expandedPath), "%s%s", homeDir, listArgs[j] + 1);
                path = strdup(expandedPath);
            }
            else if (listArgs[j][0] == '.' && listArgs[j][1] == '/'){
                char expandedPath[1024];
                snprintf(expandedPath, sizeof(expandedPath), "%s/%s", currentDir, listArgs[j] + 2);
                if (path) free(path);
                path = strdup(expandedPath);
            }
            else if (listArgs[j][0] != '/'){
                char expandedPath[1024];
                snprintf(expandedPath, sizeof(expandedPath), "%s/%s", currentDir, listArgs[j]);
                path = strdup(expandedPath);
            } 
            else {
                path = strdup(listArgs[j]);
            }
        }

        if (path){
            printf("%s\n\n", path);
            if (chdir(path) == -1) {
                perror("Directory change failed");
                error = 1;
            }
            if (!error && (abs || dot)){
                if (prevDir) free(prevDir);
                prevDir = strdup(currentDir);
                if (currentDir) free(currentDir);
                currentDir = strdup(path);
                abs = 0;
                dot = 0;
            }
        }

        if (path) free(path);  // Free the temporary path after changing directory
    }
    fflush(stdout);
    fsync(STDOUT_FILENO);
    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);
    for (int j = 0; j < 10; j++)
        if (listArgs[j]) free(listArgs[j]);
    if (output_file) free(output_file);
}

