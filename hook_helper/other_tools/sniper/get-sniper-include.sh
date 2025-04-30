#!/bin/bash

git clone https://github.com/snipersim/snipersim.git  --depth=1 --filter=blob:none --no-checkout --sparse 
pushd snipersim
git sparse-checkout add include
git checkout
mv include ../
popd 
rm -rf snipersim
