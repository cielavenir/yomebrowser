CC=gcc -O2

.PHONY: all
all: unyomecolle getyomecolleuid

unyomecolle: unyomecolle.c
	$(CC) -o $@ $^
getyomecolleuid: getyomecolleuid.c rijndael.c
	$(CC) -o $@ $^
