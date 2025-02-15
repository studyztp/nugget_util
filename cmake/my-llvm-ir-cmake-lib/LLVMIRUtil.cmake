#.rst:
#LLVM-IR-Util
# -------------
#
# LLVM IR utils for cmake

cmake_minimum_required(VERSION 3.30.3)

include(CMakeParseArguments)

include(LLVMIRUtilInternal)

###

llvmir_setup()

###

function(llvm_generate_ir_target)
    set(options ADDITIONAL_COMMANDS)
    set(oneValueArgs TARGET)
    set(multiValueArgs DEPEND_TARGETS)
    cmake_parse_arguments(LLVM_GENERATE 
    "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(TRGT ${LLVM_GENERATE_TARGET})
    set(DEP_TRGTS ${LLVM_GENERATE_DEPEND_TARGETS})

    if(NOT TRGT)
        message(FATAL_ERROR "llvmir_attach_bc_target: missing TARGET option")
    endif()

    if(NOT DEP_TRGTS)
        message(FATAL_ERROR "llvmir_attach_bc_target: missing DEPENDS option")
    endif()
    
    # check if the necessary properties are set
    # for this function, we need the SOURCES property
    foreach(dep_trgt ${DEP_TRGTS})
        get_property(LOCAL_FILES TARGET ${dep_trgt} PROPERTY SOURCES)
        if(NOT LOCAL_FILES)
            message(FATAL_ERROR 
                "llvm_generate_ir_target: missing SOURCES property for target ${dep_trgt}"
            )
        endif()
    endforeach()

    # setup global lists to store the properties of all targets

    # list of all the output files and their names
    set(GLOBAL_SOURCES "")
    set(OUTPUT_LLVM_IR_FILE_PATHS "")

    # list of all the dependencies
    set(GLOBAL_LIB_LINKINGS "")
    set(GLOBAL_LIB_INCLUDES "")
    set(GLOBAL_LIB_OPTIONS "")

    # list of all the include directories
    set(GLOBAL_INCLUDES "")
    set(GLOBAL_DEFINITION "")

    set(GLOBAL_COMPILE_OPTIONS "")
    set(GLOBAL_COMPILE_FLAGS "")

    # list of the language flags
    set(GLOBAL_C_FLAGS "")
    set(GLOBAL_CXX_FLAGS "")
    set(GLOBAL_FORTRAN_FLAGS "")

    set(temp_library_target_list "")

    set(header_exts ".h;.hh;.hpp;.h++;.hxx;.txt")
    set(exclude_exts ".md;.txt")
    
    set(WORK_DIR "${CMAKE_CURRENT_BINARY_DIR}/${LLVM_IR_OUTPUT_DIR}/${TRGT}")
    if(NOT EXISTS "${WORK_DIR}")
        file(MAKE_DIRECTORY "${WORK_DIR}" RESULT_VARIABLE result)
    else()
        set(result "")  # Empty string means success
    endif()

    if("${result}" STREQUAL "")
        # Directory created successfully or already exists
        # message(STATUS "Created directory: ${WORK_DIR}")
    else()
        message(FATAL_ERROR 
            "[llvm_generate_ir_target]: failed to create directory ${WORK_DIR}: ${result}"
        )
    endif()

    foreach(dep_trgt ${DEP_TRGTS})
        # get the properties of the target
        get_property(LOCAL_FILES TARGET ${dep_trgt} PROPERTY SOURCES)
        get_property(LOCAL_LINK_FLAGS TARGET ${dep_trgt} PROPERTY LINK_FLAGS)
        get_property(LOCAL_LINK_LIBRARIES
            TARGET ${dep_trgt}
            PROPERTY LINK_LIBRARIES
        )
        # remove the depend targets from the link libraries
        set(dep_targets_list ${DEP_TRGTS})

        # Check if library is in dependency list
        set(NEW_LINK_LIBRARIES "")
        foreach(lib ${LOCAL_LINK_LIBRARIES})
            if(NOT "${lib}" IN_LIST dep_targets_list)
                list(APPEND NEW_LINK_LIBRARIES "${lib}")
            endif()
        endforeach()

        list(APPEND temp_library_target_list ${NEW_LINK_LIBRARIES})

        # compile definitions
        llvmir_extract_compile_defs_properties(LOCAL_DEFS ${dep_trgt})

        # include
        llvmir_extract_include_dirs_properties(LOCAL_INCLUDES ${dep_trgt})

        # compile std flags, i.e. -std=c++11
        llvmir_extract_standard_flags(LOCAL_CXX_STD_FLAGS ${dep_trgt} CXX)
        llvmir_extract_standard_flags(LOCAL_C_STD_FLAGS ${dep_trgt} C)
        llvmir_extract_standard_flags(LOCAL_FORTRAN_STD_FLAGS ${dep_trgt} Fortran)

        # compile options
        llvmir_extract_compile_option_properties(
            LOCAL_COMPILE_OPTIONS ${dep_trgt})

        # compile flags
        llvmir_extract_compile_flags(LOCAL_COMPILE_FLAGS ${dep_trgt})

        # compile lang flags
        llvmir_extract_lang_flags(LOCAL_C_FLAGS C)
        llvmir_extract_lang_flags(LOCAL_CXX_FLAGS CXX)
        llvmir_extract_lang_flags(LOCAL_FORTRAN_FLAGS Fortran)

        # extract library related properties
        # extract library related properties
        llvmir_extract_library_linking(
            LOCAL_LIB_LINKING "${NEW_LINK_LIBRARIES}")
        llvmir_extract_library_compile_option(
            LOCAL_LIB_OPT "${NEW_LINK_LIBRARIES}")
        llvmir_extract_library_include(
            LOCAL_LIB_INCLUDE "${NEW_LINK_LIBRARIES}")

        set(temp_include "")
        set(excluded_files "")

        # Find all header files in the source
        foreach(IN_FILE ${LOCAL_FILES})
            # Get file extension
            get_filename_component(FILE_EXT "${IN_FILE}" EXT)
            # Get directory path
            get_filename_component(FILE_DIR "${IN_FILE}" DIRECTORY)
            
            # Convert extension to lowercase
            string(TOLOWER "${FILE_EXT}" FILE_EXT_LOWER)
            
            # Check if it's a header file
            list(FIND header_exts "${FILE_EXT_LOWER}" header_index)
            if(header_index GREATER -1)
                list(REMOVE_ITEM LOCAL_FILES "${IN_FILE}")
                list(APPEND temp_include "-I${FILE_DIR}")
            endif()

            # Check if it's an excluded file
            list(FIND exclude_exts "${FILE_EXT_LOWER}" exclude_index)
            if(exclude_index GREATER -1)
                list(APPEND excluded_files "${IN_FILE}")
            endif()
        endforeach()

        if(temp_include)
            list(REMOVE_DUPLICATES temp_include)
            list(APPEND LOCAL_INCLUDES ${temp_include})
            list(REMOVE_DUPLICATES LOCAL_INCLUDES)
        endif()

        if(excluded_files AND LOCAL_FILES)
            list(REMOVE_DUPLICATES excluded_files)
            list(REMOVE_ITEM LOCAL_FILES ${excluded_files})
        else()
            message(STATUS "No files to exclude")
        endif()

        list(APPEND GLOBAL_INCLUDES ${LOCAL_INCLUDES})
        list(APPEND GLOBAL_DEFINITION ${LOCAL_DEFS})
        list(APPEND GLOBAL_COMPILE_OPTIONS ${LOCAL_COMPILE_OPTIONS})
        list(APPEND GLOBAL_COMPILE_FLAGS ${LOCAL_COMPILE_FLAGS})
        
        catuniq(LOCAL_C_FLAGS ${LOCAL_C_STD_FLAGS} ${LOCAL_C_FLAGS})
        catuniq(LOCAL_CXX_FLAGS ${LOCAL_CXX_STD_FLAGS} ${LOCAL_CXX_FLAGS})
        catuniq(LOCAL_FORTRAN_FLAGS ${LOCAL_FORTRAN_STD_FLAGS} ${LOCAL_FORTRAN_FLAGS})

        list(APPEND GLOBAL_C_FLAGS ${LOCAL_C_FLAGS})
        list(APPEND GLOBAL_CXX_FLAGS ${LOCAL_CXX_FLAGS})
        list(APPEND GLOBAL_FORTRAN_FLAGS ${LOCAL_FORTRAN_FLAGS})

        list(APPEND GLOBAL_LIB_LINKINGS ${LOCAL_LIB_LINKING})
        list(APPEND GLOBAL_LIB_INCLUDES ${LOCAL_LIB_INCLUDE})
        list(APPEND GLOBAL_LIB_OPTIONS ${LOCAL_LIB_OPT})        
    endforeach()

    list(REMOVE_DUPLICATES GLOBAL_INCLUDES)
    list(REMOVE_DUPLICATES GLOBAL_DEFINITION)
    list(REMOVE_DUPLICATES GLOBAL_COMPILE_OPTIONS)
    list(REMOVE_DUPLICATES GLOBAL_COMPILE_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_C_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_CXX_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_FORTRAN_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_LIB_LINKINGS)
    list(REMOVE_DUPLICATES GLOBAL_LIB_INCLUDES)
    list(REMOVE_DUPLICATES GLOBAL_LIB_OPTIONS)
    list(REMOVE_DUPLICATES temp_library_target_list)

    set(new_temp_library_target_list "")

    foreach(lib ${temp_library_target_list})
        if(TARGET ${lib})
            list(APPEND new_temp_library_target_list ${lib})
        endif()
    endforeach()

    set(temp_library_target_list ${new_temp_library_target_list})

    message(STATUS "GLOBAL_INCLUDES: ${GLOBAL_INCLUDES}")
    message(STATUS "GLOBAL_DEFINITION: ${GLOBAL_DEFINITION}")
    message(STATUS "GLOBAL_COMPILE_OPTIONS: ${GLOBAL_COMPILE_OPTIONS}")
    message(STATUS "GLOBAL_COMPILE_FLAGS: ${GLOBAL_COMPILE_FLAGS}")
    message(STATUS "GLOBAL_C_FLAGS: ${GLOBAL_C_FLAGS}")
    message(STATUS "GLOBAL_CXX_FLAGS: ${GLOBAL_CXX_FLAGS}")
    message(STATUS "GLOBAL_FORTRAN_FLAGS: ${GLOBAL_FORTRAN_FLAGS}")
    message(STATUS "GLOBAL_LIB_LINKINGS: ${GLOBAL_LIB_LINKINGS}")
    message(STATUS "GLOBAL_LIB_INCLUDES: ${GLOBAL_LIB_INCLUDES}")
    message(STATUS "GLOBAL_LIB_OPTIONS: ${GLOBAL_LIB_OPTIONS}")
    message(STATUS "temp_library_target_list: ${temp_library_target_list}")


    # all the properties are set, now we can generate the IR
    foreach(dep_trgt ${DEP_TRGTS})
        set(TARGET_WORKDIR ${WORK_DIR}/${dep_trgt})
        if(NOT EXISTS "${TARGET_WORKDIR}")
            file(MAKE_DIRECTORY "${TARGET_WORKDIR}" result)
        else()
            set(result "")
        endif()
        if("${result}" STREQUAL "")
            # Directory created successfully or already exists
            # message(STATUS "Created directory: ${WORK_DIR}")
        else()
            message(FATAL_ERROR 
                "[llvm_generate_ir_target]: failed to create directory ${WORK_DIR}: ${result}"
            )
        endif()

        get_property(LOCAL_FILES TARGET ${dep_trgt} PROPERTY SOURCES)

        foreach(file ${LOCAL_FILES})
            cmake_path(GET file FILENAME filename)
            cmake_path(GET file STEM stem)
            # Get file extension
            get_filename_component(file_ext "${file}" EXT)
            # Convert extension to lowercase
            string(TOLOWER "${file_ext}" file_ext_lower)


            # Check if it's a header file
            list(FIND header_exts "${file_ext_lower}" header_index)
            if(header_index GREATER -1)
                continue()
            endif()

            # Check if it's an excluded file
            list(FIND exclude_exts "${file_ext_lower}" exclude_index)
            if(exclude_index GREATER -1)
                continue()
            endif()

            # get the relative path of the file
            cmake_path(RELATIVE_PATH file 
               BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
               OUTPUT_VARIABLE rel_path)
            if(rel_path)
                cmake_path(REMOVE_FILENAME rel_path OUTPUT_VARIABLE dir)
                set(FILE_WORKDIR ${TARGET_WORKDIR}/${dir})
                if(NOT EXISTS "${FILE_WORKDIR}")
                    file(MAKE_DIRECTORY "${FILE_WORKDIR}" result)
                else()
                    set(result "")
                endif()
                if("${result}" STREQUAL "")
                    # Directory created successfully or already exists
                    # message(STATUS "Created directory: ${WORK_DIR}")
                else()
                    message(FATAL_ERROR 
                        "[llvm_generate_ir_target]: failed to create directory ${WORK_DIR}: ${result}"
                    )
                endif()
            else()
                set(FILE_WORKDIR ${TARGET_WORKDIR})
            endif()

            set(OUTPUT_FILENAME "${stem}.ll")
            set(OUTPUT_FILEPATH "${FILE_WORKDIR}/${OUTPUT_FILENAME}")
            list(APPEND OUTPUT_LLVM_IR_FILE_PATHS ${OUTPUT_FILEPATH})
            list(APPEND GLOBAL_SOURCES ${file})

            # get the compiler for the file
            llvmir_extract_file_lang(FILE_LANG ${file_ext_lower})
            set(FILE_COMPILER ${LLVM_${FILE_LANG}_COMPILER})
            set(FILE_LANG_FLAGS ${GLOBAL_${FILE_LANG}_FLAGS})

            set(FILE_COMPILE_CMD "-emit-llvm" "-S" ${FILE_LANG_FLAGS}
                ${GLOBAL_COMPILE_OPTIONS} ${GLOBAL_COMPILE_FLAGS}
                ${GLOBAL_DEFINITION} ${GLOBAL_INCLUDES}
                ${GLOBAL_LIB_INCLUDES} ${GLOBAL_LIB_OPTIONS}
                ${GLOBAL_LIB_LINKINGS}
            )

            # add custom command to compile the file
            add_custom_command(OUTPUT ${OUTPUT_FILEPATH}
                COMMAND ${FILE_COMPILER} ${FILE_COMPILE_CMD} ${file} 
                    -o ${OUTPUT_FILEPATH} 
                    ${LLVM_GENERATE_ADDITIONAL_COMMANDS}
                DEPENDS ${file} ${temp_library_target_list}
                COMMENT "Generating LLVM IR for ${file} with command:"
                    "${FILE_COMPILER} ${FILE_COMPILE_CMD} ${file} -o "
                    "${OUTPUT_FILEPATH} ${LLVM_GENERATE_ADDITIONAL_COMMANDS}"
                VERBATIM
            )
        endforeach()

    endforeach()

    # add custom target to generate the IR
    add_custom_target(${TRGT} ALL DEPENDS ${OUTPUT_LLVM_IR_FILE_PATHS})

    set_property(TARGET ${TRGT} PROPERTY LLVM_TYPE ${LLVM_LL_TYPE})
    set_property(TARGET ${TRGT} PROPERTY LLVM_SOURCE_FILES ${GLOBAL_SOURCES})
    set_property(TARGET ${TRGT} 
        PROPERTY LLVM_GENERATED_FILES ${OUTPUT_LLVM_IR_FILE_PATHS})
    set_property(TARGET ${TRGT} PROPERTY LLVM_CUSTOM_OUTPUT_DIR ${WORK_DIR})

    # setup the properties to carry forward
    set_property(TARGET ${TRGT} PROPERTY INCLUDES ${GLOBAL_INCLUDES})
    set_property(TARGET ${TRGT} PROPERTY DEFINITION ${GLOBAL_DEFINITION})
    set_property(TARGET ${TRGT} PROPERTY COMPILE_OPTIONS ${GLOBAL_COMPILE_OPTIONS})
    set_property(TARGET ${TRGT} PROPERTY COMPILE_FLAGS ${GLOBAL_COMPILE_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY C_FLAGS ${GLOBAL_C_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY CXX_FLAGS ${GLOBAL_CXX_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY FORTRAN_FLAGS ${GLOBAL_FORTRAN_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKINGS ${GLOBAL_LIB_LINKINGS})
    set_property(TARGET ${TRGT} PROPERTY LIB_INCLUDES ${GLOBAL_LIB_INCLUDES})
    set_property(TARGET ${TRGT} PROPERTY LIB_OPTIONS ${GLOBAL_LIB_OPTIONS})

endfunction()
