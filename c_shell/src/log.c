/* ============================================================================
 *  Shell_POSIX-Core  -  Author: vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *  Unauthorized copying or false claim of authorship is prohibited.
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

void read_lines(FILE *file, Queue *q, int *line_count) {
    rewind(file);  // Move the file pointer to the beginning
    *line_count = 0;
    char str[STRING_LENGTH];
    while (fgets(str, STRING_LENGTH, file) != NULL) {
        str[strcspn(str, "\n")] = '\0';  // Remove the newline character
        enqueue(q, str);  // Enqueue the string into the queue
        (*line_count)++;
        if (*line_count == MAX_SIZE) break;  // Stop if the queue reaches its maximum size
    }
    //displayQueue(&q);
}

void write_lines(FILE *logFile, Queue *q, int *line_count){
    if (logFile == NULL) {
        printf("Error: File is not open\n");
        return;
    }
    freopen(NULL, "w", logFile);
    if (q->size == 0) {
        printf("Queue is empty. Nothing to write.\n");
        return;
    }
    for (int i = 0; i < q->size; i++) {
        int index = (q->front + i) % MAX_SIZE;
        char buffer[1024];
        strcpy(buffer, q->items[index]);
        int j=0;
        while(buffer[j] != '\0'){
            j++;
        }
        buffer[j]='\n';
        buffer[++j] = '\0';
        fputs(buffer, logFile);
        //printf("%s\n", q.items[index]);
    }
}

int handle_log(char *args, int pipeo){
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
            return -1;
        }
        dup2(fd, STDOUT_FILENO);
        close(fd);
    }
    else if (double_output_redirect && output_file != NULL){
        int fd = open(output_file, O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (fd < 0){
            perror("failed to open/create redirected file\n");
            return -1;
        }
        dup2(fd, STDOUT_FILENO);
        close(fd);
    }

    if (strlen(args)==0 || i==0){
        displayQueue(&q);
        dup2(saved_stdout, STDOUT_FILENO);
        close(saved_stdout);
        for (int j = 0; j < 10; j++)
            if (listArgs[j]) free(listArgs[j]);
        if (output_file) free(output_file);

        return 1;

    }else{
        if (strcmp(listArgs[0], "purge") == 0){
            while(!isEmpty(&q)){
                char temp[STRING_LENGTH];
                dequeue(&q, temp);
            }
            dup2(saved_stdout, STDOUT_FILENO);
            close(saved_stdout);
            for (int j = 0; j < 10; j++)
                if (listArgs[j]) free(listArgs[j]);
            if (output_file) free(output_file);

            return 2;
        }
        else if (strcmp(listArgs[0], "execute") == 0 && 1<=atoi(listArgs[1]) && 15>=atoi(listArgs[1])){
            int x = atoi(listArgs[1]);
            if (q.size < x){
            printf("Not enough commands in log\n\n");
            return -1;
            }
            int idx = (q.rear - x + 1 + MAX_SIZE) % MAX_SIZE;
            log_exec = strdup(q.items[idx]);
            dup2(saved_stdout, STDOUT_FILENO);
            close(saved_stdout);
            for (int j = 0; j < 10; j++)
                if (listArgs[j]) free(listArgs[j]);
            if (output_file) free(output_file);

            return 3;
        }
        else {
            error = 1;
                dup2(saved_stdout, STDOUT_FILENO);
                close(saved_stdout);
                for (int j = 0; j < 10; j++)
                    if (listArgs[j]) free(listArgs[j]);
                if (output_file) free(output_file);
            }
    return -1;
    }
}

