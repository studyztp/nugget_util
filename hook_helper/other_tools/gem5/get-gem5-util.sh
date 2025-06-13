#!/bin/bash

# Just get the files we need
git clone https://github.com/gem5/gem5.git --depth=1 --filter=blob:none --no-checkout --sparse --single-branch --branch=stable
pushd gem5
# Checkout just the files we need
git sparse-checkout add util/m5
git sparse-checkout add util/gem5_bridge
git sparse-checkout add include
git checkout
# Install the headers globally so that other benchmarks can use them

popd

if [ ! -d "${PWD}/include/gem5" ]; then
    mkdir -p ${PWD}/include/gem5
    cp -r gem5/include/gem5/* ${PWD}/include/gem5
    cp gem5/util/m5/src/m5_mmap.h ${PWD}/include/gem5
fi

declare -p ISAS

if [ -z "$ISAS" ]; then
    # Declare array with proper syntax
    declare -a ISAS=("arm" "arm64" "riscv" "sparc" "thumb" "x86")
else
    # Split input string into array
    IFS=' ' read -ra ISAS <<< "$ISAS"
fi

# Build the library and binary
pushd gem5/util/m5

# Iterate through array with proper quoting
for isa in "${ISAS[@]}"; do
    echo "Building for ISA: ${isa}"
    if ! scons "${isa}.CROSS_COMPILE=" "build/${isa}/out/m5"; then
        echo "Failed to build for ${isa}"
        exit 1
    fi
done

popd

# Copy files with proper path handling
for isa in "${ISAS[@]}"; do
    if [ ! -d "${PWD}/${isa}" ]; then
        mkdir -p "${PWD}/${isa}"
        echo "Copying files for ${isa}"
        cp "gem5/util/m5/build/${isa}/out/m5" "${PWD}/${isa}/"
        cp "gem5/util/m5/build/${isa}/out/libm5.a" "${PWD}/${isa}/"
    fi
done

rm -rf gem5
