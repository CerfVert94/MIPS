CC = gcc
CFLAGS = -Wall
LDFLAGS = 
PROGRAMS =
OBJ = bitmapCalc bitmapIO bitmapIntegrity main
EXEC = projet
DEBUGGER = gdb
DEBUG_EXEC = debug

all:$(OBJ) exec

debug:$(OBJ)
	$(CC) -o $(DEBUG_EXEC) *.c $(CLFAGS) -g &&$(DEBUGGER) ./$(DEBUG_EXEC) 

exec:
	$(CC) -o $(EXEC) *.o $(CFLAGS) 
bitmapIO: bitmapIO.c
	$(CC) -o $@.o $< $(CFLAGS) -c
bitmapCalc: bitmapCalc.c
	$(CC) -o $@.o $< $(CFLAGS) -c
bitmapIntegrity: bitmapIntegrity.c
	$(CC) -o $@.o $< $(CFLAGS) -c
main: main.c
	$(CC) -o $@.o $< $(CFLAGS) -c
test:
	echo $(OBJ)
clean: 
	rm *.o $(EXEC) $(DEBUG_EXEC)
.phony: all clean test
