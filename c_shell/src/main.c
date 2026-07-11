#include "shell.h"

int status = 1;

int fd;
int *numLines;
FILE* logFile;
int log_ = 0;
int log_exec_flag;

typedef struct command {
    char cmd[100];
    char argument[500];
    int numArgs;
    int background;
    int pipei;
    int pipeo;
} command;

#define MAX_ALIASES 100
#define MAX_COMMAND_LENGTH 256

typedef struct {
    char alias[MAX_COMMAND_LENGTH];
    char command[MAX_COMMAND_LENGTH];
} Alias;

Alias alias_table[MAX_ALIASES];
int alias_count = 0;

// Function to add an alias
void add_alias(const char *alias, const char *command) {
    if (alias_count < MAX_ALIASES) {
        strcpy(alias_table[alias_count].alias, alias);
        strcpy(alias_table[alias_count].command, command);
        alias_count++;
    } else {
        printf("Alias limit reached\n");
    }
}

// Function to find and return the alias's expanded command
char* expand_alias(char *input) {
    for (int i = 0; i < alias_count; i++) {
        if (strcmp(alias_table[i].alias, input) == 0) {
            input = strdup(alias_table[i].command);
        }
    }
    return input; // Return input as-is if no alias found
}

// Function to parse and load aliases from .myshrc
void load_aliases() {
    char *home = getenv("HOME");
    char path[256];

    if (home != NULL) {
        snprintf(path, sizeof(path), ".myshrc");
        FILE *file = fopen(path, "r");
        if (file != NULL) {
            char line[MAX_COMMAND_LENGTH];
            while (fgets(line, sizeof(line), file) != NULL) {
                // Parse alias definitions like "alias reveall='reveal -l'"
                if (strncmp(line, "alias", 5) == 0) {
                    char alias[MAX_COMMAND_LENGTH], command[MAX_COMMAND_LENGTH];
                    if (sscanf(line, "alias %s = %[^\n]", alias, command) == 2) {
                        add_alias(alias, command);
                    }
                }
            }
            fclose(file);
        }
    }
}

void sigchld_handler(int sig) {
    int status_;
    pid_t pid;
    while ((pid = waitpid(-1, &status_, WNOHANG | WCONTINUED)) > 0) {
        int p = 0;
        while(background_processes[p].pidBg != pid) p++;
        if (WIFEXITED(status_)) {
            printf("\n%s exited normally (%d)\n", background_processes[p].procName, pid);
        } else if (WIFSIGNALED(status_)) {
            printf("\n%s exited abnormally (%d)\n", background_processes[p].procName, pid);
        } // Check if the child was stopped (e.g., by Ctrl+Z or SIGTSTP)
        else if (WIFSTOPPED(status)) {
            printf("Process %d stopped by signal %d\n", pid, WSTOPSIG(status));
        }
        // Check if the child was continued (e.g., by SIGCONT)
        else if (WIFCONTINUED(status)) {
            printf("Process %d continued\n", pid);
        }
    }
}

void handle_sigint(int sig) {
    if (current_fg_proc)
        kill(current_fg_proc, SIGINT);
}

void handle_sigtstp(int sig) {
    if (current_fg_proc){
        int pid = current_fg_proc;
        if (kill(pid, SIGTSTP) == -1) {
            perror("Error stopping process with SIGTSTP");
        }
    }
}

void handle_sigquit(int sig) {
    for(int i=0; i<num_procs; i++){
        kill(spawned_processes[i].pidBg, SIGKILL);
    }
}

void removeLeftSpaces(char **listOfCommands) {
    int i = 0;
    char *str = listOfCommands[i];
    while (str) {
        int ch = 0;
        while (str[ch] == ' ') {
            ch++;
        }
        char *temp = malloc(strlen(str) - ch + 2);  // Correct allocation size
        if (temp == NULL) {
            perror("malloc failed for temp\n");
            exit(1);
        }
        strcpy(temp, &str[ch]);
        strcpy(listOfCommands[i], temp);
        free(temp);
        str = listOfCommands[++i];
    }
}

void extractCmd(char *source, command *dest) {

    if (strcmp(source, "hop") == 0) {
        strcpy(dest->cmd, "hop");
        dest->argument[0] = '\0';
        dest->background = 0;
    }
    else if (strlen(source) >= 4 && strncmp(source, "hop ", 4) == 0) { // at least 1 space before & after pipe | out for all user commands
        strcpy(dest->cmd, "hop");
        strcpy(dest->argument, &source[4]);
        dest->background = 0;
        if (source[strlen(source)-1] == '*'){
            dest->pipeo = 1;
        } else {dest->pipeo = 0;}
    }
    else if (strcmp(source, "reveal") == 0) {
        strcpy(dest->cmd, "reveal");
        dest->argument[0] = '\0';
        dest->background = 0;
    }
    else if (strlen(source) >= 7 && strncmp(source, "reveal ", 7) == 0){
        strcpy(dest->cmd, "reveal");
        strcpy(dest->argument, &source[7]);
        dest->background = 0;
        if (source[strlen(source)-1] == '*'){
            dest->pipeo = 1;
        } else {dest->pipeo = 0;}
    }
    else if (strlen(source) >= 5 && strncmp(source, "seek ", 5) == 0){
        strcpy(dest->cmd, "seek");
        strcpy(dest->argument, &source[5]);
        dest->background = 0;
        if (source[strlen(source)-1] == '*'){
            dest->pipeo = 1;
        } else {dest->pipeo = 0;}
    }
    else if (strlen(source) == 3 && strncmp(source, "log", 3) == 0){
        strcpy(dest->cmd, "log");
        dest->argument[0] = '\0';
        dest->background = 0;
    }
    else if (strlen(source) > 3 && strncmp(source, "log ", 4) == 0){
        strcpy(dest->cmd, "log");
        strcpy(dest->argument, &source[4]);
        dest->background = 0;
        if (source[strlen(source)-1] == '*'){
            dest->pipeo = 1;
        } else {dest->pipeo = 0;}
    }
    else if (strlen(source) >= 4 && strncmp(source, "exit", 4) == 0){
        strcpy(dest->cmd, "exit");
        dest->argument[0] = '\0';
        dest->background = 0;
    }
    else if (strlen(source) == 8 && strncmp(source, "proclore", 8) == 0){
        strcpy(dest->cmd, "proclore");
        dest->argument[0] = '\0';
        dest->background = 0;
    }
    else if (strlen(source) > 8 && strncmp(source, "proclore ", 9) == 0){
        strcpy(dest->cmd, "proclore");
        strcpy(dest->argument, &source[9]);
        dest->background = 0;
        if (source[strlen(source)-1] == '*'){
            dest->pipeo = 1;
        } else {dest->pipeo = 0;}
    }
    else if (strlen(source) == 10 && strncmp(source, "activities", 10) == 0){
        strcpy(dest->cmd, "activities");
        dest->argument[0] = '\0';
        dest->background = 0;
    }
    else if (strlen(source) >= 10 && strncmp(source, "activities ", 11) == 0){
        strcpy(dest->cmd, "activities");
        strcpy(dest->argument, &source[11]);
        dest->background = 0;
        if (source[strlen(source)-1] == '*'){
            dest->pipeo = 1;
        } else {dest->pipeo = 0;}
    }
    else if (strlen(source) >= 5 && strncmp(source, "ping ", 5) == 0){
        strcpy(dest->cmd, "ping");
        strcpy(dest->argument, &source[5]);
        dest->background = 0;
        if (source[strlen(source)-1] == '*'){
            dest->pipeo = 1;
        } else {dest->pipeo = 0;}
    }
    else if (strlen(source) >= 3 && strncmp(source, "fg ", 3) == 0){
        strcpy(dest->cmd, "fg");
        strcpy(dest->argument, &source[3]);
        dest->background = 0;
    }
    else if (strlen(source) >= 3 && strncmp(source, "bg ", 3) == 0){
        strcpy(dest->cmd, "bg");
        strcpy(dest->argument, &source[3]);
        dest->background = 0;
    }
    else if (strlen(source) >= 8 && strncmp(source, "neonate ", 8) == 0){
        strcpy(dest->cmd, "neonate");
        strcpy(dest->argument, &source[8]);
        dest->background = 0;
    }
    else if (strlen(source) >= 4 && strncmp(source, "iMan ", 4) == 0){
        strcpy(dest->cmd, "iMan");
        strcpy(dest->argument, &source[4]);
        dest->background = 0;
        if (source[strlen(source)-1] == '*'){
            dest->pipeo = 1;
        } else {dest->pipeo = 0;}
    }
    else {
        char sysCmd[100];
        int i = 0;
        if (source[0]=='*' && source[1]== '*') perror("Invalid use of pipes\n");
        if (source[i] == '*'){
            dest->pipei = 1;
            i++;
        } else {dest->pipei = 0;}
        if (source[strlen(source)-1] == '*'){
            dest->pipeo = 1;
        } else {dest->pipeo = 0;}
        int j = 0;
        while (source[i] != ' ' && source[i] != '$' && source[i] != '*' && source[i] != '\0'){
            sysCmd[j] = source[i];
            j++;
            i++;
        }
        sysCmd[j] = '\0';
        strcpy(dest->cmd, sysCmd);
        if (source[strlen(source)-1] == '$')
            dest->background = 1;
        else dest->background = 0;
        i++;
        char args[1000];
        j = 0;
        if (source[j] == '*') j++;
        while (source[j] != '$' && source[j] != '\0' && source[j] != '*'){
            args[j-1] = source[j];
            j++;
        }
        args[j-1]='\0';
        strcpy(dest->argument, args);
    }
}

void runCommand(command *executable) {
    if (strcmp(executable->cmd, "hop") == 0) {
        handle_hop(executable->argument, executable->pipeo);
    }
    else if (strcmp(executable->cmd, "reveal") == 0) {
        handle_reveal(executable->argument, executable->pipeo);
    }
    else if (strcmp(executable->cmd, "seek") == 0){
        handle_seek(executable->argument, executable->pipeo);
    }
    else if (strcmp(executable->cmd, "exit") == 0){
        status = 0;
    }
    else if (strcmp(executable->cmd, "log") == 0){
        log_ = 1;
        if (handle_log(executable->argument, executable->pipeo) == 3){
            log_exec_flag = 1;
            status = 0;
        }
    }
    else if (strcmp(executable->cmd, "proclore") == 0){
        handle_proclore(executable->argument, executable->pipeo);
    }
    else if (strcmp(executable->cmd, "activities") == 0){
        handle_activities(executable->argument, executable->pipeo);
    }
    else if (strcmp(executable->cmd, "ping") == 0){
        handle_signals(executable->argument, executable->pipeo);
    }
    else if (strcmp(executable->cmd, "fg") == 0){
        handle_fg(executable->argument);
    }
    else if (strcmp(executable->cmd, "bg") == 0){
        handle_bg(executable->argument);
    }
    else if (strcmp(executable->cmd, "neonate") == 0){
        handle_neonate(executable->argument);
    }
    else if (strcmp(executable->cmd, "iMan") == 0){
        handle_iMan(executable->argument, executable->pipeo);
    }
    else{
        handle_sys(executable->cmd, executable->argument, executable->background, executable->pipei, executable->pipeo);
    }
    if (error){ 
        error = 0;
        printf("\nErroneous command.\n\n");
        return;
    }
    return;
}

void log_out(void){
    for(int i=0; i<num_procs; i++){
        kill(spawned_processes[i].pidBg, SIGKILL);
    }
    write_lines(logFile, &q, numLines);
    if (prevSysCmd) free(prevSysCmd);
    free(homeDir);
    free(numLines);
    fclose(logFile);
    exit(0);
}

void shell_loop(char *homeDir) {
    log_ = 0;
    const char *home = strdup(homeDir);
    do {
        char *input = NULL;
        int i = 0;
        //printf("log exec flag is on %d\n", log_exec_flag);
        if (!log_exec_flag){
            uid_t uid = geteuid();
            struct passwd *pw = getpwuid(uid);

            char *userName = strdup(pw->pw_name);
            if (userName == NULL) {
                perror("strdup for username failed\n");
                exit(1);
            }

            char sysName[HOST_NAME_MAX + 1];
            if (gethostname(sysName, sizeof(sysName)) == -1) {
                perror("couldn't derive host name\n");
                free(userName);
                exit(1);
            }

            //printf("home is %s\n", home);
            //printf("currentDir id %s\n", currentDir);
            if (sys && elapsedTime > 2){
                if (strncmp(currentDir, home, (int)strlen(home)) == 0)
                    printf("<%s@%s:~%s %s : %ds> ", userName, sysName, &currentDir[strlen(home)], prevSysCmd, elapsedTime);
                else
                    printf("<%s@%s:%s %s : %ds> ", userName, sysName, currentDir, prevSysCmd, elapsedTime);
                sys = 0;
            }
            else {
                if (strncmp(currentDir, home, (int)strlen(home)) == 0)
                    printf("<%s@%s:~%s> ", userName, sysName, &currentDir[strlen(home)]);
                else
                    printf("<%s@%s:%s> ", userName, sysName, currentDir);
            }

            free(userName);

            input = malloc(1024);
            if (input == NULL) {
                perror("malloc for input failed\n");
                exit(1);
            }
            char c;
            while ((c = getchar()) != '\n' && i < 1023) {  // Avoid buffer overflow
                if (c == EOF){log_out();} // handling Ctrl+D
                input[i++] = c;
            }
            input[i] = '\0';
            input = expand_alias(input);
        }

        char *processedInput = malloc(2048);
        if (processedInput == NULL) {
            perror("malloc for processedInput failed\n");
            free(input);
            exit(1);
        }
        if (log_exec_flag) {
            input = strdup(log_exec);
            free(log_exec);
        }

        int j = 0;
        cmd_num = 0;
        for(int cl =0; cl<100; cl++){
            pipe_count_pc[cl] = 0;
        }
        pipe_count_pc[cmd_num] = 0;
        int p_sc=0;// at least 1 space character before and after a pipe + file locking (hop)
        int p = 0, p_before = 0, p_after = 1;
        for (int i = 0; input[i] != '\0'; i++) {
            int pipef = 0;
            if (input[i] == '&') {
                processedInput[j++] = '$';
                p_sc = 1;
            }
            else if (input[i] == '|') {
                if (p_sc == 1){
                    p_sc = 0;
                    cmd_num++;
                }
                pipe_count_pc[cmd_num]++;
                pipef = 1;
                processedInput[j++] = '*';
                processedInput[j++] = '|';
            }
            if (pipef) {
                processedInput[j++] = '*';
                while (input[i + 1] == ' ') {
                    i++;
                }
            } else {
                if (input[i] == ';'){
                   p_sc = 1;
                }
                processedInput[j++] = input[i];
            }
        }
        processedInput[j] = '\0';

        if (error){
            error = 0;
            perror("Invalid use of pipes\n");
            continue;
        }

        pipe_counter = 0;
        for (int l=0; l<=cmd_num; l++){
            for(int k=0; k<pipe_count_pc[l]; k++){
                //printf("num_pipes %d\n", pipe_count_pc[l]);
                if (pipe(pipes[l][k]) == -1){
                    perror("pipe error\n");
                    exit(1);
                }
            }
        }
        cmd_num = 0;
        total_pipes = pipe_count_pc[0];

        char **listOfCommands = malloc(100 * sizeof(char *));
        if (listOfCommands == NULL) {
            perror("malloc for listOfCommands failed!\n");
            free(input);
            free(processedInput);
            exit(1);
        }

        char delims[] = ";&|";
        i = 0;
        listOfCommands[i] = strtok(processedInput, delims);
        while (listOfCommands[i] != NULL) {
            listOfCommands[++i] = strtok(NULL, delims);
        }

        removeLeftSpaces(listOfCommands);

        command **executableCommands = malloc(100 * sizeof(command *));
        if (executableCommands == NULL) {
            perror("malloc failed for executableCommands\n");
            free(input);
            free(processedInput);
            free(listOfCommands);
            exit(1);
        }

        i = 0;
        while (listOfCommands[i] != NULL) {
            executableCommands[i] = malloc(sizeof(command));
            if (executableCommands[i] == NULL) {
                perror("malloc failed for executableCommands[i]\n");
                for (int k = 0; k < i; k++) free(executableCommands[k]);
                free(executableCommands);
                free(input);
                free(processedInput);
                free(listOfCommands);
                exit(1);
            }
            extractCmd(listOfCommands[i], executableCommands[i]);
            i++;
        }

        if (log_exec_flag) log_exec_flag = 0;
        //if (log_exec) free(log_exec);

        int numCommands = i;
        for (i = 0; i < numCommands; i++) {
            runCommand(executableCommands[i]);
            free(executableCommands[i]);
        }
        if (!log_ && strcmp(input, q.items[(q.rear + MAX_SIZE)%MAX_SIZE]) != 0){
            enqueue(&q, input);
        }
        log_ = 0;

        free(executableCommands);
        free(input);
        free(processedInput);
        free(listOfCommands);

    } while (status);
}

int main(void) {

    //setvbuf(stdout, NULL, _IONBF, 0);  // Disable buffering
    //setvbuf(stdin, NULL, _IONBF, 0);  // Disable buffering
   
    shellPid = getpid();

    homeDir = malloc(100);
    if (homeDir == NULL) {
        perror("malloc for homeDir failed\n");
        exit(1);
    }

    if (getcwd(homeDir, 100) == NULL) {
        perror("getcwd failed\n");
        free(homeDir);
        exit(1);
    }

    currentDir = strdup(homeDir);
    prevDir = strdup(homeDir);

    // Load aliases from .myshrc
    load_aliases();

    // Install the SIGCHLD handler
    struct sigaction sa;
    sa.sa_handler = sigchld_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;  // Restart interrupted system calls
    if (sigaction(SIGCHLD, &sa, NULL) == -1) {
        perror("sigaction failed");
        exit(EXIT_FAILURE);
    }
    signal(SIGINT, handle_sigint);    // Ctrl+C
    signal(SIGTSTP, handle_sigtstp);  // Ctrl+Z

    fd = open("log_commands_shell.txt", O_RDWR | O_CREAT | O_APPEND, 0644);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    // Convert the file descriptor to a FILE* using fdopen.
    logFile = fdopen(fd, "a+"); 
    if (logFile == NULL) {
        perror("fdopen");
        close(fd);
        return 1;
    }
    
    initQueue(&q);
    numLines = malloc(sizeof(int));
    if (numLines == NULL)
        perror("malloc failed.\n log won't be supported.\n");
    else
        read_lines(logFile, &q, numLines);

    shell_loop(homeDir);
    
    while (log_exec_flag){
        status = 1;
        shell_loop(homeDir);
    }
    write_lines(logFile, &q, numLines);

    if (prevSysCmd) free(prevSysCmd);
    free(homeDir);
    free(numLines);
    fclose(logFile);
    return 0;
}
