# TensorCore Bare-Metal Driver Makefile
# For use with Xilinx Vitis SDK

# Compiler settings (use Vitis ARM compiler)
CC = arm-none-eabi-gcc
AR = arm-none-eabi-ar
CFLAGS = -Wall -O2 -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard

# For standalone testing on host
HOST_CC = gcc
HOST_CFLAGS = -Wall -O2 -g

# Sources
SRCS = tensorcore.c
OBJS = $(SRCS:.c=.o)
LIB = libtensorcore.a

# Targets
.PHONY: all clean host test

all: $(LIB)

$(LIB): $(OBJS)
	$(AR) rcs $@ $^

%.o: %.c tensorcore.h
	$(CC) $(CFLAGS) -c $< -o $@

# Host build for testing
host:
	$(HOST_CC) $(HOST_CFLAGS) -c tensorcore.c -o tensorcore_host.o
	$(AR) rcs libtensorcore_host.a tensorcore_host.o

# Simple test program
test: host
	$(HOST_CC) $(HOST_CFLAGS) -o test_driver test_driver.c -L. -ltensorcore_host

clean:
	rm -f *.o *.a test_driver
