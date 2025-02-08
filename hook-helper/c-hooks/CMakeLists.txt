cmake_minimum_required(VERSION 3.30.3 FATAL_ERROR)

project(hook-helper-c-hooks LANGUAGES C)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/llvm-ir-cmake-utils/cmake)

include(LLVMIRUtil)

set(ALL_HOOKS
    openmp-ir-bb-analysis
    single-threaded-ir-bb-analysis
    m5-naive
    nothing-naive
    papi-naive
    openmp-m5-nugget
    openmp-time-nugget
    single-threaded-m5-nugget
    single-threaded-papi-nugget
)

include(param)

message(STATUS "PAPI_PATH=${PAPI_PATH}")
message(STATUS "M5_PATH=${M5_PATH}")
message(STATUS "M5_INCLUDE_PATH=${M5_INCLUDE_PATH}")

if (NOT PAPI_PATH)
    # Filter out targets containing "papi"
    list(FILTER ALL_HOOKS EXCLUDE REGEX ".*papi.*")
    message(WARNING "Filtered out PAPI hooks due to missing PAPI_PATH")
endif()

if (NOT M5_PATH OR NOT M5_INCLUDE_PATH)
    # Filter out targets containing "m5"
    list(FILTER ALL_HOOKS EXCLUDE REGEX ".*m5.*")
    message(WARNING "Filtered out M5 hooks due to missing M5_PATH or M5_INCLUDE_PATH")
endif()

set(ALL_PAPI_HOOKS "")
set(ALL_M5_HOOKS "")
set(ALL_OPENMP_HOOKS "")

foreach(HOOK ${ALL_HOOKS})
    add_library(${HOOK} STATIC)
    set_target_properties(${HOOK} PROPERTIES LINKER_LANGUAGE C)

    if(${HOOK} MATCHES ".*papi.*")
        list(APPEND ALL_PAPI_HOOKS ${HOOK})
    endif()

    if(${HOOK} MATCHES ".*m5.*")
        list(APPEND ALL_M5_HOOKS ${HOOK})
    endif()

    if(${HOOK} MATCHES ".*openmp.*")
        list(APPEND ALL_OPENMP_HOOKS ${HOOK})
    endif()
endforeach()

add_subdirectory(analysis)
add_subdirectory(naive)
add_subdirectory(nugget)


foreach(HOOK ${ALL_PAPI_HOOKS})
    target_include_directories(${HOOK} PUBLIC ${PAPI_PATH}/include)
    target_link_directories(${HOOK} PUBLIC ${PAPI_PATH}/lib)
    target_link_libraries(${HOOK} PUBLIC papi)
endforeach()

foreach(HOOK ${ALL_M5_HOOKS})
    # Debug output before
    message(STATUS "Before linking ${HOOK}:")
    get_target_property(INCLUDE_DIRS ${HOOK} INCLUDE_DIRECTORIES)
    get_target_property(LINK_DIRS ${HOOK} LINK_DIRECTORIES)
    get_target_property(LINK_LIBS ${HOOK} LINK_LIBRARIES)
    message(STATUS "Include dirs: ${INCLUDE_DIRS}")
    message(STATUS "Link dirs: ${LINK_DIRS}")
    message(STATUS "Link libs: ${LINK_LIBS}")

    # Add library settings
    target_include_directories(${HOOK} PUBLIC ${M5_INCLUDE_PATH})
    target_link_directories(${HOOK} PUBLIC ${M5_PATH})
    target_link_libraries(${HOOK} PUBLIC ${M5_PATH}/libm5.a)
    target_compile_options(${HOOK} PUBLIC -no-pie)
    target_link_options(${HOOK} PUBLIC -no-pie)

    # Debug output after
    message(STATUS "After linking ${HOOK}:")
    get_target_property(INCLUDE_DIRS ${HOOK} INCLUDE_DIRECTORIES)
    get_target_property(LINK_DIRS ${HOOK} LINK_DIRECTORIES)
    get_target_property(LINK_LIBS ${HOOK} LINK_LIBRARIES)
    message(STATUS "Include dirs: ${INCLUDE_DIRS}")
    message(STATUS "Link dirs: ${LINK_DIRS}")
    message(STATUS "Link libs: ${LINK_LIBS}")
endforeach()

foreach(HOOK ${ALL_OPENMP_HOOKS})
    target_link_libraries(${HOOK} PUBLIC -fopenmp)
endforeach()

set(ALL_HOOKS_BC "")

foreach(HOOK ${ALL_HOOKS})
    llvmir_attach_bc_target("${HOOK}-bc" ${HOOK})
    llvmir_attach_link_target("${HOOK}-hook" "${HOOK}-bc")
    list(APPEND ALL_HOOKS_BC "${HOOK}-hook")
endforeach()

add_custom_target(hooks ALL DEPENDS ${ALL_HOOKS_BC})

