/* ============================================================================
 *  Shell_POSIX-Core
 *  Author  : vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *  Unauthorized copying or false claim of authorship is prohibited.
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#ifndef LOG_H
#define LOG_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// File pointer for the log file
static FILE *log_file = NULL;

// Function to initialize the log file (clears previous content)
void initialize_log() {
    log_file = fopen("log.txt", "w"); // Open in write mode to clear previous content
    if (log_file == NULL) {
        perror("Failed to open log file");
        exit(EXIT_FAILURE);
    }
}

// Function to log a message to the file
void log_message(const char *msg) {
    if (log_file == NULL) {
        fprintf(stderr, "Log file not initialized. Call initialize_log() first.\n");
        return;
    }
    fprintf(log_file, "%s\n", msg);
    fflush(log_file); // Ensure data is written immediately
}

// Function to close the log file (optional, for cleanup)
void close_log() {
    if (log_file != NULL) {
        fclose(log_file);
        log_file = NULL;
    }
}

#endif // LOG_H
