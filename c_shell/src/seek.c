/* ============================================================================
 *  Shell_POSIX-Core  -  Author: vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *  Unauthorized copying or false claim of authorship is prohibited.
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

void searchDirectory(const char *dirPath, const char *fileName, const int f, const int d, const int e) {
    
    recurse++;
    if (recurse >= RECURSION_DEPTH)
        return;
    if (countMatches > 2048)
        return;

    struct dirent *entry;
    struct stat statbuf;
    DIR *dp = opendir(dirPath);

    if (dp == NULL) {
        perror("opendir");
        error = 1;
        return;
    }

    while ((entry = readdir(dp)) != NULL) {
        
        char fullPath[4096];
        snprintf(fullPath, sizeof(fullPath), "%s/%s", dirPath, entry->d_name);
        //printf("fullpath - %s\n", fullPath);

        if (stat(fullPath, &statbuf) == -1) {
            //perror("stat");
            continue;
        }

        // Skip "." and ".."
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        // If it's a directory, recurse into it
        if (S_ISDIR(statbuf.st_mode)) {
            if (!f) {
                direc = 1;
                if (strncmp(entry->d_name, fileName, strlen(fileName)) == 0) {
                    printf("COUNT REACHED %d\n", countMatches);
                    matchedFiles[countMatches] = strdup(fullPath);
                    countMatches++;
                    printf("%s%s%s\n\n", COLOR_BLUE, fullPath, COLOR_RESET);
                }
            }
            searchDirectory(fullPath, fileName, f, d, e);
        }
        else if (!d && S_ISREG(statbuf.st_mode) && !(statbuf.st_mode & S_IXUSR)) {
            if (strncmp(entry->d_name, fileName, strlen(fileName)) == 0) {
                printf("COUNT REACHED %d\n", countMatches);
                matchedFiles[countMatches] = strdup(fullPath);
                countMatches++;
                printf("%s%s%s\n\n", COLOR_GREEN, fullPath, COLOR_RESET);
            }
        }
        else if (!d && S_ISREG(statbuf.st_mode) && (statbuf.st_mode & S_IXUSR)) {
            exec = 1;
            if (strncmp(entry->d_name, fileName, strlen(fileName)) == 0) {
                printf("COUNT REACHED %d\n", countMatches);
                matchedFiles[countMatches] = strdup(fullPath);
                countMatches++;
                printf("%s%s%s\n\n", COLOR_GREEN, fullPath, COLOR_RESET);
            }
        }
    }

    closedir(dp);
    //return;
}

void handle_seek(char *args, int pipeo){

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

    char *fileName = NULL;
    char *targetDir = NULL;

    int d = 0, f = 0, e = 0;
    int file = 0, target = 0;
    for(int k=0; k<i; k++){
        if (listArgs[k][0] == '-' && !file && !target){
            if (listArgs[k][1] == 'd')
                d = 1;
            else if (listArgs[k][1] == 'f')
                f = 1;
            else if (listArgs[k][1] == 'e')
                e = 1;
            else{
                printf("invalid flag or/and order\n");
                error = 1;
                return;
            }
        }
        else if (!file){
            fileName = strdup(listArgs[k]);
            file = 1;
        }
        else if (file && !target){
            targetDir = strdup(listArgs[k]);
            target = 1;
        }
    }
    if (d && f) {printf("both d and f flags specified\n"); error = 1; return;}
    if (!target) {targetDir = strdup(currentDir);}

    if (strcmp(targetDir, "~") == 0 || strcmp(targetDir, homeDir) == 0){
        if (targetDir) free(targetDir);
        targetDir = strdup(homeDir);
    }
    else if (strcmp(targetDir, "-") == 0){
        if (targetDir) free(targetDir);
        targetDir = strdup(prevDir);
    }
    else if (strcmp(targetDir, ".") == 0){
        if (targetDir) free(targetDir);
        targetDir = strdup(currentDir);
    }
    else if (strcmp(targetDir, "/") == 0){
        if (targetDir) free(targetDir);
        char *lastSlash = strrchr(currentDir, '/');
        char *slash = "/";
        if (*lastSlash == currentDir[0]) targetDir = strdup(slash);
        else if (lastSlash != NULL) {
            *lastSlash = '\0';
            targetDir = strdup(currentDir);
        }
    }
    else if (targetDir[0] == '~') {
        char expandedtargetDir[1024];
        snprintf(expandedtargetDir, sizeof(expandedtargetDir), "%s%s", homeDir, targetDir + 1);
        if (targetDir) free(targetDir);
        targetDir = strdup(expandedtargetDir);
    }
    else if (targetDir[0] == '.' && targetDir[1] == '/'){
        char expandedtargetDir[1024];
        snprintf(expandedtargetDir, sizeof(expandedtargetDir), "%s/%s", currentDir, targetDir + 2);
        if (targetDir) free(targetDir);
        targetDir = strdup(expandedtargetDir);
    }
    else if (targetDir[0] != '/'){
        char expandedtargetDir[1024];
        snprintf(expandedtargetDir, sizeof(expandedtargetDir), "%s/%s", currentDir, targetDir);
        if (targetDir) free(targetDir);
        targetDir = strdup(expandedtargetDir);
    }
    //printf("%s %s f? %d d? %d e? %d\n", fileName, targetDir, f, d, e);

    countMatches = 0;
    i = 0;
    while(matchedFiles[i] != NULL){
        free(matchedFiles[i]);
        matchedFiles[i] = NULL;
        i++;
    }
    
    searchDirectory(targetDir, fileName, f, d, e);
    recurse = 0;

    if (countMatches == 0)
        printf("No Match found!\n");

    else if (countMatches == 1 && e){
            if (direc){
                if (prevDir) free(prevDir);
                prevDir = strdup(currentDir);
                if (currentDir) free(currentDir);
                currentDir = strdup(matchedFiles[0]);
            } /*else if (exec){
                int pid = fork();
                if (pid < 0){
                    printf("failed to run executable\n");
                    error = 1;
                } else if (pid == 0){
                    char *argues[2];
                    argues[0] = strdup(matchedFiles[0]);
                    argues[1] = NULL;
                    if (execvp(matchedFiles[0], argues) == -1) {
                        perror("exec failed\n");
                        printf("Missing permissions for task!\n");
                        error = 1;
                        exit(EXIT_FAILURE);
                    }
                } else { waitpid(pid, NULL, 0);}
            }*/ else {
                FILE *file = fopen(matchedFiles[0], "r");
                if (file == NULL){
                    perror("file didn't open\n");
                    printf("Missing permissions for task!\n");
                    error = 1;
                    return;
                }
                rewind(file);
                char str[STRING_LENGTH];
                while (fgets(str, STRING_LENGTH, file) != NULL) {
                    printf("%s", str);
                }
                printf("\n");
                fclose(file);
            }
    }
    countMatches = 0; direc = 0; exec = 0;
    if (fileName) free(fileName);
    if (targetDir) free(targetDir);

    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);

    for (int j = 0; j < 10; j++)
        if (listArgs[j]) free(listArgs[j]);
    if (output_file) free(output_file);

}

