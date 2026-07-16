/* ============================================================================
 *  Shell_POSIX-Core
 *  Author  : vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *
 *  Built-in : mark   (persistent directory bookmarks)
 *  ------------------------------------------------------------------------
 *  Lets the user tag any directory with a short label and teleport back to it
 *  later, from anywhere in the filesystem. Bookmarks survive across sessions:
 *  they are stored in an author-watermarked dotfile in the shell's home
 *  directory. Navigation updates the shell's logical directory state exactly
 *  like `hop`, so `hop -` still returns to where you came from.
 *
 *  Usage:
 *      mark <name>        save the current directory under <name>
 *      mark -g <name>     go to the directory bookmarked as <name>
 *      mark -d <name>     delete the bookmark <name>
 *      mark -l            list every saved bookmark   (supports > >> |)
 *
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

#define MARK_MAX      256
#define MARK_NAME_LEN 256
#define MARK_PATH_LEN 1024

/* Builds the absolute path of the bookmarks store inside the shell home. */
static void marks_file_path(char *out, size_t n) {
    const char *base = homeDir ? homeDir : ".";
    snprintf(out, n, "%s/.vidvathamaiiith_marks", base);
}

/* Loads every bookmark from disk. Returns the number of bookmarks read. */
static int load_marks(char names[][MARK_NAME_LEN], char paths[][MARK_PATH_LEN]) {
    char file[MARK_PATH_LEN];
    marks_file_path(file, sizeof(file));
    FILE *f = fopen(file, "r");
    if (!f) return 0;
    int count = 0;
    char line[MARK_NAME_LEN + MARK_PATH_LEN + 4];
    while (count < MARK_MAX && fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = '\0';
        if (line[0] == '\0') continue;
        char *tab = strchr(line, '\t');
        if (!tab) continue;
        *tab = '\0';
        strncpy(names[count], line, MARK_NAME_LEN - 1);
        names[count][MARK_NAME_LEN - 1] = '\0';
        strncpy(paths[count], tab + 1, MARK_PATH_LEN - 1);
        paths[count][MARK_PATH_LEN - 1] = '\0';
        count++;
    }
    fclose(f);
    return count;
}

/* Persists the bookmark table back to disk. Returns 1 on success. */
static int save_marks(char names[][MARK_NAME_LEN], char paths[][MARK_PATH_LEN], int count) {
    char file[MARK_PATH_LEN];
    marks_file_path(file, sizeof(file));
    FILE *f = fopen(file, "w");
    if (!f) { perror("mark: cannot write bookmarks file"); return 0; }
    for (int i = 0; i < count; i++)
        fprintf(f, "%s\t%s\n", names[i], paths[i]);
    fclose(f);
    return 1;
}

void handle_mark(char *args, int pipeo) {
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
        if (rfd < 0) { perror("failed to open/create redirected file\n"); goto restore; }
        dup2(rfd, STDOUT_FILENO);
        close(rfd);
    } else if (double_output_redirect && output_file != NULL) {
        int rfd = open(output_file, O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (rfd < 0) { perror("failed to open/create redirected file\n"); goto restore; }
        dup2(rfd, STDOUT_FILENO);
        close(rfd);
    }

    static char names[MARK_MAX][MARK_NAME_LEN];
    static char paths[MARK_MAX][MARK_PATH_LEN];
    int count = load_marks(names, paths);

    if (i == 0) {
        printf("mark: usage\n");
        printf("  mark <name>      bookmark the current directory\n");
        printf("  mark -g <name>   go to a bookmarked directory\n");
        printf("  mark -d <name>   delete a bookmark\n");
        printf("  mark -l          list bookmarks\n");
    }
    else if (strcmp(listArgs[0], "-l") == 0) {
        if (count == 0) {
            printf("mark: no bookmarks saved yet.\n");
        } else {
            printf("%sSaved bookmarks (vidvathamaiiith)%s\n", COLOR_BLUE, COLOR_RESET);
            for (int k = 0; k < count; k++)
                printf("  %s%-16s%s -> %s\n", COLOR_GREEN, names[k], COLOR_RESET, paths[k]);
        }
    }
    else if (strcmp(listArgs[0], "-g") == 0) {
        if (i < 2) { printf("mark: -g requires a bookmark name.\n"); error = 1; goto restore; }
        int found = -1;
        for (int k = 0; k < count; k++)
            if (strcmp(names[k], listArgs[1]) == 0) { found = k; break; }
        if (found < 0) { printf("mark: no bookmark named '%s'.\n", listArgs[1]); error = 1; goto restore; }
        if (chdir(paths[found]) == 0) {
            if (prevDir) free(prevDir);
            prevDir = strdup(currentDir);
            if (currentDir) free(currentDir);
            currentDir = strdup(paths[found]);
            printf("%s\n", paths[found]);
        } else {
            perror("mark: cannot change directory");
            error = 1;
        }
    }
    else if (strcmp(listArgs[0], "-d") == 0) {
        if (i < 2) { printf("mark: -d requires a bookmark name.\n"); error = 1; goto restore; }
        int found = -1;
        for (int k = 0; k < count; k++)
            if (strcmp(names[k], listArgs[1]) == 0) { found = k; break; }
        if (found < 0) { printf("mark: no bookmark named '%s'.\n", listArgs[1]); error = 1; goto restore; }
        for (int k = found; k < count - 1; k++) {
            strcpy(names[k], names[k + 1]);
            strcpy(paths[k], paths[k + 1]);
        }
        count--;
        if (save_marks(names, paths, count))
            printf("mark: deleted bookmark '%s'.\n", listArgs[1]);
    }
    else {
        /* Add / overwrite: `mark <name>` bookmarks the current directory. */
        if (strlen(listArgs[0]) >= MARK_NAME_LEN) { printf("mark: name too long.\n"); error = 1; goto restore; }
        int found = -1;
        for (int k = 0; k < count; k++)
            if (strcmp(names[k], listArgs[0]) == 0) { found = k; break; }
        if (found < 0) {
            if (count >= MARK_MAX) { printf("mark: bookmark limit reached.\n"); error = 1; goto restore; }
            found = count++;
            strncpy(names[found], listArgs[0], MARK_NAME_LEN - 1);
            names[found][MARK_NAME_LEN - 1] = '\0';
        }
        strncpy(paths[found], currentDir ? currentDir : ".", MARK_PATH_LEN - 1);
        paths[found][MARK_PATH_LEN - 1] = '\0';
        if (save_marks(names, paths, count))
            printf("mark: '%s' -> %s\n", names[found], paths[found]);
    }

restore:
    fflush(stdout);
    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);
    for (int j = 0; j < 10; j++)
        if (listArgs[j]) free(listArgs[j]);
    if (output_file) free(output_file);
}
