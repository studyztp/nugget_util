if ("openmp-m5-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        openmp-m5-nugget
        PUBLIC
        openmp-m5-nugget.c
    )

    target_include_directories(
        openmp-m5-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("openmp-time-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        openmp-time-nugget
        PUBLIC
        openmp-time-nugget.c
    )

    target_include_directories(
        openmp-time-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("single-threaded-m5-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        single-threaded-m5-nugget
        PUBLIC
        single-threaded-m5-nugget.c
    )

    target_include_directories(
        single-threaded-m5-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("single-threaded-papi-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        single-threaded-papi-nugget
        PUBLIC
        single-threaded-papi-nugget.c
    )


    target_include_directories(
        single-threaded-papi-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()
