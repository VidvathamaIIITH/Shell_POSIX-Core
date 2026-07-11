#include "../include/shell.h"

void initQueue(Queue *q) {
    q->front = 0;
    q->rear = -1;
    q->size = 0;
}

int isFull(Queue *q) {
    return q->size == MAX_SIZE;
}

int isEmpty(Queue *q) {
    return q->size == 0;
}

int dequeue(Queue *q, char *str) {
    if (isEmpty(q)) {
        printf("Queue is empty. Cannot dequeue\n");
        return 0; // Failed to dequeue
    }
    strncpy(str, q->items[q->front], STRING_LENGTH);  // Copy the string from the queue
    q->front = (q->front + 1) % MAX_SIZE;  // Circular increment
    q->size--;
    return 1; // Successfully dequeued
}

int enqueue(Queue *q, const char *str) {
    if (isFull(q)) {
        //printf("Queue is full. Dequeuing the front element before enqueuing '%s'\n", str);
        // Automatically dequeue the front element
        char temp[STRING_LENGTH];
        dequeue(q, temp);
    }
    q->rear = (q->rear + 1) % MAX_SIZE;  // Circular increment
    strncpy(q->items[q->rear], str, STRING_LENGTH - 1); // Add the string to the queue
    q->items[q->rear][STRING_LENGTH - 1] = '\0'; // Ensure null-termination
    q->size++;
    return 1; // Successfully enqueued
}

int peek(Queue *q, char *str) {
    if (isEmpty(q)) {
        printf("Queue is empty. Cannot peek\n");
        return 0; // Failed to peek
    }
    strncpy(str, q->items[q->front], STRING_LENGTH);
    return 1; // Successfully peeked
}

void displayQueue(Queue *q) {
    if (isEmpty(q)) {
        return;
    }
    for (int i = 0; i < q->size; i++) {
        int index = (q->front + i) % MAX_SIZE;
        printf("%s\n", q->items[index]);
    }
}

