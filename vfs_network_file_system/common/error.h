// General Errors
#define ERR_OK 0                   // Operation successful
#define ERR_INVALID_REQUEST 1      // Malformed or invalid request
#define ERR_SERVER_UNAVAILABLE 2   // Server is unreachable

// File-Related Errors
#define ERR_FILE_NOT_FOUND 100     // File does not exist
#define ERR_FILE_ALREADY_EXISTS 101 // File already exists (e.g., during create)
#define ERR_FILE_IN_USE 102        // File is currently locked for writing
#define ERR_PERMISSION_DENIED 103  // Insufficient permissions to access the file
#define ERR_DISK_FULL 104          // Not enough space to create or write to file
#define ERR_EMPTY_DIR 105          // If a particular directory is empty

// Communication Errors
#define ERR_CONNECTION_LOST 200    // Connection with the server dropped
#define ERR_PACKET_LOST 201        // when some data could not be sent
#define ERR_TIMEOUT 202            // Request timed out
#define ERR_INTERNAL_SERVER 203    // Internal server error

// Storage Server-Specific Errors
#define ERR_SS_UNREGISTERED 300    // Storage server not registered with Naming Server
#define ERR_SS_UNAVAILABLE 301     // Storage server is down or unreachable

void send_error(int sock, int code, const char *message) {
    char response[100];
    snprintf(response, sizeof(response), "ERROR %d: %s\n", code, message);
    write(sock, response, strlen(response));
}