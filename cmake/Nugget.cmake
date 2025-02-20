list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/my-llvm-ir-cmake-lib")

include(LLVMIRUtil)
include(NuggetInternal)
include(CMakeParseArguments)

function(nugget_bbv_profiling_bc)
    set(options)
    set(oneValueArgs TARGET REGION_LENGTH BB_INFO_OUTPUT_PATH HOOK_TARGET) 
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
    set(HOOK_TARGET ${NUGGET_BBV_PROFILING_BC_HOOK_TARGET})

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

    if(NOT HOOK_TARGET)
        message(FATAL_ERROR "HOOK_TARGET not set")
    endif()

    llvm_generate_ir_target(
        TARGET ${TRGT}_source_ir
        DEPEND_TARGETS ${DEP_TRGTS}
        EXTRA_FLAGS ${EXTRA_FLAGS}
        EXTRA_INCLUDES ${EXTRA_INCLUDES}
        EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
        EXTRA_LIBS ${EXTRA_LIBS}
    )

    llvm_generate_ir_target(
        TARGET ${TRGT}_hook_ir
        DEPEND_TARGETS ${HOOK_TARGET}
        EXTRA_FLAGS ${EXTRA_FLAGS}
        EXTRA_INCLUDES ${EXTRA_INCLUDES}
        EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
        EXTRA_LIBS ${EXTRA_LIBS}
    )

    llvm_link_ir_into_bc_target(
        TARGET ${TRGT}_source_bc
        DEPEND_TARGETS ${TRGT}_source_ir
    )

    llvm_link_ir_into_bc_target(
        TARGET ${TRGT}_hook_bc
        DEPEND_TARGETS ${TRGT}_hook_ir
    )

    llvm_link_bc_targets(
        TARGET ${TRGT}_bc
        DEPEND_TARGETS ${TRGT}_source_bc ${TRGT}_hook_bc
    )

    set(OPT_CMD
        -passes=phase-analysis 
        -phase-analysis-output-file=${BB_INFO_OUTPUT_PATH}
        -phase-analysis-using-papi=false 
        -phase-analysis-region-length=${REGION_LENGTH}
    )

    apply_opt_to_bc_target(
        TARGET ${TRGT}
        DEPEND_TARGET ${TRGT}_bc
        OPT_COMMAND ${OPT_CMD}
    )
endfunction()

function(nugget_nugget_bc)
    set(options LABEL_WARMUP)
    set(oneValueArgs 
        TARGET 
        HOOK_TARGET
        SOURCE_BC_FILE_PATH
        INPUT_FILE_DIR 
        INPUT_FILE_NAME_BASE
        BB_INFO_INPUT_PATH 
        BB_INFO_OUTPUT_DIR
        LABEL_TARGET
        )
    set(multiValueArgs
        DEPEND_TARGETS
        ALL_NUGGET_RIDS
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
    set(HOOK_TARGET ${NUGGET_NUGGET_BC_HOOK_TARGET})
    set(SOURCE_BC_FILE_PATH ${NUGGET_NUGGET_BC_SOURCE_BC_FILE_PATH})
    set(INPUT_FILE_DIR ${NUGGET_NUGGET_BC_INPUT_FILE_DIR})
    set(INPUT_FILE_NAME_BASE ${NUGGET_NUGGET_BC_INPUT_FILE_NAME_BASE})
    set(BB_INFO_INPUT_PATH ${NUGGET_NUGGET_BC_BB_INFO_INPUT_PATH})
    set(BB_INFO_OUTPUT_DIR ${NUGGET_NUGGET_BC_BB_INFO_OUTPUT_DIR})
    set(LABEL_TARGET ${NUGGET_NUGGET_BC_LABEL_TARGET})
    set(LABEL_WARMUP ${NUGGET_NUGGET_BC_LABEL_WARMUP})
    set(ALL_NUGGET_RIDS ${NUGGET_NUGGET_BC_ALL_NUGGET_RIDS})

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

    if(NOT SOURCE_BC_FILE_PATH)
        message(FATAL_ERROR "SOURCE_BC_FILE_PATH not set")
    endif()

    if(NOT INPUT_FILE_DIR)
        message(FATAL_ERROR "INPUT_FILE_DIR not set")
    endif()

    if(NOT INPUT_FILE_NAME_BASE)
        message(FATAL_ERROR "INPUT_FILE_NAME_BASE not set")
    endif()

    if(NOT BB_INFO_INPUT_PATH)
        message(FATAL_ERROR "BB_INFO_INPUT_PATH not set")
    endif()

    if(NOT BB_INFO_OUTPUT_DIR)
        set(BB_INFO_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/${TRGT}-bb-info-output")
        if(NOT EXISTS ${BB_INFO_OUTPUT_DIR})
            file(MAKE_DIRECTORY ${BB_INFO_OUTPUT_DIR})
            if(NOT EXISTS ${BB_INFO_OUTPUT_DIR})
                message(FATAL_ERROR "Failed to create directory ${BB_INFO_OUTPUT_DIR}")
            endif()
        endif()
    endif()

    llvm_generate_ir_target(
        TARGET ${TRGT}_hook_ir
        DEPEND_TARGETS ${HOOK_TARGET}
        EXTRA_FLAGS ${EXTRA_FLAGS}
        EXTRA_INCLUDES ${EXTRA_INCLUDES}
        EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
        EXTRA_LIBS ${EXTRA_LIBS}
    )

    llvm_link_ir_into_bc_target(
        TARGET ${TRGT}_hook_bc
        DEPEND_TARGETS ${TRGT}_hook_ir
    )

    create_bc_target_without_rebuild(
        TARGET ${TRGT}_source_bc
        BC_FILE_PATH ${SOURCE_BC_FILE_PATH}
        DEPEND_TARGETS ${DEP_TRGTS}
    )

    llvm_link_bc_targets(
        TARGET ${TRGT}_bc
        DEPEND_TARGETS ${TRGT}_source_bc ${TRGT}_hook_bc
    )

    set(ALL_TARGETS "")
    foreach(rid ${ALL_NUGGET_RIDS})
        set(OPT_CMD
            -passes=phase-bound
            -phase-bound-bb-order-file=${BB_INFO_INPUT_PATH}
            -phase-bound-input-file=${INPUT_FILE_DIR}/${rid}${INPUT_FILE_NAME_BASE}
            -phase-bound-output-file=${BB_INFO_OUTPUT_DIR}/${rid})

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
            TARGET ${TRGT}_${rid}
            DEPEND_TARGET ${TRGT}_bc
            OPT_COMMAND ${OPT_CMD}
        )
        list(APPEND ALL_TARGETS ${TRGT}_${rid})
    endforeach()

    add_custom_target(${TRGT} ALL DEPENDS ${ALL_TARGETS})

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
    set(TRGT ${NUGGET_COMPILE_EXE_TARGET})
    set(DEP_TRGTS ${NUGGET_COMPILE_EXE_DEPEND_TARGETS})
    set(EXTRA_FLAGS ${NUGGET_COMPILE_EXE_EXTRA_FLAGS})
    set(EXTRA_INCLUDES ${NUGGET_COMPILE_EXE_EXTRA_INCLUDES})
    set(EXTRA_LIB_PATHS ${NUGGET_COMPILE_EXE_EXTRA_LIB_PATHS})
    set(EXTRA_LIBS ${NUGGET_COMPILE_EXE_EXTRA_LIBS})
    set(BB_FILE_PATH ${NUGGET_COMPILE_EXE_BB_FILE_PATH})
    set(LLC_CMD ${NUGGET_COMPILE_EXE_LLC_CMD})

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
        set(BC_TARGET ${TRGT}_bc)
    else()
        set(count 0)
        foreach(DEP_TRGT ${DEP_TRGTS})
            math(EXPR count "${count} + 1")
        endforeach()
        if(count GREATER 1)
            message(FATAL_ERROR "BB_FILE_PATH not set and DEPEND_TARGETS has more than one target")
        endif()
        set(BC_TARGET ${DEP_TRGTS})
    endif()

    if(LLC_CMD)
        llvm_llc_into_obj_target(
            TARGET ${TRGT}_obj
            DEPEND_TARGET ${BC_TARGET}
            LLC_COMMAND ${LLC_CMD}
        )
        set(OBJ_TARGET ${TRGT}_obj)
    else()
        set(OBJ_TARGET ${BC_TARGET})
    endif()

    llvm_compile_into_executable_target(
        TARGET ${TRGT}
        DEPEND_TARGET ${OBJ_TARGET}
        EXTRA_FLAGS ${EXTRA_FLAGS}
        EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
        EXTRA_LIBS ${EXTRA_LIBS}
    )

endfunction()