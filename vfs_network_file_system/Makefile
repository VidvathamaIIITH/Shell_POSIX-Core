CC = gcc
CFLAGS = -Wall -Icommon -pthread

all: naming_server/naming_server storage_server/storage_server client/client

naming_server/naming_server: naming_server/naming_server.c
	$(CC) $(CFLAGS) -o $@ $^

storage_server/storage_server: storage_server/storage_server.c
	$(CC) $(CFLAGS) -o $@ $^

client/client: client/client.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f naming_server/naming_server storage_server/storage_server client/client
