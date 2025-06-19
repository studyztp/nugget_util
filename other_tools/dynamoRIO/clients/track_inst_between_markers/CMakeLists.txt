cmake_minimum_required(VERSION 3.30)
project(track_markers C)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Determine DynamoRIO path
if(DEFINED ENV{DynamoRIO_DIR} AND NOT "$ENV{DynamoRIO_DIR}" STREQUAL "")
    message(STATUS "Using DynamoRIO_DIR from environment: $ENV{DynamoRIO_DIR}")
    set(DynamoRIO_DIR $ENV{DynamoRIO_DIR})
else()
    message(WARNING "DynamoRIO_DIR environment variable is not set. Using default path.")
    set(DynamoRIO_DIR ${CMAKE_CURRENT_LIST_DIR}/../../dynamorio/build/cmake)
endif()

# Find core DynamoRIO
find_package(DynamoRIO REQUIRED)
if (NOT DynamoRIO_FOUND)
    message(FATAL_ERROR "DynamoRIO package required to build")
endif()

# Include extension headers (drmgr)
include_directories(${DynamoRIO_DIR}/../ext/include)

# Build the client
add_library(track_markers SHARED track_inst_between_markers.c)

set(DRMGR_LIB
    /home/studyztp/test_ground/experiments/nugget-eval/gem5-experiments/nugget-protocol-NPB/nugget_util/other_tools/dynamoRIO/dynamorio/build/ext/lib64/release/libdrmgr.so
)


# Link core + drmgr manually
target_link_libraries(track_markers
    ${DynamoRIO_LIBRARIES}
    ${DynamoRIO_CLIENT_LIBS}           # drmgr and other extensions live here
    ${DRMGR_LIB}                       # drmgr library
)

# Configure as a DynamoRIO client
configure_DynamoRIO_client(track_markers)
