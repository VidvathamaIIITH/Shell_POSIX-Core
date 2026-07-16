/* ============================================================================
 *  Shell_POSIX-Core  -  Author: vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *  Unauthorized copying or false claim of authorship is prohibited.
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

pid_t get_most_recent_pid() {
    DIR *proc_dir;
    struct dirent *entry;
    pid_t recent_pid = 0;
    time_t recent_time = 0;
    char path[268];
    FILE *stat_file;
    struct stat file_stat;

    proc_dir = opendir("/proc");
    if (proc_dir == NULL) {
        perror("opendir");
        return -1;
    }

    while ((entry = readdir(proc_dir)) != NULL) {
        // Check if entry is a directory and starts with a digit
        if (entry->d_type == DT_DIR && isdigit(entry->d_name[0])) {
            snprintf(path, sizeof(path), "/proc/%s/stat", entry->d_name);
            stat(path, &file_stat);

            if (file_stat.st_ctime > recent_time) {
                recent_time = file_stat.st_ctime;
                recent_pid = atoi(entry->d_name);
            }
        }
    }

    closedir(proc_dir);
    return recent_pid;
}

int kbhit(void) {
    struct termios oldt, newt;
    int ch;
    int oldf;

    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);

    ch = getchar();

    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    fcntl(STDIN_FILENO, F_SETFL, oldf);

    if(ch != EOF) {
        ungetc(ch, stdin);
        return 1;
    }

    return 0;
}

void handle_neonate(char *args){
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
    if (i>2){error = 1; return;}
    int interval = atoi(listArgs[1]);
    if (interval <= 0) {
        error = 1;
        printf("Invalid time argument. Please enter a positive number.\n");
        return;
    }
    while (1) {
        pid_t recent_pid = get_most_recent_pid();
        if (recent_pid == -1) {
            printf("Error retrieving recent PID.\n");
            error = 1;
            return;
        }

        printf("%d\n", recent_pid);

        sleep(interval);

        if (kbhit()) {
            char c = getchar();
            if (c == 'x') {
                break;
            }
        }
    }
}

