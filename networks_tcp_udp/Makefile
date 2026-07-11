CC = gcc
CFLAGS = -Wall

all: src/client src/server

src/client: src/client.c
	$(CC) $(CFLAGS) -o $@ $^

src/server: src/server.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f src/client src/server
