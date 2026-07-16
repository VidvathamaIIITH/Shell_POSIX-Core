# ============================================================================
#  Shell_POSIX-Core  --  Makefile
#  Author: vidvathamaiiith
#  Copyright (c) vidvathamaiiith. All Rights Reserved.
# ============================================================================
CC = gcc
CFLAGS = -Wall -Iinclude
LDLIBS = -lm
SRC = src/main.c src/globals.c src/queue.c src/hop.c src/reveal.c src/seek.c \
      src/log.c src/proclore.c src/activities.c src/signals.c src/neonate.c \
      src/iman.c src/sys.c src/sysinfo.c src/mark.c src/calc.c
OBJ = $(SRC:.c=.o)
EXEC = shell

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)

clean:
	rm -f $(OBJ) $(EXEC)
