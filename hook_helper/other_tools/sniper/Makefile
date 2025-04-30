CC = gcc
CFLAGS = -Wall -O2 -fPIC
INCLUDE_DIR = .
LDFLAGS = -L.
LIBS = -lsniper

SRCS = sim_api.c
OBJS = $(SRCS:.c=.o)
TARGET = libsniper.a
TEST = test

.PHONY: all clean test

all: $(TARGET) $(TEST)

$(TARGET): $(OBJS)
	ar rcs $@ $(OBJS)

$(TEST): test.c $(TARGET)
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS) $(LIBS)

%.o: %.c
	$(CC) $(CFLAGS) -I$(INCLUDE_DIR) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET) $(TEST)
