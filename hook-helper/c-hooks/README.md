# c hooks that are recognized by the LLVM pass

analysis:
    - single-threaded-ir-bb-analysis
    - openmp-ir-bb-analysis
    - [TBD] single-threaded-papi-analysis
    - [TBD] openmp-papi-analysis
naive:
    - papi-naive
    - m5-naive
    - nothing-naive
nugget:
    - single-threaded-papi-nugget
    - single-threaded-m5-nugget
    - openmp-time-nugget
    - [TBD] openmp-papi-nugget
    - openmp-m5-nugget

