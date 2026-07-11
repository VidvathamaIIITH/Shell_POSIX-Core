#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <semaphore.h>
#include <fcntl.h>
#include <unistd.h>
#include <regex.h>
#include <time.h>
#include <errno.h>
#include <assert.h>
#include <signal.h>

#define MAX_FILENAME 128
#define TIMESTAMP_LEN 20
#define THRESHOLD 42
#define CLEANUP_ERROR -1
#define SUCCESS 0
#define MAX_NAME_LENGTH 128
#define MIN_THREAD_SIZE 100  // Minimum size to trigger threading in merge sort
#define NUM_THREADS 4
#define TIMESTAMP_BUCKETS 1000
#define MAX_ID 100000  // Adjust based on expected maximum ID value

// Global variables
pthread_barrier_t count_barrier;

// Structure to hold file information
typedef struct {
    char name[MAX_FILENAME];
    int id;
    char timestamp[TIMESTAMP_LEN];
} FileEntry;

// Structure for performance metrics with atomic access
typedef struct {
    double execution_time;
    size_t memory_used;
    int file_count;
    char algorithm[30];
    pthread_mutex_t metrics_mutex;
} PerformanceMetrics;

// Encapsulated file collection with synchronization
typedef struct {
    FileEntry *entries;
    int count;
    sem_t *semaphore;
    char *semaphore_name;
} FileCollection;

// Structure to hold arguments for threads in merge sort
typedef struct {
    FileCollection *collection;
    int left;
    int right;
    const char *sort_column;
    PerformanceMetrics *metrics;
} SortArgs;

//Structure to hold arguements for threads in count sort
typedef struct {
    FileCollection *collection;
    int start_idx;
    int end_idx;
    int *count_arr;
    const char *sort_column;
    pthread_mutex_t *mutex;
    int max_val;  // To track maximum value for dynamic sizing
} CountSortThreadArgs;

// Function prototypes
static void cleanup_handler(void *arg);
static void signal_handler(int signum);
static int initialize_metrics(PerformanceMetrics *metrics);
static void cleanup_metrics(PerformanceMetrics *metrics);
static int initialize_collection(FileCollection *collection, int count, const char *sem_name);
static void cleanup_collection(FileCollection *collection);
static int lazy_sort(FileCollection *collection, const char *sort_column, PerformanceMetrics *metrics);
static int count_sort(FileCollection *collection, const char *sort_column, PerformanceMetrics *metrics);
static size_t get_memory_usage();
static void merge_sort(FileCollection *collection, int left, int right, const char *sort_column, PerformanceMetrics *metrics);
static void merge(FileEntry *arr, int left, int mid, int right, const char *sort_column);

// Signal handler for safe shutdown
static void signal_handler(int signum) {
    printf("Caught signal %d, cleaning up...\n", signum);
    exit(signum);
}

// Cleanup handler for pthreads
static void cleanup_handler(void *arg) {
    FileCollection *collection = (FileCollection *)arg;
    cleanup_collection(collection);
}

static int calculate_timestamp_hash(struct tm *tm_time) {
    return (tm_time->tm_year * 12 + tm_time->tm_mon) * 31 + 
           tm_time->tm_mday * 24 + tm_time->tm_hour * 60 + 
           tm_time->tm_min * 60 + tm_time->tm_sec;
}

static void cleanup_resources(FileCollection *collection, pthread_mutex_t *mutex) {
    if (mutex) {
        pthread_mutex_destroy(mutex);
    }
    pthread_barrier_destroy(&count_barrier);
}

// Optimized thread-safe memory usage calculation
static size_t get_memory_usage() {
    static long page_size = 0;
    if (page_size == 0) page_size = getpagesize();  // Cache page size

    FILE* status = fopen("/proc/self/statm", "r");
    if (status == NULL) return 0;
    long pages = 0;
    if (fscanf(status, "%ld", &pages) != 1) {
        fclose(status);
        return 0;
    }
    fclose(status);
    return pages * page_size;
}

// Parse ISO 8601 Timestamp with error checking
static int parse_iso8601(const char *timestamp, struct tm *tm) {
    if (!timestamp || !tm) return 0;
    memset(tm, 0, sizeof(struct tm));
    if (sscanf(timestamp, "%4d-%2d-%2dT%2d:%2d:%2d", 
               &tm->tm_year, &tm->tm_mon, &tm->tm_mday, 
               &tm->tm_hour, &tm->tm_min, &tm->tm_sec) != 6) {
        return 0;
    }
    tm->tm_year -= 1900;
    tm->tm_mon -= 1;
    return 1;
}

// Compare function for timestamps
static int compare_timestamps(const char *ts1, const char *ts2) {
    struct tm tm1, tm2;
    if (!parse_iso8601(ts1, &tm1) || !parse_iso8601(ts2, &tm2)) {
        return 0;
    }
    time_t t1 = mktime(&tm1);
    time_t t2 = mktime(&tm2);
    return (t1 < t2) ? -1 : (t1 > t2) ? 1 : 0;
}

// Helper function to get timestamp bucket
static int get_timestamp_bucket(const char *timestamp) {
    struct tm tm_time;
    if (!parse_iso8601(timestamp, &tm_time)) {
        return 0;
    }
    
    // Convert timestamp to a single comparable value
    // Using year, month, day, hour, minute, second as weighted components
    int bucket = (tm_time.tm_year + 1900) * 12 * 31 * 24 * 60 * 60 +
                 (tm_time.tm_mon + 1) * 31 * 24 * 60 * 60 +
                 tm_time.tm_mday * 24 * 60 * 60 +
                 tm_time.tm_hour * 60 * 60 +
                 tm_time.tm_min * 60 +
                 tm_time.tm_sec;
    
    return bucket;
}

static void build_sorted_array_by_id(FileCollection *collection, FileEntry *sorted_files, int *count_arr) {
    // Build cumulative frequency
    for (int i = 1; i < MAX_ID + 1; i++) {
        count_arr[i] += count_arr[i - 1];
    }
    
    // Build sorted array
    for (int i = collection->count - 1; i >= 0; i--) {
        int index = --count_arr[collection->entries[i].id];
        sorted_files[index] = collection->entries[i];
    }
}

static void build_sorted_array_by_name(FileCollection *collection, FileEntry *sorted_files, int *count_arr) {
    // Build cumulative frequency
    for (int i = 1; i < 256; i++) {
        count_arr[i] += count_arr[i - 1];
    }
    
    // Build sorted array
    for (int i = collection->count - 1; i >= 0; i--) {
        int index = --count_arr[(unsigned char)collection->entries[i].name[0]];
        sorted_files[index] = collection->entries[i];
    }
}

static void build_sorted_array_by_timestamp(FileCollection *collection, FileEntry *sorted_files, int *count_arr) {
    // Create temporary array to store entries with their timestamp values
    typedef struct {
        FileEntry entry;
        int timestamp_val;
    } TimestampEntry;
    
    TimestampEntry *temp = malloc(collection->count * sizeof(TimestampEntry));
    
    // Convert all timestamps to comparable values
    for (int i = 0; i < collection->count; i++) {
        temp[i].entry = collection->entries[i];
        temp[i].timestamp_val = get_timestamp_bucket(collection->entries[i].timestamp);
    }
    
    // Sort based on timestamp values
    for (int i = 0; i < collection->count - 1; i++) {
        for (int j = 0; j < collection->count - i - 1; j++) {
            if (temp[j].timestamp_val > temp[j + 1].timestamp_val) {
                TimestampEntry t = temp[j];
                temp[j] = temp[j + 1];
                temp[j + 1] = t;
            }
        }
    }
    
    // Copy sorted entries back
    for (int i = 0; i < collection->count; i++) {
        sorted_files[i] = temp[i].entry;
    }
    
    free(temp);
}


// Modified thread function with better error handling
static void* count_sort_thread(void *arg) {
    CountSortThreadArgs *args = (CountSortThreadArgs *)arg;
    
    if (!args || !args->collection || !args->count_arr) {
        return NULL;
    }

    if (strcmp(args->sort_column, "ID") == 0) {
        for (int i = args->start_idx; i < args->end_idx; i++) {
            if (i < args->collection->count) {  // Bounds checking
                int id = args->collection->entries[i].id;
                if (id >= 0 && id <= args->max_val) {  // Value range checking
                    pthread_mutex_lock(args->mutex);
                    args->count_arr[id]++;
                    pthread_mutex_unlock(args->mutex);
                }
            }
        }
    }
    else if (strcmp(args->sort_column, "Name") == 0) {
        for (int i = args->start_idx; i < args->end_idx; i++) {
            if (i < args->collection->count) {  // Bounds checking
                unsigned char first_char = (unsigned char)args->collection->entries[i].name[0];
                pthread_mutex_lock(args->mutex);
                args->count_arr[first_char]++;
                pthread_mutex_unlock(args->mutex);
            }
        }
    }
    else {  // Timestamp
        for (int i = args->start_idx; i < args->end_idx; i++) {
            if (i < args->collection->count) {  // Bounds checking
                int bucket = get_timestamp_bucket(args->collection->entries[i].timestamp);
                if (bucket >= 0 && bucket < TIMESTAMP_BUCKETS) {
                    pthread_mutex_lock(args->mutex);
                    args->count_arr[bucket]++;
                    pthread_mutex_unlock(args->mutex);
                }
            }
        }
    }
    
    return NULL;
}

static int count_sort(FileCollection *collection, const char *sort_column, PerformanceMetrics *metrics) {
    if (!collection || !sort_column || !metrics) return CLEANUP_ERROR;

    // Record metrics
    pthread_mutex_lock(&metrics->metrics_mutex);
    strcpy(metrics->algorithm, "Distributed Count Sort");
    clock_t start_time = clock();
    pthread_mutex_unlock(&metrics->metrics_mutex);

    // Allocate memory for sorted array with error checking
    FileEntry *sorted_files = calloc(collection->count, sizeof(FileEntry));
    if (!sorted_files) {
        fprintf(stderr, "Memory allocation failed for sorted_files\n");
        return CLEANUP_ERROR;
    }

    // Determine array size and initialize count array
    int array_size;
    if (strcmp(sort_column, "ID") == 0) {
        array_size = MAX_ID + 1;
    } else if (strcmp(sort_column, "Name") == 0) {
        array_size = 256;  // ASCII range
    } else { // Timestamp
        array_size = TIMESTAMP_BUCKETS;
    }

    // Allocate and initialize count array with error checking
    int *count_arr = calloc(array_size, sizeof(int));
    if (!count_arr) {
        fprintf(stderr, "Memory allocation failed for count_arr\n");
        free(sorted_files);
        return CLEANUP_ERROR;
    }

    // Initialize mutex and barrier with error checking
    pthread_mutex_t count_mutex;
    if (pthread_mutex_init(&count_mutex, NULL) != 0) {
        fprintf(stderr, "Mutex initialization failed\n");
        free(sorted_files);
        free(count_arr);
        return CLEANUP_ERROR;
    }

    // Calculate optimal number of threads based on data size
    int num_threads = (NUM_THREADS < collection->count / 10 + 1)? NUM_THREADS : collection->count / 10 + 1;
    pthread_t *threads = calloc(num_threads, sizeof(pthread_t));
    CountSortThreadArgs *thread_args = calloc(num_threads, sizeof(CountSortThreadArgs));

    if (!threads || !thread_args) {
        fprintf(stderr, "Thread allocation failed\n");
        free(sorted_files);
        free(count_arr);
        pthread_mutex_destroy(&count_mutex);
        free(threads);
        free(thread_args);
        return CLEANUP_ERROR;
    }

    // Calculate chunk size and distribute work
    int chunk_size = collection->count / num_threads;
    int remainder = collection->count % num_threads;
    int current_start = 0;

    // Create threads with proper error handling
    for (int i = 0; i < num_threads; i++) {
        thread_args[i].collection = collection;
        thread_args[i].start_idx = current_start;
        thread_args[i].end_idx = current_start + chunk_size + (i < remainder ? 1 : 0);
        thread_args[i].count_arr = count_arr;
        thread_args[i].sort_column = sort_column;
        thread_args[i].mutex = &count_mutex;
        thread_args[i].max_val = array_size - 1;

        current_start = thread_args[i].end_idx;

        if (pthread_create(&threads[i], NULL, count_sort_thread, &thread_args[i]) != 0) {
            fprintf(stderr, "Thread creation failed\n");
            // Cleanup already created threads
            for (int j = 0; j < i; j++) {
                pthread_cancel(threads[j]);
                pthread_join(threads[j], NULL);
            }
            free(sorted_files);
            free(count_arr);
            pthread_mutex_destroy(&count_mutex);
            free(threads);
            free(thread_args);
            return CLEANUP_ERROR;
        }
    }

    // Wait for all threads to complete
    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
    }

    // Build final sorted array with error checking
    if (strcmp(sort_column, "ID") == 0) {
        build_sorted_array_by_id(collection, sorted_files, count_arr);
    } else if (strcmp(sort_column, "Name") == 0) {
        build_sorted_array_by_name(collection, sorted_files, count_arr);
    } else {
        build_sorted_array_by_timestamp(collection, sorted_files, count_arr);
    }

    // Copy results back with error checking
    if (collection->entries) {
        memcpy(collection->entries, sorted_files, collection->count * sizeof(FileEntry));
    }

    // Update metrics
    pthread_mutex_lock(&metrics->metrics_mutex);
    metrics->execution_time = (double)(clock() - start_time) / CLOCKS_PER_SEC;
    metrics->memory_used = get_memory_usage();
    pthread_mutex_unlock(&metrics->metrics_mutex);

    // Cleanup
    pthread_mutex_destroy(&count_mutex);
    free(count_arr);
    free(sorted_files);
    free(threads);
    free(thread_args);

    return SUCCESS;
}

// Thread function for merge sort
void *threaded_merge_sort(void *args) {
    SortArgs *sort_args = (SortArgs *)args;
    merge_sort(sort_args->collection, sort_args->left, sort_args->right, 
              sort_args->sort_column, sort_args->metrics);
    return NULL;
}

// Optimized merge sort with conditional threading
static void merge_sort(FileCollection *collection, int left, int right, 
                      const char *sort_column, PerformanceMetrics *metrics) {
    if (left < right) {
        int mid = left + (right - left) / 2;

        if (right - left > MIN_THREAD_SIZE) {
            pthread_t left_thread, right_thread;
            SortArgs left_args = {collection, left, mid, sort_column, metrics};
            SortArgs right_args = {collection, mid + 1, right, sort_column, metrics};

            pthread_create(&left_thread, NULL, threaded_merge_sort, &left_args);
            pthread_create(&right_thread, NULL, threaded_merge_sort, &right_args);

            pthread_join(left_thread, NULL);
            pthread_join(right_thread, NULL);
        } else {
            merge_sort(collection, left, mid, sort_column, metrics);
            merge_sort(collection, mid + 1, right, sort_column, metrics);
        }

        merge(collection->entries, left, mid, right, sort_column);
    }
}

// Enhanced merge function with support for all columns
static void merge(FileEntry *arr, int left, int mid, int right, const char *sort_column) {
    int n1 = mid - left + 1;
    int n2 = right - mid;

    FileEntry *L = malloc(n1 * sizeof(FileEntry));
    FileEntry *R = malloc(n2 * sizeof(FileEntry));

    for (int i = 0; i < n1; i++) L[i] = arr[left + i];
    for (int i = 0; i < n2; i++) R[i] = arr[mid + 1 + i];

    int i = 0, j = 0, k = left;

    while (i < n1 && j < n2) {
        int cmp = 0;
        if (strcmp(sort_column, "ID") == 0) cmp = L[i].id - R[j].id;
        else if (strcmp(sort_column, "Name") == 0) cmp = strcmp(L[i].name, R[j].name);
        else if (strcmp(sort_column, "Timestamp") == 0) cmp = compare_timestamps(L[i].timestamp, R[j].timestamp);

        if (cmp <= 0) arr[k++] = L[i++];
        else arr[k++] = R[j++];
    }

    while (i < n1) arr[k++] = L[i++];
    while (j < n2) arr[k++] = R[j++];

    free(L);
    free(R);
}

// Main sorting function with error handling
static int lazy_sort(FileCollection *collection, const char *sort_column, PerformanceMetrics *metrics) {
    if (!collection || !sort_column || !metrics) return CLEANUP_ERROR;

    pthread_mutex_lock(&metrics->metrics_mutex);
    clock_t start_time = clock();
    size_t initial_memory = get_memory_usage();
    pthread_mutex_unlock(&metrics->metrics_mutex);

    int result;
    if (collection->count < THRESHOLD) {
        result = count_sort(collection, sort_column, metrics);
    } else {
        pthread_mutex_lock(&metrics->metrics_mutex);
        strcpy(metrics->algorithm, "Concurrent Merge Sort");
        pthread_mutex_unlock(&metrics->metrics_mutex);
        merge_sort(collection, 0, collection->count - 1, sort_column, metrics);
        result = SUCCESS;
    }

    pthread_mutex_lock(&metrics->metrics_mutex);
    metrics->execution_time = (double)(clock() - start_time) / CLOCKS_PER_SEC;
    metrics->memory_used = get_memory_usage() - initial_memory;
    metrics->file_count = collection->count;
    pthread_mutex_unlock(&metrics->metrics_mutex);

    return result;
}

// Initialize performance metrics
static int initialize_metrics(PerformanceMetrics *metrics) {
    if (!metrics) return CLEANUP_ERROR;
    memset(metrics, 0, sizeof(PerformanceMetrics));
    if (pthread_mutex_init(&metrics->metrics_mutex, NULL) != 0) {
        return CLEANUP_ERROR;
    }
    return SUCCESS;
}

// Cleanup performance metrics
static void cleanup_metrics(PerformanceMetrics *metrics) {
    if (!metrics) return;
    pthread_mutex_destroy(&metrics->metrics_mutex);
}

// Initialize file collection with semaphore
static int initialize_collection(FileCollection *collection, int count, const char *sem_name) {
    if (!collection || count <= 0 || !sem_name) return CLEANUP_ERROR;
    collection->count = count;
    collection->entries = malloc(count * sizeof(FileEntry));
    if (!collection->entries) return CLEANUP_ERROR;
    collection->semaphore = sem_open(sem_name, O_CREAT, 0644, 1);
    if (collection->semaphore == SEM_FAILED) {
        free(collection->entries);
        return CLEANUP_ERROR;
    }
    collection->semaphore_name = strdup(sem_name);
    return SUCCESS;
}

// Cleanup file collection
static void cleanup_collection(FileCollection *collection) {
    if (!collection) return;
    if (collection->entries) free(collection->entries);
    if (collection->semaphore) {
        sem_close(collection->semaphore);
        sem_unlink(collection->semaphore_name);
    }
    if (collection->semaphore_name) free(collection->semaphore_name);
}

int main() {
    // Set up signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    int file_count;
    if (scanf("%d", &file_count) != 1 || file_count <= 0) {
        fprintf(stderr, "Invalid file count\n");
        return EXIT_FAILURE;
    }

    FileCollection collection;
    PerformanceMetrics metrics;

    if (initialize_collection(&collection, file_count, "/file_semaphore") != SUCCESS) {
        fprintf(stderr, "Failed to initialize file collection\n");
        return EXIT_FAILURE;
    }

    if (initialize_metrics(&metrics) != SUCCESS) {
        cleanup_collection(&collection);
        fprintf(stderr, "Failed to initialize metrics\n");
        return EXIT_FAILURE;
    }

    // Push cleanup handler
    pthread_cleanup_push(cleanup_handler, &collection);

    // Read file entries
    for (int i = 0; i < file_count; i++) {
        if (scanf("%s %d %s", collection.entries[i].name, 
                 &collection.entries[i].id, 
                 collection.entries[i].timestamp) != 3) {
            fprintf(stderr, "Invalid input for file entry %d\n", i + 1);
            cleanup_collection(&collection);
            cleanup_metrics(&metrics);
            return EXIT_FAILURE;
        }
    }

    char sort_column[20];
    scanf("%s", sort_column);

    printf("Sorting parameter: %s\n", sort_column);

    // Perform the sort
    if (lazy_sort(&collection, sort_column, &metrics) != SUCCESS) {
        fprintf(stderr, "Sorting failed\n");
        cleanup_collection(&collection);
        cleanup_metrics(&metrics);
        return EXIT_FAILURE;
    }

    // Output sorted entries
    printf("Sorted File Entries:\n");
    for (int i = 0; i < collection.count; i++) {
        printf("%s %d %s\n", collection.entries[i].name, collection.entries[i].id, collection.entries[i].timestamp);
    }

    // Display performance metrics
    pthread_mutex_lock(&metrics.metrics_mutex);
    printf("\nPerformance Metrics:\n");
    printf("Algorithm Used: %s\n", metrics.algorithm);
    printf("Execution Time: %.6f seconds\n", metrics.execution_time);
    printf("Memory Used: %zu bytes\n", metrics.memory_used);
    printf("File Count: %d\n", metrics.file_count);
    pthread_mutex_unlock(&metrics.metrics_mutex);

    // Cleanup resources
    pthread_cleanup_pop(1); // This calls cleanup_collection on FileCollection
    cleanup_metrics(&metrics);

    return EXIT_SUCCESS;
}