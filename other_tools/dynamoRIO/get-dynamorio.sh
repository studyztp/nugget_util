git clone https://github.com/DynamoRIO/dynamorio.git
cd dynamorio
git submodule update --init --recursive
mkdir build
cd build
cmake ..
cmake --build . --parallel
