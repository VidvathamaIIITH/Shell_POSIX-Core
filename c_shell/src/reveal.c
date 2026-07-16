/* ============================================================================
 *  Shell_POSIX-Core  -  Author: vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *  Unauthorized copying or false claim of authorship is prohibited.
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

void printFileDetails(const char *name, const struct stat *fileStat) {
    char permissions[11];
    strcpy(permissions, "----------");

    if (S_ISDIR(fileStat->st_mode)) permissions[0] = 'd';
    if (S_ISLNK(fileStat->st_mode)) permissions[0] = 'l';

    if (fileStat->st_mode & S_IRUSR) permissions[1] = 'r';
    if (fileStat->st_mode & S_IWUSR) permissions[2] = 'w';
    if (fileStat->st_mode & S_IXUSR) permissions[3] = 'x';
    if (fileStat->st_mode & S_IRGRP) permissions[4] = 'r';
    if (fileStat->st_mode & S_IWGRP) permissions[5] = 'w';
    if (fileStat->st_mode & S_IXGRP) permissions[6] = 'x';
    if (fileStat->st_mode & S_IROTH) permissions[7] = 'r';
    if (fileStat->st_mode & S_IWOTH) permissions[8] = 'w';
    if (fileStat->st_mode & S_IXOTH) permissions[9] = 'x';

    char timeStr[20];
    strftime(timeStr, sizeof(timeStr), "%b %d %H:%M", localtime(&fileStat->st_mtime));

    const char *color = COLOR_WHITE;  // Default color for files
    if (S_ISDIR(fileStat->st_mode)) {
        color = COLOR_BLUE;  // Blue for directories
    } else if (fileStat->st_mode & S_IXUSR) {
        color = COLOR_GREEN;  // Green for executables
    }

    printf("%s%s %ld %s %s %5ld %s %s%s\n",
           color,
           permissions,
           fileStat->st_nlink,
           getpwuid(fileStat->st_uid)->pw_name,
           getgrgid(fileStat->st_gid)->gr_name,
           fileStat->st_size,
           timeStr,
           name,
           COLOR_RESET);
}

int compareEntries(const void *a, const void *b) {
    return strcmp(*(const char **)a, *(const char **)b);
}

void handle_reveal(char *args, int pipeo){

    error = 0;
    /*char *listArgs[10];
    char delims[] = " ";
    int i = 0;
    listArgs[i] = strtok(args, delims);
    while (listArgs[i] != NULL) {
        //printf("%s\n", listArgs[i]);
        i++;
        listArgs[i] = strtok(NULL, delims);
    }
    i--;*/
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
    i--;
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

    int noarg = 0;
    char *path = NULL;
    if (strlen(args)==0){
        if (path) free(path);
        path = strdup(currentDir);
    } else {
        path = strdup(listArgs[i]);
        if (path[0] == '-' && (path[1]=='l' || path[1]=='a')){
            noarg = 1;
            free(path);
            path = strdup(currentDir);
            //printf("this is the path detected %s\n", path);
            i++;
        }
    }

    int a = 0, l = 0;
    if (i>=1){
        char *flag;
        for(int k=0; k<i; k++){
            flag = listArgs[k];
            //printf("%c\n", *flag);
            if (listArgs[k][0] != '-'){
                printf("invalid flag\n");
                //error = 1;
                return;
            } else{ flag++; }
            while(*flag != '\0'){
                if ((*flag != 'a') && (*flag != 'l')){
                    printf("invalid flag\n");
                    //error = 1;
                    return;
                } 
                else if (*flag == 'a')
                    a = 1;
                else if (*flag == 'l')
                    l = 1;
                flag++;
            }
        }
    }
    //printf("a is %d, l is %d\n", a, l);
    struct dirent *entry;
    struct stat fileStat;

    if (strcmp(path, "~") == 0 || strcmp(path, homeDir) == 0){
        if (path) free(path);
        path = strdup(homeDir);
    }
    else if (strcmp(path, "-") == 0){
        if (path) free(path);
        path = strdup(prevDir);
    }
    else if (strcmp(path, ".") == 0){
        if (path) free(path);
        path = strdup(currentDir);
    }
    else if (strcmp(path, "/") == 0){
        if (path) free(path);
        char *lastSlash = strrchr(currentDir, '/');
        char *slash = "/";
        if (*lastSlash == currentDir[0]) path = strdup(slash);
        else if (lastSlash != NULL) {
            *lastSlash = '\0';
            path = strdup(currentDir);
        }
    }
    else if (strlen(args) != 0) {
            if (path[0] == '~') {
                char expandedPath[1024];
                snprintf(expandedPath, sizeof(expandedPath), "%s%s", homeDir, path + 1);
                if (path) free(path);
                path = strdup(expandedPath);
            }
            else if (path[0] == '.' && path[1] == '/'){
                char expandedPath[1024];
                snprintf(expandedPath, sizeof(expandedPath), "%s/%s", currentDir, path + 2);
                if (path) free(path);
                path = strdup(expandedPath);
            }
            else if (path[0] != '/'){
                char expandedPath[1024];
                snprintf(expandedPath, sizeof(expandedPath), "%s/%s", currentDir, path);
                if (path) free(path);
                path = strdup(expandedPath);
            }
        }

    DIR *dir = opendir(path);

    if (dir == NULL) {
        perror("opendir");
        error = 1;
        return;
    }

    char *entries[1024];
    int totalFiles = 0;

    while ((entry = readdir(dir)) != NULL) {
        if (!a && entry->d_name[0] == '.') {
            continue;  // Skip hidden files if -a is not set
        }

        entries[totalFiles] = strdup(entry->d_name);
        totalFiles++;
    }
    closedir(dir);

    // Sort the entries lexicographically
    qsort(entries, totalFiles, sizeof(char *), compareEntries);

    for (int i = 0; i < totalFiles; i++){

        // Create the full file path
        char fullPath[1024];
        snprintf(fullPath, sizeof(fullPath), "%s/%s", path, entries[i]);

        // Get file status
        if (stat(fullPath, &fileStat) == -1) {
            perror("stat");
            continue;
        }

        const char *color = COLOR_WHITE;  // Default color for files
        if (S_ISDIR(fileStat.st_mode)) {
            color = COLOR_BLUE;  // Blue for directories
        } else if (fileStat.st_mode & S_IXUSR) {
            color = COLOR_GREEN;  // Green for executables
        }

        if (l) {
            printFileDetails(entries[i], &fileStat);
        } else {
            printf("%s%s%s", color, entries[i], COLOR_RESET);
            if (S_ISDIR(fileStat.st_mode)) {
                printf("/");
            }
            printf("\n");
        }
        free(entries[i]);
    }
    if (path) free(path);
    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);

    for (int j = 0; j < 10; j++)
        if (listArgs[j]) free(listArgs[j]);
    if (output_file) free(output_file);

}

