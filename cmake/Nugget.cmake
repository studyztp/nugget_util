list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/my-llvm-ir-cmake-lib")

include(LLVMIRUtil)
include(NuggetInternal)
include(CMakeParseArguments)

function(nugget_bbv_profiling_bc)
    set(options)
    set(oneValueArgs TARGET REGION_LENGTH BB_INFO_OUTPUT_PATH) 
    set(multiValueArgs 
        DEPEND_TARGETS
        EXTRA_FLAGS
        EXTRA_INCLUDES
        EXTRA_LIB_PATHS
        EXTRA_LIBS   
    )
    cmake_parse_arguments(
        NUGGET_BBV_PROFILING_BC 
        "${options}" "${oneValueArgs}" "${multiValueArgs}" 
        ${ARGN}
    )
    set(TRGT ${NUGGET_BBV_PROFILING_BC_TARGET})
    set(DEP_TRGTS ${NUGGET_BBV_PROFILING_BC_DEPEND_TARGETS})
    set(EXTRA_FLAGS ${NUGGET_BBV_PROFILING_BC_EXTRA_FLAGS})
    set(EXTRA_INCLUDES ${NUGGET_BBV_PROFILING_BC_EXTRA_INCLUDES})
    set(EXTRA_LIB_PATHS ${NUGGET_BBV_PROFILING_BC_EXTRA_LIB_PATHS})
    set(EXTRA_LIBS ${NUGGET_BBV_PROFILING_BC_EXTRA_LIBS})
    set(REGION_LENGTH ${NUGGET_BBV_PROFILING_BC_REGION_LENGTH})
    set(BB_INFO_OUTPUT_PATH ${NUGGET_BBV_PROFILING_BC_BB_INFO_OUTPUT_PATH})
    
    if (NOT TRGT)
        message(FATAL_ERROR "TARGET not set")
    endif()
    if (NOT DEP_TRGTS)
        message(FATAL_ERROR "DEPEND_TARGETS not set")
    endif()

    if(NOT LLVM_SETUP_DONE)
        message(FATAL_ERROR "LLVM setup not done"
            "Please call llvm_setup before calling nugget_bbv_profiling_bc")
    endif()

    if(NOT REGION_LENGTH)
        message(FATAL_ERROR "REGION_LENGTH not set")
    endif()

    if(NOT BB_INFO_OUTPUT_PATH)
        set(BB_INFO_OUTPUT_PATH "basic_block_info_output.txt")
    endif()

    llvm_generate_ir_target(
        TARGET ${TRGT}_ir
        DEPEND_TARGETS ${DEP_TRGTS}
        EXTRA_FLAGS ${EXTRA_FLAGS}
        EXTRA_INCLUDES ${EXTRA_INCLUDES}
        EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
        EXTRA_LIBS ${EXTRA_LIBS}
    )

    llvm_link_ir_into_bc_target(
        TARGET ${TRGT}_bc
        DEPEND_TARGETS ${TRGT}_ir
    )

    set(OPT_CMD
        -passes=phase-analysis 
        -phase-analysis-output-file=${BB_INFO_OUTPUT_PATH}
        -phase-analysis-using-papi=false 
        -phase-analysis-region-length=${REGION_LENGTH}
    )

    apply_opt_to_bc_target(
        TARGET ${TRGT}_opt_bc
        DEPEND_TARGET ${TRGT}_bc
        OPT_CMD ${OPT_CMD}
    )
endfunction()

function(nugget_nugget_bc)
    set(options LABEL_WARMUP)
    set(oneValueArgs 
        TARGET 
        INPUT_FILE_PATH 
        BB_INFO_INPUT_PATH 
        BB_INFO_OUTPUT_PATH
        LABEL_TARGET
        )
    set(multiValueArgs
        DEPEND_TARGETS
        EXTRA_FLAGS
        EXTRA_INCLUDES
        EXTRA_LIB_PATHS
        EXTRA_LIBS
    )
    cmake_parse_arguments(
        NUGGET_NUGGET_BC
        "${options}" "${oneValueArgs}" "${multiValueArgs}"
        ${ARGN}
    )
    set(TRGT ${NUGGET_NUGGET_BC_TARGET})
    set(DEP_TRGTS ${NUGGET_NUGGET_BC_DEPEND_TARGETS})
    set(EXTRA_FLAGS ${NUGGET_NUGGET_BC_EXTRA_FLAGS})
    set(EXTRA_INCLUDES ${NUGGET_NUGGET_BC_EXTRA_INCLUDES})
    set(EXTRA_LIB_PATHS ${NUGGET_NUGGET_BC_EXTRA_LIB_PATHS})
    set(EXTRA_LIBS ${NUGGET_NUGGET_BC_EXTRA_LIBS})
    set(INPUT_FILE_PATH ${NUGGET_NUGGET_BC_INPUT_FILE_PATH})
    set(BB_INFO_OUTPUT_PATH ${NUGGET_NUGGET_BC_BB_INFO_OUTPUT_PATH})
    set(BB_INFO_INPUT_PATH ${NUGGET_NUGGET_BC_BB_INFO_INPUT_PATH})
    set(LABEL_TARGET ${NUGGET_NUGGET_BC_LABEL_TARGET})
    set(LABEL_WARMUP ${NUGGET_NUGGET_BC_LABEL_WARMUP})

    if(NOT LLVM_SETUP_DONE)
        message(FATAL_ERROR "LLVM setup not done"
            "Please call llvm_setup before calling nugget_bbv_profiling_bc")
    endif()

    if (NOT TRGT)
        message(FATAL_ERROR "TARGET not set")
    endif()

    if (NOT DEP_TRGTS)
        message(FATAL_ERROR "DEPEND_TARGETS not set")
    endif()

    if (NOT INPUT_FILE_PATH)
        message(FATAL_ERROR "INPUT_FILE_PATH not set")
    endif()

    if(NOT BB_INFO_INPUT_PATH)
        message(FATAL_ERROR "BB_INFO_INPUT_PATH not set")
    endif()

    if(NOT BB_INFO_OUTPUT_PATH)
        set(BB_INFO_OUTPUT_PATH "basic_block_info_output.txt")
    endif()

    llvm_generate_ir_target(
        TARGET ${TRGT}_ir
        DEPEND_TARGETS ${DEP_TRGTS}
        EXTRA_FLAGS ${EXTRA_FLAGS}
        EXTRA_INCLUDES ${EXTRA_INCLUDES}
        EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
        EXTRA_LIBS ${EXTRA_LIBS}
    )

    llvm_link_ir_into_bc_target(
        TARGET ${TRGT}_bc
        DEPEND_TARGETS ${TRGT}_ir
    )

    set(OPT_CMD
        -passes=phase-bound
        -phase-bound-bb-order-file=${BB_INFO_INPUT_PATH}
        -phase-bound-input-file=${INPUT_FILE_PATH}
        -phase-bound-output-file=${BB_INFO_OUTPUT_PATH})

    if(LABEL_TARGET)
        list(APPEND OPT_CMD -phase-bound-label-target=${LABEL_TARGET})
        if(LABEL_WARMUP)
            list(APPEND OPT_CMD phase-bound-label-warmup=true)
        else()
            list(APPEND OPT_CMD phase-bound-label-warmup=false)
        endif()
        list(APPEND OPT_CMD phase-bound-label-only=true)
    endif()

    apply_opt_to_bc_target(
        TARGET ${TRGT}_opt_bc
        DEPEND_TARGET ${TRGT}_bc
        OPT_CMD ${OPT_CMD}
    )

endfunction()

function(nugget_compile_exe)
    set(options)
    set(oneValueArgs TARGET BB_FILE_PATH)
    set(multiValueArgs 
        DEPEND_TARGETS
        EXTRA_FLAGS
        EXTRA_INCLUDES
        EXTRA_LIB_PATHS
        EXTRA_LIBS   
        LLC_CMD
    )
    cmake_parse_arguments(
        NUGGET_COMPILE_EXE
        "${options}" "${oneValueArgs}" "${multiValueArgs}" 
        ${ARGN}
    )
    set(TRGT ${NUGGET_BBV_PROFILING_EXE_TARGET})
    set(DEP_TRGTS ${NUGGET_BBV_PROFILING_EXE_DEPEND_TARGETS})
    set(EXTRA_FLAGS ${NUGGET_BBV_PROFILING_EXE_EXTRA_FLAGS})
    set(EXTRA_INCLUDES ${NUGGET_BBV_PROFILING_EXE_EXTRA_INCLUDES})
    set(EXTRA_LIB_PATHS ${NUGGET_BBV_PROFILING_EXE_EXTRA_LIB_PATHS})
    set(EXTRA_LIBS ${NUGGET_BBV_PROFILING_EXE_EXTRA_LIBS})
    set(BB_FILE_PATH ${NUGGET_BBV_PROFILING_EXE_BB_FILE_PATH})
    set(LLC_CMD ${NUGGET_BBV_PROFILING_EXE_LLC_CMD})

    if (NOT TRGT)
        message(FATAL_ERROR "TARGET not set")
    endif()

    if (NOT DEP_TRGTS)
        message(FATAL_ERROR "DEPEND_TARGETS not set")
    endif()

    if(NOT LLVM_SETUP_DONE)
        message(FATAL_ERROR "LLVM setup not done"
            "Please call llvm_setup before calling nugget_bbv_profiling_exe")
    endif()

    if(BB_FILE_PATH)
        create_bc_target_without_rebuild(
            TARGET ${TRGT}_bc
            BC_FILE_PATH ${BB_FILE_PATH}
            DEPEND_TARGETS ${DEP_TRGTS}
        )
    else()
        set(count 0)
        foreach(DEP_TRGT ${DEP_TRGTS})
            math(EXPR count "${count} + 1")
        endforeach()
        if(count GREATER 1)
            message(FATAL_ERROR "BB_FILE_PATH not set and DEPEND_TARGETS has more than one target")
        endif()
        set(${TRGT}_bc ${DEP_TRGTS})
    endif()

    if(LLC_CMD)
        llvm_llc_into_obj_target(
            TARGET ${TRGT}_obj
            DEPEND_TARGETS ${TRGT}_bc
            LLC_COMMAND ${LLC_CMD}
        )
    else()
        set(${TRGT}_obj ${TRGT}_bc)
    endif()

    llvm_link_obj_target(
        TARGET ${TRGT}_exe
        DEPEND_TARGETS ${TRGT}_obj
        EXTRA_FLAGS ${EXTRA_FLAGS}
        EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
        EXTRA_LIBS ${EXTRA_LIBS}
    )
endfunction()