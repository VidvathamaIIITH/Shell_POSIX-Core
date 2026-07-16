/* ============================================================================
 *  Shell_POSIX-Core
 *  Author  : vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *
 *  Built-in : sysinfo
 *  ------------------------------------------------------------------------
 *  A live diagnostics dashboard that fuses operating-system telemetry (read
 *  straight from the /proc virtual filesystem) with the shell's own internal
 *  bookkeeping. It reports system uptime, load averages, physical memory
 *  utilisation, the number of children the shell has spawned, how many are
 *  still alive, and the depth of the persistent command history.
 *
 *  Usage:   sysinfo                (supports > , >> and | like every builtin)
 *
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

/* Reads the first floating point number out of a single-line /proc file. */
static int read_first_double(const char *path, double *out) {
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    int ok = (fscanf(f, "%lf", out) == 1);
    fclose(f);
    return ok;
}

/* Pulls MemTotal and MemAvailable (in kB) from /proc/meminfo. */
static int read_meminfo(long *total_kb, long *avail_kb) {
    FILE *f = fopen("/proc/meminfo", "r");
    if (!f) return 0;
    char line[256];
    long t = -1, a = -1;
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "MemTotal:", 9) == 0)      sscanf(line + 9, "%ld", &t);
        else if (strncmp(line, "MemAvailable:", 13) == 0) sscanf(line + 13, "%ld", &a);
    }
    fclose(f);
    if (t < 0) return 0;
    *total_kb = t;
    *avail_kb = (a < 0) ? 0 : a;
    return 1;
}

void handle_sysinfo(char *args, int pipeo) {
    error = 0;
    char *listArgs[10] = {NULL};
    char delims[] = " ";
    int i = 0;
    int output_redirect = 0, double_output_redirect = 0;
    char *output_file = NULL;
    char *token = strtok(args, delims);
    while (token != NULL) {
        if (strcmp(token, ">") == 0) {
            output_redirect = 1;
            token = strtok(NULL, delims);
            if (token != NULL) output_file = strdup(token);
        } else if (strcmp(token, ">>") == 0) {
            double_output_redirect = 1;
            token = strtok(NULL, delims);
            if (token != NULL) output_file = strdup(token);
        } else if (!output_redirect && !double_output_redirect && strcmp(token, "*") != 0) {
            listArgs[i] = strdup(token);
            i++;
        }
        token = strtok(NULL, delims);
    }
    listArgs[i] = NULL;

    if (pipeo) {
        user_pipe = 1;
        total_pipes--;
        output_file = strdup(pipe_file);
    }

    int saved_stdout = dup(STDOUT_FILENO);
    if ((user_pipe || output_redirect) && output_file != NULL) {
        int rfd = open(output_file, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (rfd < 0) { perror("failed to open/create redirected file\n"); return; }
        dup2(rfd, STDOUT_FILENO);
        close(rfd);
    } else if (double_output_redirect && output_file != NULL) {
        int rfd = open(output_file, O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (rfd < 0) { perror("failed to open/create redirected file\n"); return; }
        dup2(rfd, STDOUT_FILENO);
        close(rfd);
    }

    /* ----- gather telemetry ------------------------------------------------ */
    double uptime = 0.0, l1 = 0.0, l2 = 0.0, l3 = 0.0;
    int have_uptime = read_first_double("/proc/uptime", &uptime);

    FILE *lf = fopen("/proc/loadavg", "r");
    int have_load = 0;
    if (lf) {
        have_load = (fscanf(lf, "%lf %lf %lf", &l1, &l2, &l3) == 3);
        fclose(lf);
    }

    long mem_total = 0, mem_avail = 0;
    int have_mem = read_meminfo(&mem_total, &mem_avail);

    int alive = 0;
    for (int n = 0; n < num_procs; n++) {
        if (is_process_running(spawned_processes[n].pidBg) != 0) alive++;
    }

    /* ----- render ---------------------------------------------------------- */
    printf("%s", COLOR_BLUE);
    printf("  Shell_POSIX-Core :: sysinfo      (c) %s\n", SHELL_WATERMARK);
    printf("  ------------------------------------------------------------\n");
    printf("%s", COLOR_RESET);

    printf("  Shell PID           : %d\n", (int)shellPid);
    printf("  Working directory   : %s\n", currentDir ? currentDir : "(unknown)");

    if (have_uptime) {
        long secs = (long)uptime;
        long days = secs / 86400; secs %= 86400;
        long hrs  = secs / 3600;  secs %= 3600;
        long mins = secs / 60;    secs %= 60;
        printf("  System uptime       : %ldd %02ldh %02ldm %02lds\n", days, hrs, mins, secs);
    } else {
        printf("  System uptime       : unavailable\n");
    }

    if (have_load)
        printf("  Load average        : %.2f  %.2f  %.2f   (1 / 5 / 15 min)\n", l1, l2, l3);
    else
        printf("  Load average        : unavailable\n");

    if (have_mem && mem_total > 0) {
        long used_kb = mem_total - mem_avail;
        double used_mb  = used_kb   / 1024.0;
        double total_mb = mem_total / 1024.0;
        double pct = (double)used_kb * 100.0 / (double)mem_total;
        printf("  Physical memory     : %.0f / %.0f MB used  (%.1f%%)\n", used_mb, total_mb, pct);
    } else {
        printf("  Physical memory     : unavailable\n");
    }

    printf("  Children spawned    : %d\n", num_procs);
    printf("  Children still alive: %d\n", alive);
    printf("  History entries     : %d / %d\n", q.size, MAX_SIZE);
    printf("%s  Watermark           : %s%s\n", COLOR_GREEN, SHELL_WATERMARK, COLOR_RESET);
    printf("\n");

    fflush(stdout);
    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);

    for (int j = 0; j < 10; j++)
        if (listArgs[j]) free(listArgs[j]);
    if (output_file) free(output_file);
}
