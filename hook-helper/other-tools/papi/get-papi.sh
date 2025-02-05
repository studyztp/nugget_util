#!/bin/bash

# get the papi repository

git clone git@github.com:icl-utk-edu/papi.git

pushd papi/src

ARCH=$(uname -m)

# build the library and binary
./configure --prefix=$PWD/../../$ARCH

make -j$(nproc)
make install

popd

rm -rf papi
