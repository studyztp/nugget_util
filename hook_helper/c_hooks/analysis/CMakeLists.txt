
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


if("openmp-ir-bb-analysis-balance" IN_LIST ALL_HOOKS)
    target_sources(openmp-ir-bb-analysis-balance
        PUBLIC
        openmp-ir-bb-analysis-balance.c    
    )

    target_include_directories(
        openmp-ir-bb-analysis-balance
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if("count-marker-execution" IN_LIST ALL_HOOKS)
    target_sources(count-marker-execution
        PUBLIC
        count-marker-execution.c    
    )

    target_include_directories(
        count-marker-execution
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

if ("single-threaded-ir-bb-analysis-balance" IN_LIST ALL_HOOKS)
    target_sources(single-threaded-ir-bb-analysis-balance
        PUBLIC
        single-threaded-ir-bb-analysis-balance.c    
    )

    target_include_directories(
        single-threaded-ir-bb-analysis-balance
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
