
if("openmp-ir-bb-analysis" IN_LIST ALL_HOOKS)
    target_sources(openmp-ir-bb-analysis
        PUBLIC
        openmp-ir-bb-analysis.c    
    )

    target_include_directories(
        openmp-ir-bb-analysis
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()


if ("single-threaded-ir-bb-analysis" IN_LIST ALL_HOOKS)
    target_sources(single-threaded-ir-bb-analysis
        PUBLIC
        single-threaded-ir-bb-analysis.c    
    )

    target_include_directories(
        single-threaded-ir-bb-analysis
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if ("single-threaded-papi-analysis" IN_LIST ALL_HOOKS)
    target_sources(single-threaded-papi-analysis
        PUBLIC
        single-threaded-papi-analysis.c    
    )

    target_include_directories(
        single-threaded-papi-analysis
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()
