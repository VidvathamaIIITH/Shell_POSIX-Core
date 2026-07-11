CC = gcc
CFLAGS = -Wall -Iinclude
SRC = src/main.c src/globals.c src/queue.c src/hop.c src/reveal.c src/seek.c src/log.c src/proclore.c src/activities.c src/signals.c src/neonate.c src/iman.c src/sys.c
OBJ = $(SRC:.c=.o)
EXEC = shell

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(OBJ) $(EXEC)
