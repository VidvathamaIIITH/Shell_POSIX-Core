/* ============================================================================
 *  Shell_POSIX-Core
 *  Author  : vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *  Unauthorized copying or false claim of authorship is prohibited.
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#define MAX_PATHS 50
#define MAX_PATH_LENGTH 256

#define HASHMAP_SIZE 128   // Size of the hashmap
#define CACHE_CAPACITY 10  // LRU cache capacity

// Structure to store Storage Server information
typedef struct {
    char ip[INET_ADDRSTRLEN];
    int nm_port;
    int port;
    int active;
    char accessible_paths[MAX_PATHS][MAX_PATH_LENGTH]; // Array to store accessible paths
    int path_count;
} StorageServer;

// Structure to store file metadata information
typedef struct {
    char filePath[256];
    StorageServer* server;
} FileMetadata;

// Node for the linked list in hashmap
typedef struct Node {
    FileMetadata data;
    struct Node* next;
} Node;

// Hashmap for path lookups
Node* hashmap[HASHMAP_SIZE];

// Node for LRU cache
typedef struct LRUNode {
    char filePath[256];
    StorageServer* server;
    struct LRUNode* prev;
    struct LRUNode* next;
} LRUNode;

// LRU Cache
typedef struct {
    int size;
    LRUNode* head;  // Most recently used
    LRUNode* tail;  // Least recently used
    Node* cacheMap[HASHMAP_SIZE]; // Quick access to cache nodes
} LRUCache;

LRUCache* lruCache;

// Hash function for file paths
unsigned int hash(const char* filePath) {
    unsigned int hash = 0;
    while (*filePath) {
        hash = (hash * 31) + (*filePath++);
    }
    return hash % HASHMAP_SIZE;
}

// Initialize the hashmap
void initializeHashmap() {
    for (int i = 0; i < HASHMAP_SIZE; i++) {
        hashmap[i] = NULL;
    }
}

// Insert into the hashmap
void hashmapInsert(const char* filePath, StorageServer* server) {
    unsigned int index = hash(filePath);
    Node* newNode = (Node*)malloc(sizeof(Node));
    strcpy(newNode->data.filePath, filePath);
    newNode->data.server = server;
    newNode->next = hashmap[index];
    hashmap[index] = newNode;
}

// Search the hashmap
StorageServer* hashmapSearch(const char* filePath) {
    unsigned int index = hash(filePath);
    Node* current = hashmap[index];
    while (current) {
        if (strcmp(current->data.filePath, filePath) == 0) {
            return current->data.server;
        }
        current = current->next;
    }
    return NULL; // Not found
}

// Initialize the LRU cache
void initializeLRUCache() {
    lruCache = (LRUCache*)malloc(sizeof(LRUCache));
    lruCache->size = 0;
    lruCache->head = NULL;
    lruCache->tail = NULL;
    for (int i = 0; i < HASHMAP_SIZE; i++) {
        lruCache->cacheMap[i] = NULL;
    }
}

// Move a cache node to the head (most recently used)
void moveToHead(LRUNode* node) {
    if (node == lruCache->head) return;

    // Remove node from its current position
    if (node->prev) node->prev->next = node->next;
    if (node->next) node->next->prev = node->prev;
    if (node == lruCache->tail) lruCache->tail = node->prev;

    // Move node to the head
    node->next = lruCache->head;
    node->prev = NULL;
    if (lruCache->head) lruCache->head->prev = node;
    lruCache->head = node;

    if (!lruCache->tail) lruCache->tail = node; // If tail is NULL, set it
}

// Add a new node to the LRU cache
void addToCache(const char* filePath, StorageServer* server) {
    unsigned int index = hash(filePath);
    LRUNode* newNode = (LRUNode*)malloc(sizeof(LRUNode));
    strcpy(newNode->filePath, filePath);
    newNode->server = server;
    newNode->prev = NULL;
    newNode->next = lruCache->head;

    if (lruCache->head) lruCache->head->prev = newNode;
    lruCache->head = newNode;

    if (!lruCache->tail) lruCache->tail = newNode;

    lruCache->cacheMap[index] = newNode;
    lruCache->size++;

    // If cache exceeds capacity, remove the least recently used node
    if (lruCache->size > CACHE_CAPACITY) {
        LRUNode* lru = lruCache->tail;
        if (lru->prev) lru->prev->next = NULL;
        lruCache->tail = lru->prev;

        unsigned int lruIndex = hash(lru->filePath);
        lruCache->cacheMap[lruIndex] = NULL;
        free(lru);
        lruCache->size--;
    }
}

// Search the LRU cache
StorageServer* cacheSearch(const char* filePath) {
    unsigned int index = hash(filePath);
    LRUNode* node = lruCache->cacheMap[index];

    // If found, move to head and return
    if (node && strcmp(node->filePath, filePath) == 0) {
        moveToHead(node);
        return node->server;
    }
    return NULL; // Not found in cache
}

// Combined search function with caching
StorageServer* searchWithCache(const char* filePath) {
    // First, check the cache
    StorageServer* server = cacheSearch(filePath);
    if (server) {
        printf("Cache hit for %s\n", filePath);
        return server;
    }

    // If not in cache, check the hashmap
    server = hashmapSearch(filePath);
    if (server) {
        printf("Cache miss for %s. Adding to cache.\n", filePath);
        addToCache(filePath, server);
    } else {
        printf("File not found: %s\n", filePath);
    }
    return server;
}

// Delete from hashmap
void hashmapDelete(const char* filePath) {
    unsigned int index = hash(filePath);
    Node* current = hashmap[index];
    Node* prev = NULL;

    while (current) {
        if (strcmp(current->data.filePath, filePath) == 0) {
            // Found the node to delete
            if (prev) {
                prev->next = current->next;
            } else {
                hashmap[index] = current->next; // Update head
            }
            free(current);
            printf("Deleted %s from hashmap.\n", filePath);
            return;
        }
        prev = current;
        current = current->next;
    }
    printf("File path %s not found in hashmap.\n", filePath);
}

// Delete from LRU cache
void cacheDelete(const char* filePath) {
    unsigned int index = hash(filePath);
    LRUNode* node = lruCache->cacheMap[index];

    if (node && strcmp(node->filePath, filePath) == 0) {
        // Remove node from the doubly linked list
        if (node->prev) {
            node->prev->next = node->next;
        } else {
            lruCache->head = node->next; // Update head
        }
        if (node->next) {
            node->next->prev = node->prev;
        } else {
            lruCache->tail = node->prev; // Update tail
        }

        // Remove from cache map and free memory
        lruCache->cacheMap[index] = NULL;
        free(node);
        lruCache->size--;
        printf("Deleted %s from LRU cache.\n", filePath);
    } else {
        printf("File path %s not found in cache.\n", filePath);
    }
}

// Combined delete function
void deletePath(const char* filePath) {
    // Delete from cache
    cacheDelete(filePath);

    // Delete from hashmap
    hashmapDelete(filePath);
}

char * printAllPaths() { 
    char buffer[(MAX_PATH_LENGTH+1)];
    char *all = malloc((MAX_PATH_LENGTH+1)*MAX_PATHS);
    printf("Printing all paths in the hashmap:\n");
    for (int i = 0; i < HASHMAP_SIZE; i++) {
        Node* current = hashmap[i];
        while (current) {
            snprintf(buffer, sizeof(buffer), "%s\n", current->data.filePath);
            strcat(all, buffer);
            current = current->next;
        }
    }
    //printf("%s \n Finished printing all paths.\n", all);
    return all;
}
