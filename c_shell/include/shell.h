/* ============================================================================
 *  Shell_POSIX-Core
 *  Author  : vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *
 *  This source file is the intellectual property of vidvathamaiiith.
 *  Unauthorized copying, redistribution, or false claim of authorship of any
 *  portion of this project is strictly prohibited.
 *
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
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
#include <sys/socket.h>
#include <netinet/in.h>
#include <signal.h>
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

/* ----------------------------------------------------------------------------
 *  Compile-time configuration
 * --------------------------------------------------------------------------*/
#define MAX_SIZE               15        /* history ring-buffer capacity      */
#define STRING_LENGTH          1024      /* max stored command length         */
#define BUFFER_SIZE            4096       /* iMan request buffer               */
#define BUFFER_SIZE_RESPONSE   100000     /* iMan response buffer              */
#define PORT                   80         /* iMan (man.he.net) port            */
#define RECURSION_DEPTH        10000      /* seek recursion guard              */
#define PIPE_MAX               100        /* max command groups / pipes        */
#define PROC_MAX               4096       /* tracked spawned/background procs  */
#define MATCH_MAX              4096       /* seek match capacity               */

/* ANSI colour codes used by reveal/seek for coloured listings                */
#define COLOR_RESET   "\033[0m"
#define COLOR_WHITE   "\033[1;37m"
#define COLOR_BLUE    "\033[1;34m"
#define COLOR_GREEN   "\033[1;32m"

/* ----------------------------------------------------------------------------
 *  Shared data types
 * --------------------------------------------------------------------------*/
typedef struct {
    char items[MAX_SIZE][STRING_LENGTH];  /* stored command strings           */
    int front;                            /* index of the front element       */
    int rear;                             /* index of the rear element        */
    int size;                             /* current number of stored items   */
} Queue;

typedef struct command {
    char cmd[100];
    char argument[500];
    int numArgs;
    int background;
    int pipei;
    int pipeo;
} command;

struct bgProcs {
    pid_t pidBg;      /* process id                                           */
    char *procName;   /* executable name                                      */
    int status;       /* 0 = gone, 1 = running/sleeping, 2 = stopped          */
};

/* ----------------------------------------------------------------------------
 *  Shared global state (definitions live in src/globals.c)
 * --------------------------------------------------------------------------*/
extern const char *SHELL_WATERMARK;       /* "vidvathamaiiith"                */

extern pid_t shellPid;                    /* pid of the shell itself          */
extern int error;                         /* set by handlers on failure       */
extern int recurse;                       /* seek recursion counter           */

extern char *homeDir;                     /* directory the shell started in   */
extern char *currentDir;                  /* logical current directory        */
extern char *prevDir;                     /* previous directory (for hop -)   */
extern char *prevSysCmd;                  /* last system command (for prompt) */
extern char *log_exec;                    /* command queued by "log execute"  */

extern Queue q;                           /* persistent command history       */

extern char pipe_file[];                  /* intermediate buffer for pipes    */
extern int user_pipe;                     /* a builtin is piping its output   */
extern int total_pipes;                   /* pipes remaining in current group */
extern int pipe_counter;                  /* current pipe stage               */
extern int cmd_num;                       /* current command-group index      */
extern int pipe_count_pc[PIPE_MAX];       /* pipe count per command group     */
extern int pipes[PIPE_MAX][PIPE_MAX][2];  /* pipe file descriptors            */

extern struct bgProcs spawned_processes[PROC_MAX];    /* every child spawned  */
extern struct bgProcs background_processes[PROC_MAX]; /* background children  */
extern int num_procs;                     /* count in spawned_processes       */
extern int num_bg;                        /* count in background_processes    */
extern pid_t current_fg_proc;             /* current foreground child, or 0   */

extern int sys;                           /* last command was a system cmd    */
extern int elapsedTime;                   /* wall time of last system cmd     */
extern struct timeval start, end;         /* timing of last system cmd        */

extern int countMatches;                  /* seek: matches found              */
extern char *matchedFiles[MATCH_MAX];     /* seek: matched paths              */
extern int direc;                         /* seek: a directory matched        */
extern int exec;                          /* seek: an executable matched      */

/* ----------------------------------------------------------------------------
 *  Function prototypes
 * --------------------------------------------------------------------------*/
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

/* --- vidvathamaiiith extensions ------------------------------------------- */
void handle_sysinfo(char *args, int pipeo);  /* system + shell diagnostics    */
void handle_mark(char *args, int pipeo);     /* persistent directory bookmarks*/
void handle_calc(char *args, int pipeo);     /* inline arithmetic evaluator   */
void print_shell_banner(void);               /* watermark startup banner      */

#endif
