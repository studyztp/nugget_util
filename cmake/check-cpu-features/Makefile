ifndef LLVM_DIR
  $(error LLVM_DIR is not set)
endif

LLVM_BIN = ${LLVM_DIR}/bin
LLVM_LIB = ${LLVM_DIR}/lib
LLVM_INCLUDE = ${LLVM_DIR}/include

LLVM_CLANG++ = ${LLVM_BIN}/clang++

# Detect system architecture and set library path
ARCH := $(shell uname -m)
ifeq ($(ARCH),aarch64)
    SYSTEM_LIB = /usr/lib/aarch64-linux-gnu
    NCURSES_LIB = -L$(SYSTEM_LIB) -l:libncurses.so.6
else
    SYSTEM_LIB = /usr/lib/x86_64-linux-gnu
    NCURSES_LIB = -lncurses
endif

all: check-cpu-features

check-cpu-features: check-cpu-features.cpp
	${LLVM_CLANG++} -I${LLVM_INCLUDE} -L${LLVM_LIB} check-cpu-features.cpp -o check-cpu-features \
        `${LLVM_BIN}/llvm-config --libs support core` \
        -Wl,-rpath,${LLVM_LIB} \
        $(NCURSES_LIB)

clean:
	rm -f check-cpu-features
