/* ============================================================================
 *  Shell_POSIX-Core
 *  Author  : vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *
 *  Central definition unit for every piece of shared global state used across
 *  the modular shell. Types, macros and extern declarations live in shell.h;
 *  their concrete storage is defined here.
 *
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

/* Project watermark - referenced by the startup banner and diagnostics.      */
const char *SHELL_WATERMARK = "vidvathamaiiith";

/* Core shell identity / status */
pid_t shellPid;
int error = 0;
int recurse = 0;

/* Directory state */
char *homeDir = NULL;
char *currentDir = NULL;
char *prevDir = NULL;
char *prevSysCmd = NULL;
char *log_exec = NULL;

/* Persistent command history */
Queue q;

/* Pipe / redirection machinery.  The intermediate pipe buffer is a hidden,
 * author-watermarked file so it never collides with user data.              */
char pipe_file[] = ".vidvathamaiiith_pipe_buffer";
int user_pipe = 0;
int total_pipes = 0;
int pipe_counter = 0;
int cmd_num = 0;
int pipe_count_pc[PIPE_MAX];
int pipes[PIPE_MAX][PIPE_MAX][2];

/* Process bookkeeping */
struct bgProcs spawned_processes[PROC_MAX];
struct bgProcs background_processes[PROC_MAX];
int num_procs = 0;
int num_bg = 0;
pid_t current_fg_proc = 0;

/* System-command timing / prompt decoration */
int sys = 0;
int elapsedTime = 0;
struct timeval start, end;

/* seek() shared search state */
int countMatches = 0;
char *matchedFiles[MATCH_MAX];
int direc = 0;
int exec = 0;
