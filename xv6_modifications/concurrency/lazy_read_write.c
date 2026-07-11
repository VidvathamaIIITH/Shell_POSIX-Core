#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <string.h>
#include <sys/time.h>

#define YELLOW "\033[1;33m"
#define PINK "\033[1;35m"
#define WHITE "\033[1;37m"
#define GREEN "\033[1;32m"
#define RED "\033[1;31m"
#define RESET "\033[0m"

typedef struct {
    int user_id;
    int file_id;
    char operation;
    double request_time;
} Request;

typedef struct {
    int id;
    int exists;
    int read_count;
    int is_writing;
    pthread_mutex_t lock;
    sem_t access_limit;
    sem_t write_limit;
    pthread_mutex_t delete_lock;
    pthread_cond_t delete;
    //pthread_mutex_t wl;
} File;

File *files;
int n_files, max_concurrency, max_wait_time;
int read_time, write_time, delete_time;
pthread_mutex_t print_lock = PTHREAD_MUTEX_INITIALIZER;
double initial_time;

// Get current time in seconds with microsecond precision
double get_initial_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (tv.tv_sec + tv.tv_usec / 1e6);
}

double get_current_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (tv.tv_sec + tv.tv_usec / 1e6) - initial_time;
}

void print_event(const char *color, const char *event) {
    pthread_mutex_lock(&print_lock);
    printf("%s%s%s\n", color, event, RESET);
    pthread_mutex_unlock(&print_lock);
}

void *process_request(void *arg) {
    Request *req = (Request *) arg;
    File *file = &files[req->file_id - 1];

    double current_time = get_current_time();

    // Wait until request time arrives (relative time)
    if ((current_time - req->request_time) < 0) {
        usleep((req->request_time - current_time) * 1e6);  // Delay until request time
        current_time = get_current_time();
    }

    char event[200];
    snprintf(event, sizeof(event), "User %d has made request for %c on file %d at %0.2lf seconds", 
             req->user_id, req->operation, req->file_id, req->request_time);
    print_event(YELLOW, event);

    // Delay for 1 second before LAZY starts processing
    usleep(1e6);

    current_time = get_current_time();
    double wait_time = current_time - req->request_time;
    // Check if request timed out
    if (wait_time > max_wait_time) {
        snprintf(event, sizeof(event), "User %d canceled the request due to no response at %0.2lf seconds", 
                 req->user_id, current_time);
        print_event(RED, event);
        free(req);
        return NULL;
    }

    // Process based on operation type
    int operation_time = 0;
    if (req->operation == 'R') {  // READ operation
        //sem_wait(&file->delete_lock);
        sem_wait(&file->access_limit);
        pthread_mutex_lock(&file->lock);

        if (!file->exists) {
            snprintf(event, sizeof(event), "LAZY has declined the request of User %d at %0.2lf seconds because an invalid/deleted file was requested.", 
                     req->user_id, current_time);
            print_event(WHITE, event);
            pthread_mutex_unlock(&file->lock);
            sem_post(&file->access_limit);
            //sem_post(&file->delete_lock);
            free(req);
            return NULL;
        }

        wait_time = current_time - req->request_time;
        // Check if request timed out
        if (wait_time > max_wait_time) {
            snprintf(event, sizeof(event), "User %d canceled the request due to no response at %0.2lf seconds", 
                    req->user_id, current_time);
            print_event(RED, event);
            pthread_mutex_unlock(&file->lock);
            sem_post(&file->access_limit);
            //sem_post(&file->delete_lock);
            free(req);
            return NULL;
        }

        snprintf(event, sizeof(event), "LAZY has taken up the request of User %d at %0.2lf seconds", req->user_id, current_time);
        print_event(PINK, event);
        file->read_count++;
        pthread_mutex_unlock(&file->lock);

        operation_time = read_time;
        usleep(operation_time * 1e6);

        pthread_mutex_lock(&file->lock);
        pthread_mutex_lock(&file->delete_lock);
        file->read_count--;
        pthread_cond_signal(&file->delete);
        pthread_mutex_unlock(&file->delete_lock);
        pthread_mutex_unlock(&file->lock);

        current_time = get_current_time();
        snprintf(event, sizeof(event), "The request for User %d was completed at %0.2lf seconds", 
        req->user_id, current_time);
        print_event(GREEN, event);

        sem_post(&file->access_limit);
        //sem_post(&file->delete_lock);

    } else if (req->operation == 'W') {  // WRITE operation
        //sem_wait(&file->delete_lock);
        sem_wait(&file->access_limit);
        sem_wait(&file->write_limit);
        pthread_mutex_lock(&file->lock);
        current_time = get_current_time();
        if (!file->exists) {
            snprintf(event, sizeof(event), "LAZY has declined the request of User %d at %0.2lf seconds because an invalid/deleted file was requested.", 
                     req->user_id, current_time);
            print_event(WHITE, event);
            pthread_mutex_unlock(&file->lock);
            sem_post(&file->write_limit);
            sem_post(&file->access_limit);
            //sem_post(&file->delete_lock);
            free(req);
            return NULL;
        }

        double wait_time = current_time - req->request_time;
        // Check if request timed out
        if (wait_time > max_wait_time) {
            snprintf(event, sizeof(event), "User %d canceled the request due to no response at %0.2lf seconds", 
                    req->user_id, current_time);
            print_event(RED, event);
            pthread_mutex_unlock(&file->lock);
            sem_post(&file->write_limit);
            sem_post(&file->access_limit);
            //sem_post(&file->delete_lock);
            free(req);
            return NULL;
        }

        snprintf(event, sizeof(event), "LAZY has taken up the request of User %d at %0.2lf seconds", req->user_id, current_time);
        print_event(PINK, event);
        file->is_writing = 1;
        pthread_mutex_unlock(&file->lock);

        operation_time = write_time;
        usleep(operation_time * 1e6);

        pthread_mutex_lock(&file->lock);
        pthread_mutex_lock(&file->delete_lock);
        file->is_writing = 0;
        pthread_cond_signal(&file->delete);
        pthread_mutex_unlock(&file->delete_lock);
        pthread_mutex_unlock(&file->lock);

        current_time = get_current_time();
        snprintf(event, sizeof(event), "The request for User %d was completed at %0.2lf seconds", 
        req->user_id, current_time);
        print_event(GREEN, event);

        sem_post(&file->write_limit);
        sem_post(&file->access_limit);
        //sem_post(&file->delete_lock);

    } else if (req->operation == 'D') {  // DELETE operation
        //sem_wait(&file->delete_lock);
        sem_wait(&file->access_limit);
        /*pthread_mutex_lock(&file->wl);
        while (&file->read_count > 0 || &file->is_writing == 1)
            pthread_cond_wait(&file->delete, &file->wl);
        pthread_mutex_unlock(&file->wl);*/
        current_time = get_current_time();
        pthread_mutex_lock(&file->lock);
        if (!file->exists) {
            snprintf(event, sizeof(event), "LAZY has declined the request of User %d at %0.2lf seconds because an invalid/deleted file was requested.", 
                     req->user_id, current_time);
            print_event(WHITE, event);
            pthread_mutex_unlock(&file->lock);
            sem_post(&file->access_limit);
            //sem_post(&file->delete_lock);
            free(req);
            return NULL;
        }
        pthread_mutex_unlock(&file->lock);
        pthread_mutex_lock(&file->delete_lock);
        while (file->read_count > 0 || file->is_writing == 1) {
            printf("caught\n");
            pthread_cond_wait(&file->delete, &file->delete_lock);
        }
        printf("freed\n");
        pthread_mutex_unlock(&file->delete_lock);

        //sleep(0.5);
        pthread_mutex_lock(&file->lock);
        current_time = get_current_time();
        wait_time = current_time - req->request_time;
        // Check if request timed out
        if (wait_time > max_wait_time) {
            snprintf(event, sizeof(event), "User %d canceled the request due to no response at %0.2lf seconds", 
                    req->user_id, current_time);
            print_event(RED, event);
            pthread_mutex_unlock(&file->lock);
            sem_post(&file->access_limit);
            //sem_post(&file->delete_lock);
            free(req);
            return NULL;
        }

        snprintf(event, sizeof(event), "LAZY has taken up the request of User %d at %0.2lf seconds", req->user_id, current_time);
        print_event(PINK, event);
        file->exists = 0;
        pthread_mutex_unlock(&file->lock);

        operation_time = delete_time;
        usleep(operation_time * 1e6);

        current_time = get_current_time();
        snprintf(event, sizeof(event), "The request for User %d was completed at %0.2lf seconds", 
        req->user_id, current_time);
        print_event(GREEN, event);

        sem_post(&file->access_limit);
        //sem_post(&file->delete_lock);
    }
    free(req);
    return NULL;
}

int main() {
    // Input for times
    printf("Enter times for READ, WRITE, and DELETE operations (r w d): ");
    scanf("%d %d %d", &read_time, &write_time, &delete_time);

    printf("Enter number of files, max concurrency per file, and max wait time (n c T): ");
    scanf("%d %d %d", &n_files, &max_concurrency, &max_wait_time);

    files = malloc(n_files * sizeof(File));
    for (int i = 0; i < n_files; i++) {
        files[i].id = i + 1;
        files[i].exists = 1;
        files[i].read_count = 0;
        files[i].is_writing = 0;
        pthread_mutex_init(&files[i].lock, NULL);
        sem_init(&files[i].access_limit, 0, max_concurrency);
        sem_init(&files[i].write_limit, 0, 1);
        //sem_init(&files[i].delete_lock, 0, 1);
        pthread_cond_init(&files[i].delete, NULL);
        pthread_mutex_init(&files[i].delete_lock, NULL);
    }

    Request requests[100];
    int request_count = 0;

    // Read requests
    while (1) {
        int user_id, file_id, request_time;
        char operation[10];

        printf("Enter request (u_i f_i o_i t_i) or STOP to end: ");
        if (scanf("%d %d %s %d", &user_id, &file_id, operation, &request_time) != 4) {
            char end_check[10];
            scanf("%s", end_check);
            if (strcmp(end_check, "STOP") == 0) {
                break;
            }
            printf("Invalid input. Try again.\n");
            continue;
        }

        requests[request_count].user_id = user_id;
        requests[request_count].file_id = file_id;
        requests[request_count].operation = operation[0];
        requests[request_count].request_time = request_time;
        request_count++;
    }

    print_event(PINK, "LAZY has woken up!");

    pthread_t threads[100];
    for (int i = 0; i < request_count; i++) {
        Request *req = malloc(sizeof(Request));
        *req = requests[i];
        // Track initial time when the first request arrives
        if (i == 0)
            initial_time = get_initial_time();
        pthread_create(&threads[i], NULL, process_request, req);
    }

    for (int i = 0; i < request_count; i++) {
        pthread_join(threads[i], NULL);
    }

    for (int i = 0; i < n_files; i++) {
        pthread_mutex_destroy(&files[i].lock);
        pthread_mutex_destroy(&files[i].delete_lock);
        sem_destroy(&files[i].access_limit);
        sem_destroy(&files[i].write_limit);
        pthread_mutex_destroy(&files[i].lock);
        pthread_cond_destroy(&files[i].delete);
    }
    free(files);

    print_event(PINK, "LAZY is done!");

    return 0;
}

