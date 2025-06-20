
set(ALL_HOOKS
    openmp-ir-bb-analysis
    openmp-ir-bb-analysis-balance
    count-marker-execution
    single-threaded-ir-bb-analysis
    single-threaded-ir-bb-analysis-balance
    single-threaded-papi-analysis
    m5-naive
    sniper-naive
    nothing-naive
    papi-naive
    openmp-m5-nugget
    openmp-time-nugget
    single-threaded-m5-nugget
    single-threaded-papi-nugget
    openmp-sniper-nugget
    single-threaded-sniper-nugget
    empty-hooks-nugget
    single-threaded-empty-m5-nugget
    single-threaded-all-empty-m5-nugget
    single-threaded-empty-dynamorio-nugget
    openmp-empty-m5-nugget
)

message(STATUS "PAPI_PATH=${PAPI_PATH}")
message(STATUS "M5_PATH=${M5_PATH}")
message(STATUS "M5_INCLUDE_PATH=${M5_INCLUDE_PATH}")
message(STATUS "SNIPER_PATH=${SNIPER_PATH}")

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

if (NOT SNIPER_PATH)
    # Filter out targets containing "sniper"
    list(FILTER ALL_HOOKS EXCLUDE REGEX ".*sniper.*")
    message(WARNING "Filtered out Sniper hooks due to missing SNIPER_PATH")
endif()

set(ALL_PAPI_HOOKS "")
set(ALL_M5_HOOKS "")
set(ALL_OPENMP_HOOKS "")
set(ALL_SNIPER_HOOKS "")

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

    if(${HOOK} MATCHES ".*sniper.*")
        list(APPEND ALL_SNIPER_HOOKS ${HOOK})
    endif()

endforeach()

# Replace the add_subdirectory calls with:
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/analysis ${CMAKE_BINARY_DIR}/hooks/analysis)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/naive ${CMAKE_BINARY_DIR}/hooks/naive)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/nugget ${CMAKE_BINARY_DIR}/hooks/nugget)
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

    if (NOT "${USE_ADDR_VERSION_M5OPS_BEGIN}" STREQUAL "")
        target_compile_definitions(${HOOK} PUBLIC USE_ADDR_VERSION_M5OPS_BEGIN=${USE_ADDR_VERSION_M5OPS_BEGIN})
    endif()
    if (NOT "${USE_ADDR_VERSION_M5OPS_END}" STREQUAL "")
        target_compile_definitions(${HOOK} PUBLIC USE_ADDR_VERSION_M5OPS_END=${USE_ADDR_VERSION_M5OPS_END})
    endif()

endforeach()

foreach(HOOK ${ALL_OPENMP_HOOKS})
    #    target_link_libraries(${HOOK} PUBLIC OpenMP::OpenMP_CXX)
    target_link_options(
        ${HOOK}
        PRIVATE
        -fopenmp
    )
endforeach()

foreach(HOOK ${ALL_SNIPER_HOOKS})
    target_link_libraries(${HOOK} PUBLIC ${SNIPER_PATH}/libsniper.a)
endforeach()

