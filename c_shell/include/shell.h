#ifndef SHELL_H
#define SHELL_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <grp.h>
#include <time.h>
#include <pwd.h>
#include <dirent.h>
#include <math.h>
#include <errno.h>
#include <termios.h>
#include <ctype.h>
#include <arpa/inet.h>
#include <netdb.h> 


// Function Prototypes
void initQueue(Queue *q);
int isFull(Queue *q);
int isEmpty(Queue *q);
int dequeue(Queue *q, char *str);
int enqueue(Queue *q, const char *str);
int peek(Queue *q, char *str);
void displayQueue(Queue *q);
void handle_hop(char *args, int pipeo);
void printFileDetails(const char *name, const struct stat *fileStat);
int compareEntries(const void *a, const void *b);
void handle_reveal(char *args, int pipeo);
void searchDirectory(const char *dirPath, const char *fileName, const int f, const int d, const int e);
void handle_seek(char *args, int pipeo);
void read_lines(FILE *file, Queue *q, int *line_count);
void write_lines(FILE *logFile, Queue *q, int *line_count);
int handle_log(char *args, int pipeo);
void handle_proclore(char *args, int pipeo);
int is_process_running(pid_t pid);
int compare_cmds(const void *a, const void *b);
void handle_activities(char *args, int pipeo);
void handle_signals(char *args, int pipeo);
int is_gui_process(pid_t pid);
void handle_fg(char *args);
void handle_bg(char *args);
pid_t get_most_recent_pid();
int kbhit(void);
void handle_neonate(char *args);
void get_man_page(const char *command_name);
void handle_iMan(char *args, int pipeo);
void handle_sys(char *cmd, char *args, int bg, int pipei, int pipeo);
void add_alias(const char *alias, const char *command);
char* expand_alias(char *input);
void load_aliases();
void sigchld_handler(int sig);
void handle_sigint(int sig);
void handle_sigtstp(int sig);
void handle_sigquit(int sig);
void removeLeftSpaces(char **listOfCommands);
void extractCmd(char *source, command *dest);
void runCommand(command *executable);
void log_out(void);
void shell_loop(char *homeDir);

#endif
