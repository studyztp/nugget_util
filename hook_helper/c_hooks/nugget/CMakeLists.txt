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

if ("openmp-sniper-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        openmp-sniper-nugget
        PUBLIC
        openmp-sniper-nugget.c
    )

    target_include_directories(
        openmp-sniper-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("single-threaded-sniper-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        single-threaded-sniper-nugget
        PUBLIC
        single-threaded-sniper-nugget.c
    )

    target_include_directories(
        single-threaded-sniper-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("empty-hooks-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        empty-hooks-nugget
        PUBLIC
        empty-hooks-nugget.c
    )

    target_include_directories(
        empty-hooks-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("single-threaded-empty-m5-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        single-threaded-empty-m5-nugget
        PUBLIC
        single-threaded-empty-m5-nugget.c
    )

    target_include_directories(
        single-threaded-empty-m5-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("single-threaded-all-empty-m5-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        single-threaded-all-empty-m5-nugget
        PUBLIC
        single-threaded-all-empty-m5-nugget.c
    )

    target_include_directories(
        single-threaded-all-empty-m5-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("single-threaded-empty-dynamorio-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        single-threaded-empty-dynamorio-nugget
        PUBLIC
        single-threaded-empty-dynamorio-nugget.c
    )

    target_include_directories(
        single-threaded-empty-dynamorio-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("openmp-empty-m5-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        openmp-empty-m5-nugget
        PUBLIC
        openmp-empty-m5-nugget.c
    )

    target_include_directories(
        openmp-empty-m5-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("single-threaded-time-nugget" IN_LIST ALL_HOOKS)
    target_sources(
        single-threaded-time-nugget
        PUBLIC
        single-threaded-time-nugget.c
    )

    target_include_directories(
        single-threaded-time-nugget
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()
