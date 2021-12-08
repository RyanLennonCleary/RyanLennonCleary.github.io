EXECUTABLE=dijkstra
SRC_C=adjacent.c main.c dijkstra.c
CC=gcc
CFLAGS= -lm -g -O3 -std=c99 -Wall -Wshadow -Wvla -Werror -pedantic 
$(EXECUTABLE): $(SRC_C) 
	$(CC) -o dijkstra dijkstra.c adjacent.c main.c $(CFLAGS) 
test: $(EXECUTABLE)
	./$(EXECUTABLE) $(MAP) $(QUERY)


.PHONY: test
