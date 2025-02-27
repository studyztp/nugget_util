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
        TARGET ${TRGT}_hook_ir
        DEPEND_TARGETS ${HOOK_TARGET}
        EXTRA_FLAGS ${EXTRA_FLAGS}
        EXTRA_INCLUDES ${EXTRA_INCLUDES}
        EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
        EXTRA_LIBS ${EXTRA_LIBS}
    )

    llvm_generate_ir_target(
        TARGET ${TRGT}_source_ir
        DEPEND_TARGETS ${DEP_TRGTS}
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

function(nugget_naive_bc)
    set(options)
    set(oneValueArgs TARGET HOOK_TARGET SOURCE_BC_FILE_PATH HOOK_BC_FILE_PATH)
    set(multiValueArgs 
        DEPEND_TARGETS
        EXTRA_FLAGS
        EXTRA_INCLUDES
        EXTRA_LIB_PATHS
        EXTRA_LIBS   
    )
    cmake_parse_arguments(
        NUGGET_NAIVE_BC 
        "${options}" "${oneValueArgs}" "${multiValueArgs}" 
        ${ARGN}
    )
    set(TRGT ${NUGGET_NAIVE_BC_TARGET})
    set(DEP_TRGTS ${NUGGET_NAIVE_BC_DEPEND_TARGETS})
    set(EXTRA_FLAGS ${NUGGET_NAIVE_BC_EXTRA_FLAGS})
    set(EXTRA_INCLUDES ${NUGGET_NAIVE_BC_EXTRA_INCLUDES})
    set(EXTRA_LIB_PATHS ${NUGGET_NAIVE_BC_EXTRA_LIB_PATHS})
    set(EXTRA_LIBS ${NUGGET_NAIVE_BC_EXTRA_LIBS})
    set(HOOK_TARGET ${NUGGET_NAIVE_BC_HOOK_TARGET})
    set(SOURCE_BC_FILE_PATH ${NUGGET_NAIVE_BC_SOURCE_BC_FILE_PATH})
    set(HOOK_BC_FILE_PATH ${NUGGET_NAIVE_BC_HOOK_BC_FILE_PATH})

    if (NOT TRGT)
        message(FATAL_ERROR "TARGET not set")
    endif()
    if (NOT DEP_TRGTS)
        message(FATAL_ERROR "DEPEND_TARGETS not set")
    endif()

    if(SOURCE_BC_FILE_PATH)
        create_bc_target_without_rebuild(
            TARGET ${TRGT}_source_bc
            BC_FILE_PATH ${SOURCE_BC_FILE_PATH}
            DEPEND_TARGETS ${DEP_TRGTS}
        )
    else()
        llvm_generate_ir_target(
            TARGET ${TRGT}_source_ir
            DEPEND_TARGETS ${DEP_TRGTS}
            EXTRA_FLAGS ${EXTRA_FLAGS}
            EXTRA_INCLUDES ${EXTRA_INCLUDES}
            EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
            EXTRA_LIBS ${EXTRA_LIBS}
        )
        llvm_link_ir_into_bc_target(
            TARGET ${TRGT}_source_bc
            DEPEND_TARGETS ${TRGT}_source_ir
        )
    endif()

    if(HOOK_BC_FILE_PATH)
    create_bc_target_without_rebuild(
        TARGET ${TRGT}_hook_bc
        BC_FILE_PATH ${HOOK_BC_FILE_PATH}
        DEPEND_TARGETS ${HOOK_TARGET}
    )
    else()
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
    endif()

    llvm_link_bc_targets(
        TARGET ${TRGT}
        DEPEND_TARGETS ${TRGT}_source_bc ${TRGT}_hook_bc
    )

endfunction()

function(nugget_nugget_bc)
    set(options LABEL_WARMUP)
    set(oneValueArgs 
        TARGET 
        HOOK_TARGET
        SOURCE_BC_FILE_PATH
        HOOK_BC_FILE_PATH
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
    set(HOOK_BC_FILE_PATH ${NUGGET_NUGGET_BC_HOOK_BC_FILE_PATH})

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

    if (HOOK_BC_FILE_PATH AND EXISTS ${HOOK_BC_FILE_PATH})
        create_bc_target_without_rebuild(
            TARGET ${TRGT}_hook_bc
            BC_FILE_PATH ${HOOK_BC_FILE_PATH}
            DEPEND_TARGETS ${HOOK_TARGET}
        )
    else()
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
    endif()

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

    add_custom_target(${TRGT} ALL DEPENDS ${ALL_TARGETS} ${TRGT}_hook_bc)

endfunction()

function(nugget_compile_exe)
    set(options)
    set(oneValueArgs TARGET BC_FILE_PATH)
    set(multiValueArgs 
        DEPEND_TARGETS
        ADDITIONAL_OPT
        EXTRA_FLAGS
        EXTRA_INCLUDES
        EXTRA_LIB_PATHS
        EXTRA_LIBS   
        LLC_CMD
        EXTRACT_FUNCTIONS
        FINAL_BC_FILE_PATHS
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
    set(BC_FILE_PATH ${NUGGET_COMPILE_EXE_BC_FILE_PATH})
    set(LLC_CMD ${NUGGET_COMPILE_EXE_LLC_CMD})
    set(EXTRACT_FUNCTIONS ${NUGGET_COMPILE_EXE_EXTRACT_FUNCTIONS})
    set(ADDITIONAL_OPT ${NUGGET_COMPILE_EXE_ADDITIONAL_OPT})
    set(FINAL_BC_FILE_PATHS ${NUGGET_COMPILE_EXE_FINAL_BC_FILE_PATHS})

    if (NOT TRGT)
        message(FATAL_ERROR "TARGET not set")
    endif()

    if (NOT DEP_TRGTS)
        message(FATAL_ERROR "DEP_TRGTS not set")
    endif()

    if(NOT LLVM_SETUP_DONE)
        message(FATAL_ERROR "LLVM setup not done"
            "Please call llvm_setup before calling nugget_bbv_profiling_exe")
    endif()

    message(STATUS "If EXTRACT_HOOK: ${EXTRACT_HOOK}")
    if(FINAL_BB_FILE_PATHS)
        set(BC_TARGET "")
        foreach(bb_file_path ${FINAL_BB_FILE_PATHS})
            cmake_path(GET bb_file_path STEM bb_file_name)
            create_bc_target_without_rebuild(
                TARGET ${bb_file_name}_bc
                BC_FILE_PATH ${bb_file_path}
                DEPEND_TARGETS ${DEP_TRGTS}
            )
            list(APPEND BC_TARGET ${bb_file_name}_bc)
        endforeach()
    else()
        if(BC_FILE_PATH)
            message(STATUS "BC_FILE_PATH: ${BC_FILE_PATH}")
            create_bc_target_without_rebuild(
                TARGET ${TRGT}_bc
                BC_FILE_PATH ${BC_FILE_PATH}
                DEPEND_TARGETS ${DEP_TRGTS}
            )
            set(BC_TARGET ${TRGT}_bc)
        else()
            set(count 0)
            foreach(DEP_TRGT ${DEP_TRGTS})
                math(EXPR count "${count} + 1")
            endforeach()
            if(count GREATER 1)
                message(FATAL_ERROR "BB_FILE_PATH not set for DEP_TRGTS has more than one target")
            endif()
            set(BC_TARGET ${DEP_TRGTS})
        endif()

        if(EXTRACT_FUNCTIONS) 
            llvm_extract_functions_to_bc(
                TARGET ${TRGT}_hook_bc
                DEPEND_TARGET ${BC_TARGET}
                FUNCTIONS ${EXTRACT_FUNCTIONS}
            )
            llvm_delete_functions_from_bc(
                TARGET ${TRGT}_source_bc
                DEPEND_TARGET ${BC_TARGET}
                FUNCTIONS ${EXTRACT_FUNCTIONS}
            )
            set(BC_TARGET ${TRGT}_hook_bc ${TRGT}_source_bc)
        endif()

    endif()

    if(ADDITIONAL_OPT)
        message(STATUS "ADDITIONAL_OPT: ${ADDITIONAL_OPT}")
        set(NEW_LIST "")
        foreach(target ${BC_TARGET})
            apply_opt_to_bc_target(
                TARGET ${target}_add_opt_bc
                DEPEND_TARGET ${target}
                OPT_COMMAND ${ADDITIONAL_OPT}
            )
            list(APPEND NEW_LIST ${target}_add_opt_bc)
        endforeach()
        set(BC_TARGET ${NEW_LIST})
    endif()

    if(LLC_CMD)
        set(OBJ_TARGET "")
        foreach(target ${BC_TARGET})
            llvm_llc_into_obj_target(
                TARGET ${target}_obj
                DEPEND_TARGET ${target}
                LLC_COMMAND ${LLC_CMD}
            )
            list(APPEND OBJ_TARGET ${target}_obj)
        endforeach()
    else()
        set(OBJ_TARGET ${BC_TARGET})
    endif()

    llvm_compile_into_executable_target(
        TARGET ${TRGT}
        DEPEND_TARGETS ${OBJ_TARGET}
        EXTRA_FLAGS ${EXTRA_FLAGS}
        EXTRA_LIB_PATHS ${EXTRA_LIB_PATHS}
        EXTRA_LIBS ${EXTRA_LIBS}
    )

endfunction()