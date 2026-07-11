#include "../include/shell.h"



pid_t shellPid;
int error = 0;


#define MAX_SIZE 15
#define STRING_LENGTH 1024

#define BUFFER_SIZE 4096
#define BUFFER_SIZE_RESPONSE 100000
#define PORT 80

#define RECURSION_DEPTH 10000
int recurse = 0;

typedef struct {
    char items[MAX_SIZE][STRING_LENGTH];  // Array to store strings
    int front;                            // Index of the front element
    int rear;                             // Index of the rear element
    int size;                             // Current size of the queue
} Queue;

// Function to initialize the queue
