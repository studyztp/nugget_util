set(PAPI_PATH "/home/studyztp/test_ground/open-source-project/nugget-util/hook-helper/other-tools/papi/x86_64")
set(M5_PATH "/home/studyztp/test_ground/open-source-project/nugget-util/hook-helper/other-tools/gem5/x86")
set(M5_INCLUDE_PATH "/home/studyztp/test_ground/open-source-project/nugget-util/hook-helper/other-tools/gem5/include")

# set if we should use addr mop m5 ops in the beginning and end of the ROI
# for
set(IF_USE_ADDR_VERSION_M5OPS_BEGIN TRUE)
set(IF_USE_ADDR_VERSION_M5OPS_END TRUE)

set(LLVM_DIR "/scr/studyztp/compiler/llvm-dir")
set(LLVM_BIN ${LLVM_DIR}/bin)
set(CMAKE_CXX_COMPILER ${LLVM_BIN}/clang++)
set(CMAKE_C_COMPILER ${LLVM_BIN}/clang)
set(CMAKE_FORTRAN_COMPILER ${LLVM_BIN}/flang-new)
