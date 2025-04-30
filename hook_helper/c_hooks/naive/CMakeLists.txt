if ("m5-naive" IN_LIST ALL_HOOKS)
    target_sources(
        m5-naive
        PUBLIC
        m5-naive.c
    )

    target_include_directories(
        m5-naive
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("nothing-naive" IN_LIST ALL_HOOKS)
    target_sources(
        nothing-naive
        PUBLIC
        nothing-naive.c
    )

    target_include_directories(
        nothing-naive
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("papi-naive" IN_LIST ALL_HOOKS)
    target_sources(
        papi-naive
        PUBLIC
        papi-naive.c
    )
    target_include_directories(
        papi-naive
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("sniper-naive" IN_LIST ALL_HOOKS)
    target_sources(
        sniper-naive
        PUBLIC
        sniper-naive.c
    )

    target_include_directories(
        sniper-naive
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()
