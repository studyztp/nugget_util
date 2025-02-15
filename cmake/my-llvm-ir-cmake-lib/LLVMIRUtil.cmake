#.rst:
#LLVM-IR-Util
# -------------
#
# LLVM IR utils for cmake

cmake_minimum_required(VERSION 3.30.3)

include(CMakeParseArguments)

include(LLVMIRUtilInternal)

function(llvm_generate_ir_target)
    # Generate LLVM IR for specified targets and combine their properties.
    #
    # This function processes source files from dependent targets to generate
    # LLVM IR files. Each source file is compiled separately to maintain proper
    # dependency tracking and IR generation.
    #
    # Usage:
    #   llvm_generate_ir_target(
    #       TARGET <target-name>
    #       DEPEND_TARGETS <target1> [<target2> ...]
    #       [ADDITIONAL_COMMANDS <cmd1> [<cmd2> ...]]
    #   )
    #
    # The function combines and applies the following properties from all 
    # dependent targets:
    # * Include directories
    # * Compile definitions
    # * Compile options and flags
    # * Language-specific flags (C/C++/Fortran)
    # * Library dependencies and their properties
    #
    # Note: Generated IR files are not automatically linked. Use LLVM tools
    # for IR linking if needed.
    #
    # Arguments:
    #   TARGET              - Name of the output target containing generated IR
    # files
    #   DEPEND_TARGETS      - List of targets whose sources will be compiled to
    # IR
    #   ADDITIONAL_COMMANDS - (Optional) Extra compiler flags for IR generation

    # List of options without values (boolean flags)
    set(options)

    # Arguments that take exactly one value
    # TARGET: Name of the output IR target to be generated
    set(oneValueArgs TARGET)

    # Arguments that can take multiple values
    # DEPEND_TARGETS: List of CMake targets to generate IR from
    # ADDITIONAL_COMMANDS: Extra compiler flags to be appended to each compile command
    set(multiValueArgs 
        DEPEND_TARGETS 
        EXTRA_FLAGS 
        EXTRA_INCLUDES 
        EXTRA_LIB_PATHS
        EXTRA_LIBS)

    # Parse the function arguments
    cmake_parse_arguments(LLVM_GENERATE 
        "${options}" 
        "${oneValueArgs}" 
        "${multiValueArgs}" 
        ${ARGN}
    )

    set(TRGT ${LLVM_GENERATE_TARGET})
    set(DEP_TRGTS ${LLVM_GENERATE_DEPEND_TARGETS})
    set(ADD_FLAGS ${LLVM_GENERATE_EXTRA_FLAGS})
    set(ADD_INCLUDES ${LLVM_GENERATE_EXTRA_INCLUDES})
    set(ADD_LIB_PATHS ${LLVM_GENERATE_EXTRA_LIB_PATHS})
    set(ADD_LIBS ${LLVM_GENERATE_EXTRA_LIBS})

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
                "llvm_generate_ir_target: missing SOURCES property for target "
                "${dep_trgt}"
            )
        endif()
    endforeach()

    # setup global lists to store the properties of all targets

    # list of all the source files
    set(GLOBAL_SOURCES "")
    # list of all the generated IR files
    set(OUTPUT_LLVM_IR_FILE_PATHS "")

    # list of all the library properties
    # list of all the library paths, i.e. -L<lib-path>
    set(GLOBAL_LIB_LINKING_LIB_PATHS "")
    # list of all the libraries, i.e. -l<lib-path>
    set(GLOBAL_LIB_LINKING_LIBS "")
    # list of all the library includes, i.e. -I<lib-path>
    set(GLOBAL_LIB_INCLUDES "")
    # list of all the library options, i.e. -fopenmp
    set(GLOBAL_LIB_OPTIONS "")

    # list of all the include directories
    set(GLOBAL_INCLUDES "")
    # list of all the compile definitions
    set(GLOBAL_DEFINITION "")

    # list of all the compile options
    set(GLOBAL_COMPILE_OPTIONS "")
    # list of all the compile flags
    set(GLOBAL_COMPILE_FLAGS "")

    # list of the language flags, i.e. -std=c++11, -O3
    set(GLOBAL_C_FLAGS "")
    set(GLOBAL_CXX_FLAGS "")
    set(GLOBAL_Fortran_FLAGS "")

    # list of all the library targets that the final target will be dependent 
    # on
    set(temp_library_target_list "")

    # will exclude all the header file from the source files but make sure to
    # include the header files in the include directories
    set(header_exts ".h;.hh;.hpp;.h++;.hxx;.txt")
    # will exclude all the files with these extensions
    set(exclude_exts ".md;.txt")
    
    # the work directory where the IR files will be generated
    set(WORK_DIR "${CMAKE_CURRENT_BINARY_DIR}/${LLVM_IR_OUTPUT_DIR}/${TRGT}")
    if(NOT EXISTS "${WORK_DIR}")
        file(MAKE_DIRECTORY "${WORK_DIR}")
        if(NOT EXISTS "${WORK_DIR}")
            message(FATAL_ERROR 
                "[llvm_generate_ir_target]: failed to create directory ${WORK_DIR}"
            )
        endif()
    endif()

    foreach(dep_trgt ${DEP_TRGTS})
        # get the properties of the target
        get_property(LOCAL_FILES TARGET ${dep_trgt} PROPERTY SOURCES)
        get_property(LOCAL_LINK_FLAGS TARGET ${dep_trgt} PROPERTY LINK_FLAGS)
        # all the libraries that are linked to this target, i.e. using 
        # target_link_libraries
        get_property(LOCAL_LINK_LIBRARIES
            TARGET ${dep_trgt}
            PROPERTY LINK_LIBRARIES
        )
        
        # we will remove all the targets in the dependency list from the
        # link libraries list because we will be generating the IR for them
        # and we don't want to link them again
        set(dep_targets_list ${DEP_TRGTS})
        # Check if library is in dependency list
        set(NEW_LINK_LIBRARIES "")
        foreach(lib ${LOCAL_LINK_LIBRARIES})
            if(NOT "${lib}" IN_LIST dep_targets_list)
                list(APPEND NEW_LINK_LIBRARIES "${lib}")
            endif()
        endforeach()
        list(APPEND temp_library_target_list ${NEW_LINK_LIBRARIES})

        # extract compile definitions, i.e. -D<def>
        llvmir_extract_compile_defs_properties(LOCAL_DEFS ${dep_trgt})

        # extract include directories, i.e. -I<dir>
        llvmir_extract_include_dirs_properties(LOCAL_INCLUDES ${dep_trgt})

        # compiler std flags, i.e. -std=c++11
        llvmir_extract_standard_flags(LOCAL_CXX_STD_FLAGS ${dep_trgt} CXX)
        llvmir_extract_standard_flags(LOCAL_C_STD_FLAGS ${dep_trgt} C)
        llvmir_extract_standard_flags(LOCAL_Fortran_STD_FLAGS ${dep_trgt} Fortran)

        # compile options
        llvmir_extract_compile_option_properties(
            LOCAL_COMPILE_OPTIONS ${dep_trgt})

        # compile flags
        llvmir_extract_compile_flags(LOCAL_COMPILE_FLAGS ${dep_trgt})

        # compile lang flags, i.e. -O3
        llvmir_extract_lang_flags(LOCAL_C_FLAGS C)
        llvmir_extract_lang_flags(LOCAL_CXX_FLAGS CXX)
        llvmir_extract_lang_flags(LOCAL_Fortran_FLAGS Fortran)

        # extract library related properties
        llvmir_extract_library_linking(
            LOCAL_LIB_LINKING_LIB_PATHS 
            LOCAL_LIB_LINKING_LIBS "${NEW_LINK_LIBRARIES}")
        llvmir_extract_library_compile_option(
            LOCAL_LIB_OPT "${NEW_LINK_LIBRARIES}")
        llvmir_extract_library_include(
            LOCAL_LIB_INCLUDE "${NEW_LINK_LIBRARIES}")

        set(temp_include "")
        set(excluded_files "")

        # Find all header files and excluded files in the source
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
                # remove the header file from the source files
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
        endif()

        list(APPEND GLOBAL_INCLUDES ${LOCAL_INCLUDES})
        list(APPEND GLOBAL_DEFINITION ${LOCAL_DEFS})
        list(APPEND GLOBAL_COMPILE_OPTIONS ${LOCAL_COMPILE_OPTIONS})
        list(APPEND GLOBAL_COMPILE_FLAGS ${LOCAL_COMPILE_FLAGS})
        
        # combine the language flags
        catuniq(LOCAL_C_FLAGS ${LOCAL_C_STD_FLAGS} ${LOCAL_C_FLAGS})
        catuniq(LOCAL_CXX_FLAGS ${LOCAL_CXX_STD_FLAGS} ${LOCAL_CXX_FLAGS})
        catuniq(LOCAL_Fortran_FLAGS ${LOCAL_Fortran_STD_FLAGS} ${LOCAL_Fortran_FLAGS})
        
        # add the linekr flags to library linkings
        catuniq(LOCAL_LIB_OPT ${LOCAL_LIB_OPT} ${LOCAL_LINK_FLAGS})

        list(APPEND GLOBAL_C_FLAGS ${LOCAL_C_FLAGS})
        list(APPEND GLOBAL_CXX_FLAGS ${LOCAL_CXX_FLAGS})
        list(APPEND GLOBAL_Fortran_FLAGS ${LOCAL_Fortran_FLAGS})

        list(APPEND GLOBAL_LIB_LINKING_LIB_PATHS ${LOCAL_LIB_LINKING_LIB_PATHS})
        list(APPEND GLOBAL_LIB_LINKING_LIBS ${LOCAL_LIB_LINKING_LIBS})
        list(APPEND GLOBAL_LIB_INCLUDES ${LOCAL_LIB_INCLUDE})
        list(APPEND GLOBAL_LIB_OPTIONS ${LOCAL_LIB_OPT})        
    endforeach()

    list(REMOVE_DUPLICATES GLOBAL_INCLUDES)
    list(REMOVE_DUPLICATES GLOBAL_DEFINITION)
    list(REMOVE_DUPLICATES GLOBAL_COMPILE_OPTIONS)
    list(REMOVE_DUPLICATES GLOBAL_COMPILE_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_C_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_CXX_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_Fortran_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_LIB_LINKING_LIB_PATHS)
    list(REMOVE_DUPLICATES GLOBAL_LIB_LINKING_LIBS)
    list(REMOVE_DUPLICATES GLOBAL_LIB_INCLUDES)
    list(REMOVE_DUPLICATES GLOBAL_LIB_OPTIONS)
    list(REMOVE_DUPLICATES temp_library_target_list)

    set(new_temp_library_target_list "")

    # check if the library targets are valid, if not, remove them from the list
    # of dependencies
    foreach(lib ${temp_library_target_list})
        if(TARGET ${lib})
            list(APPEND new_temp_library_target_list ${lib})
        endif()
    endforeach()

    set(temp_library_target_list ${new_temp_library_target_list})

    # from here we will check if the flags are supported by the LLVM compilers,
    # if not, we will remove them from the list
    set(temp_list "")

    foreach(flag ${GLOBAL_C_FLAGS})
        check_lang_flag_works_with_llvm_compiler(${flag} C result)
        if(${result})
            list(APPEND temp_list ${flag})
        else()
            message(WARNING "Flag ${flag} is not supported by the LLVM Clang")
        endif()
    endforeach()

    set(GLOBAL_C_FLAGS ${temp_list})

    set(temp_list "")

    foreach(flag ${GLOBAL_CXX_FLAGS})
        check_lang_flag_works_with_llvm_compiler(${flag} CXX result)
        if(${result})
            list(APPEND temp_list ${flag})
        else()
            message(WARNING "Flag ${flag} is not supported by the LLVM Clang++")
        endif()
    endforeach()

    set(GLOBAL_CXX_FLAGS ${temp_list})

    set(temp_list "")

    foreach(flag ${GLOBAL_Fortran_FLAGS})
        check_lang_flag_works_with_llvm_compiler(${flag} Fortran result)
        if(${result})
            list(APPEND temp_list ${flag})
        else()
            message(WARNING "Flag ${flag} is not supported by the LLVM Flang")
        endif()
    endforeach()

    set(GLOBAL_Fortran_FLAGS ${temp_list})
    # end of checking the flags

    message(STATUS "GLOBAL_INCLUDES: ${GLOBAL_INCLUDES}")
    message(STATUS "GLOBAL_DEFINITION: ${GLOBAL_DEFINITION}")
    message(STATUS "GLOBAL_COMPILE_OPTIONS: ${GLOBAL_COMPILE_OPTIONS}")
    message(STATUS "GLOBAL_COMPILE_FLAGS: ${GLOBAL_COMPILE_FLAGS}")
    message(STATUS "GLOBAL_C_FLAGS: ${GLOBAL_C_FLAGS}")
    message(STATUS "GLOBAL_CXX_FLAGS: ${GLOBAL_CXX_FLAGS}")
    message(STATUS "GLOBAL_Fortran_FLAGS: ${GLOBAL_Fortran_FLAGS}")
    message(STATUS "GLOBAL_LIB_LINKING_LIB_PATHS: "
                                "${GLOBAL_LIB_LINKING_LIB_PATHS}")
    message(STATUS "GLOBAL_LIB_LINKING_LIBS: ${GLOBAL_LIB_LINKING_LIBS}")
    message(STATUS "GLOBAL_LIB_INCLUDES: ${GLOBAL_LIB_INCLUDES}")
    message(STATUS "GLOBAL_LIB_OPTIONS: ${GLOBAL_LIB_OPTIONS}")
    message(STATUS "temp_library_target_list: ${temp_library_target_list}")
    message(STATUS "ADD_CMDS: ${ADD_CMDS}")


    # all the properties are set, now we can generate the IR
    foreach(dep_trgt ${DEP_TRGTS})
        # each dependent target will have its own work directory to distinguish
        # the generated IR files and for better debugging
        set(TARGET_WORKDIR ${WORK_DIR}/${dep_trgt})
        if(NOT EXISTS "${TARGET_WORKDIR}")
            file(MAKE_DIRECTORY "${TARGET_WORKDIR}")
            if(NOT EXISTS "${TARGET_WORKDIR}")
                message(FATAL_ERROR 
                    "[llvm_generate_ir_target]: failed to create directory ${TARGET_WORKDIR}"
                )
            endif()
        endif()

        get_property(LOCAL_FILES TARGET ${dep_trgt} PROPERTY SOURCES)

        foreach(file ${LOCAL_FILES})
            # filename is with the extension, i.e. file.cpp
            cmake_path(GET file FILENAME filename)
            # stem is the filename without the extension, i.e. file
            cmake_path(GET file STEM stem)

            # Get file extension, i.e. .cpp
            get_filename_component(file_ext "${file}" EXT)
            # Convert extension to lowercase
            string(TOLOWER "${file_ext}" file_ext_lower)


            # Check if it's a header file
            list(FIND header_exts "${file_ext_lower}" header_index)
            if(header_index GREATER -1)
                # skip header files
                continue()
            endif()

            # Check if it's an excluded file
            list(FIND exclude_exts "${file_ext_lower}" exclude_index)
            if(exclude_index GREATER -1)
                # skip excluded files
                continue()
            endif()

            # get the relative path of the file, i.e. src/file.cpp
            cmake_path(RELATIVE_PATH file 
               BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
               OUTPUT_VARIABLE rel_path)
            if(rel_path)
                # If the file has a relative path (e.g., "src/core/file.cpp"),
                # create a matching directory structure in the output 
                # directory. 
                # This preserves the source tree organization and prevents name
                # conflicts when multiple files have the same name but live in 
                # different directories.
                cmake_path(REMOVE_FILENAME rel_path OUTPUT_VARIABLE dir)
                set(FILE_WORKDIR ${TARGET_WORKDIR}/${dir})
                if(NOT EXISTS "${FILE_WORKDIR}")
                    file(MAKE_DIRECTORY "${FILE_WORKDIR}")
                    if(NOT EXISTS "${FILE_WORKDIR}")
                        message(FATAL_ERROR 
                            "[llvm_generate_ir_target]: "
                            "failed to create directory ${FILE_WORKDIR}"
                        )
                    endif()
                endif()
            else()
                set(FILE_WORKDIR ${TARGET_WORKDIR})
            endif()

            # set the output filename with .ll extension
            set(OUTPUT_FILENAME "${stem}.${LLVM_LL_FILE_SUFFIX}")
            set(OUTPUT_FILEPATH "${FILE_WORKDIR}/${OUTPUT_FILENAME}")
            # add the generated IR file to the list
            list(APPEND OUTPUT_LLVM_IR_FILE_PATHS ${OUTPUT_FILEPATH})
            list(APPEND GLOBAL_SOURCES ${file})

            # get the language of the file, i.e. C, CXX, Fortran
            llvmir_extract_file_lang(FILE_LANG ${file_ext_lower})
            set(FILE_COMPILER ${LLVM_${FILE_LANG}_COMPILER})
            set(FILE_LANG_FLAGS ${GLOBAL_${FILE_LANG}_FLAGS})

            # set the compile command for the file
            set(FILE_COMPILE_CMD "-emit-llvm" "-S" ${FILE_LANG_FLAGS}
                ${GLOBAL_COMPILE_OPTIONS} ${GLOBAL_COMPILE_FLAGS} 
                ${ADD_FLAGS}
                ${GLOBAL_DEFINITION} ${GLOBAL_INCLUDES} ${ADD_INCLUDES}
                ${GLOBAL_LIB_INCLUDES} ${GLOBAL_LIB_OPTIONS} 
                ${GLOBAL_LIB_LINKING_LIB_PATHS}
                ${ADD_LIB_PATHS}
                ${GLOBAL_LIB_LINKING_LIBS} ${ADD_LIBS} 
            )

            # add custom command to compile the file
            # in here, we add the dependencies of the libraries that the target
            # is dependent on so that the libraries will be built before the
            # IR generation
            add_custom_command(OUTPUT ${OUTPUT_FILEPATH}
                COMMAND ${FILE_COMPILER} ${FILE_COMPILE_CMD} ${file} 
                    -o ${OUTPUT_FILEPATH} 
                DEPENDS ${file} ${temp_library_target_list}
                COMMENT "Generating LLVM IR for ${file} with command:"
                    "${FILE_COMPILER} ${FILE_COMPILE_CMD} ${file} -o "
                    "${OUTPUT_FILEPATH} ${ADD_CMDS}"
                VERBATIM
            )
        endforeach()

    endforeach()

    # add custom target to generate the IR
    add_custom_target(${TRGT} ALL DEPENDS ${OUTPUT_LLVM_IR_FILE_PATHS})

    # set the LLVM_TYPE to LLVM_LL_TYPE
    # LLVM_LL_TYPE can be generated into LLVM_BC_TYPE and LLVM_OBJ_TYPE but
    # not LLVM_EXE_TYPE because this means it's possible for the IR files to 
    # not be linked into a single file that can be compiled into an executable
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
    set_property(TARGET ${TRGT} PROPERTY Fortran_FLAGS ${GLOBAL_Fortran_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIB_PATHS 
        ${GLOBAL_LIB_LINKING_LIB_PATHS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIBS
        ${GLOBAL_LIB_LINKING_LIBS})
    set_property(TARGET ${TRGT} PROPERTY LIB_INCLUDES ${GLOBAL_LIB_INCLUDES})
    set_property(TARGET ${TRGT} PROPERTY LIB_OPTIONS ${GLOBAL_LIB_OPTIONS})

endfunction()

function(llvm_link_ir_into_bc_target)
    # List of options without values (boolean flags)
    set(options)

    # Arguments that take exactly one value
    # TARGET: Name of the output BC target to be generated
    set(oneValueArgs TARGET)

    # Arguments that can take multiple values
    # DEPEND_TARGETS: List of CMake targets to generate BC from
    # ADDITIONAL_COMMANDS: Extra compiler flags to be appended to each compile 
    # command
    set(multiValueArgs DEPEND_TARGETS ADDITIONAL_COMMANDS)

    # Parse the function arguments
    cmake_parse_arguments(LLVM_GENERATE 
        "${options}" 
        "${oneValueArgs}" 
        "${multiValueArgs}" 
        ${ARGN}
    )

    set(TRGT ${LLVM_GENERATE_TARGET})
    set(DEP_TRGTS ${LLVM_GENERATE_DEPEND_TARGETS})
    set(ADD_CMDS ${LLVM_GENERATE_ADDITIONAL_COMMANDS})

    if(NOT TRGT)
        message(FATAL_ERROR "llvm_link_ir_into_bc_target: missing TARGET option")
    endif()

    if(NOT DEP_TRGTS)
        message(FATAL_ERROR "llvm_link_ir_into_bc_target: missing DEPENDS option")
    endif()

    # check if the necessary properties are set
    # for this function, we need the LLVM_TYPE property to be LLVM_IR_TYPE
    foreach(dep_trgt ${DEP_TRGTS})
        get_property(target_type TARGET ${dep_trgt} PROPERTY LLVM_TYPE)
        # Check if it equals LLVM_LL_TYPE
        if(NOT "${target_type}" STREQUAL "${LLVM_LL_TYPE}")
            # Property matches LLVM_LL_TYPE
            message(FATAL_ERROR "Target ${dep_trgt} is not of type LLVM_LL"
                " - cannot link IR files into BC"
                " - it is of type ${target_type}")
        endif()
    endforeach()

    # setup global lists to store the properties of all targets
    # list of all the source files, in this case, the IR files
    set(GLOBAL_SOURCES "")
    # The generated BC file
    set(OUTPUT_LLVM_BC_FILE_PATH "")

    # list of all the library properties
    # list of all the library paths, i.e. -L<lib-path>
    set(GLOBAL_LIB_LINKING_LIB_PATHS "")
    # list of all the libraries, i.e. -l<lib-path>
    set(GLOBAL_LIB_LINKING_LIBS "")
    # list of all the library includes, i.e. -I<lib-path>
    set(GLOBAL_LIB_INCLUDES "")
    # list of all the library options, i.e. -fopenmp
    set(GLOBAL_LIB_OPTIONS "")

    # list of all the include directories
    set(GLOBAL_INCLUDES "")
    # list of all the compile definitions
    set(GLOBAL_DEFINITION "")

    # list of all the compile options
    set(GLOBAL_COMPILE_OPTIONS "")
    # list of all the compile flags
    set(GLOBAL_COMPILE_FLAGS "")

    # list of the language flags, i.e. -std=c++11, -O3
    set(GLOBAL_C_FLAGS "")
    set(GLOBAL_CXX_FLAGS "")
    set(GLOBAL_Fortran_FLAGS "")

    set(WORK_DIR "${CMAKE_CURRENT_BINARY_DIR}/${LLVM_BC_OUTPUT_DIR}/${TRGT}")
    if(NOT EXISTS "${WORK_DIR}")
        file(MAKE_DIRECTORY "${WORK_DIR}")
        if(NOT EXISTS "${WORK_DIR}")
            message(FATAL_ERROR 
                "[llvm_link_ir_into_bc_target]: failed to create directory ${WORK_DIR}"
            )
        endif()
    endif()
    set(OUTPUT_FILENAME "${TRGT}.${LLVM_BC_FILE_SUFFIX}")
    set(OUTPUT_LLVM_BC_FILE_PATH "${WORK_DIR}/${OUTPUT_FILENAME}")

    foreach(dep_trgt ${DEP_TRGTS})
        get_property(LOCAL_LL_FILES TARGET ${dep_trgt} 
            PROPERTY LLVM_GENERATED_FILES)
        get_property(LOCAL_INCLUDES TARGET ${dep_trgt} PROPERTY INCLUDES)
        get_property(LOCAL_DEFINITION TARGET ${dep_trgt} PROPERTY DEFINITION)
        get_property(LOCAL_COMPILE_OPTIONS TARGET ${dep_trgt} 
            PROPERTY COMPILE_OPTIONS)
        get_property(LOCAL_COMPILE_FLAGS TARGET ${dep_trgt} 
            PROPERTY COMPILE_FLAGS)
        get_property(LOCAL_C_FLAGS TARGET ${dep_trgt} PROPERTY C_FLAGS)
        get_property(LOCAL_CXX_FLAGS TARGET ${dep_trgt} PROPERTY CXX_FLAGS)
        get_property(LOCAL_Fortran_FLAGS TARGET ${dep_trgt} 
            PROPERTY Fortran_FLAGS)
        get_property(LOCAL_LIB_LINKING_LIB_PATHS TARGET ${dep_trgt} 
            PROPERTY LIB_LINKING_LIB_PATHS)
        get_property(LOCAL_LIB_LINKING_LIBS TARGET ${dep_trgt}
            PROPERTY LIB_LINKING_LIBS)
        get_property(LOCAL_LIB_INCLUDES TARGET ${dep_trgt} 
            PROPERTY LIB_INCLUDES)
        get_property(LOCAL_LIB_OPTIONS TARGET ${dep_trgt} PROPERTY LIB_OPTIONS)

        catuniq(GLOBAL_SOURCES ${LOCAL_LL_FILES} ${GLOBAL_SOURCES})
        catuniq(GLOBAL_INCLUDES ${LOCAL_INCLUDES} ${GLOBAL_INCLUDES})
        catuniq(GLOBAL_DEFINITION ${LOCAL_DEFINITION} ${GLOBAL_DEFINITION})
        catuniq(GLOBAL_COMPILE_OPTIONS ${LOCAL_COMPILE_OPTIONS} 
            ${GLOBAL_COMPILE_OPTIONS})
        catuniq(GLOBAL_COMPILE_FLAGS ${LOCAL_COMPILE_FLAGS} 
            ${GLOBAL_COMPILE_FLAGS})
        catuniq(GLOBAL_C_FLAGS ${LOCAL_C_FLAGS} ${GLOBAL_C_FLAGS})
        catuniq(GLOBAL_CXX_FLAGS ${LOCAL_CXX_FLAGS} ${GLOBAL_CXX_FLAGS})
        catuniq(GLOBAL_Fortran_FLAGS ${LOCAL_Fortran_FLAGS} 
            ${GLOBAL_Fortran_FLAGS})
        catuniq(GLOBAL_LIB_LINKING_LIB_PATHS ${LOCAL_LIB_LINKING_LIB_PATHS} 
            ${GLOBAL_LIB_LINKING_LIB_PATHS})
        catuniq(GLOBAL_LIB_LINKING_LIBS ${LOCAL_LIB_LINKING_LIBS}
            ${GLOBAL_LIB_LINKING_LIBS})
        catuniq(GLOBAL_LIB_INCLUDES ${LOCAL_LIB_INCLUDES} 
            ${GLOBAL_LIB_INCLUDES})
        catuniq(GLOBAL_LIB_OPTIONS ${LOCAL_LIB_OPTIONS} ${GLOBAL_LIB_OPTIONS})
    endforeach()

    list(REMOVE_DUPLICATES GLOBAL_INCLUDES)
    list(REMOVE_DUPLICATES GLOBAL_DEFINITION)
    list(REMOVE_DUPLICATES GLOBAL_COMPILE_OPTIONS)
    list(REMOVE_DUPLICATES GLOBAL_COMPILE_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_C_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_CXX_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_Fortran_FLAGS)
    list(REMOVE_DUPLICATES GLOBAL_LIB_LINKING_LIB_PATHS)
    list(REMOVE_DUPLICATES GLOBAL_LIB_LINKING_LIBS)
    list(REMOVE_DUPLICATES GLOBAL_LIB_INCLUDES)
    list(REMOVE_DUPLICATES GLOBAL_LIB_OPTIONS)

    message(STATUS "GLOBAL_INCLUDES: ${GLOBAL_INCLUDES}")
    message(STATUS "GLOBAL_DEFINITION: ${GLOBAL_DEFINITION}")
    message(STATUS "GLOBAL_COMPILE_OPTIONS: ${GLOBAL_COMPILE_OPTIONS}")
    message(STATUS "GLOBAL_COMPILE_FLAGS: ${GLOBAL_COMPILE_FLAGS}")
    message(STATUS "GLOBAL_C_FLAGS: ${GLOBAL_C_FLAGS}")
    message(STATUS "GLOBAL_CXX_FLAGS: ${GLOBAL_CXX_FLAGS}")
    message(STATUS "GLOBAL_Fortran_FLAGS: ${GLOBAL_Fortran_FLAGS}")
    message(STATUS "GLOBAL_LIB_LINKING_LIB_PATHS: "
                                "${GLOBAL_LIB_LINKING_LIB_PATHS}")
    message(STATUS "GLOBAL_LIB_LINKING_LIBS: ${GLOBAL_LIB_LINKING_LIBS}")
    message(STATUS "GLOBAL_LIB_INCLUDES: ${GLOBAL_LIB_INCLUDES}")
    message(STATUS "GLOBAL_LIB_OPTIONS: ${GLOBAL_LIB_OPTIONS}")

    # add custom command to link the IR files into a single BC file
    add_custom_command(OUTPUT ${OUTPUT_LLVM_BC_FILE_PATH}
        COMMAND ${LLVM_LINK} ${GLOBAL_SOURCES} -o 
            ${OUTPUT_LLVM_BC_FILE_PATH} ${ADD_CMDS}
        DEPENDS ${GLOBAL_SOURCES}
        COMMENT "Linking LLVM IR files into BC file "
             "${OUTPUT_LLVM_BC_FILE_PATH}"
        VERBATIM
    )

    # add custom target to generate the BC file
    add_custom_target(${TRGT} ALL DEPENDS ${OUTPUT_LLVM_BC_FILE_PATH})
    # set the LLVM_TYPE to LLVM_BC_TYPE
    set_property(TARGET ${TRGT} PROPERTY LLVM_TYPE ${LLVM_BC_TYPE})
    set_property(TARGET ${TRGT} PROPERTY LLVM_SOURCE_FILES ${GLOBAL_SOURCES})
    set_property(TARGET ${TRGT} PROPERTY LLVM_CUSTOM_OUTPUT_DIR ${WORK_DIR})
    set_property(TARGET ${TRGT} 
        PROPERTY LLVM_GENERATED_FILES ${OUTPUT_LLVM_BC_FILE_PATH})
    # setup the properties to carry forward
    set_property(TARGET ${TRGT} PROPERTY INCLUDES ${GLOBAL_INCLUDES})
    set_property(TARGET ${TRGT} PROPERTY DEFINITION ${GLOBAL_DEFINITION})
    set_property(TARGET ${TRGT} 
        PROPERTY COMPILE_OPTIONS ${GLOBAL_COMPILE_OPTIONS})
    set_property(TARGET ${TRGT} PROPERTY COMPILE_FLAGS ${GLOBAL_COMPILE_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY C_FLAGS ${GLOBAL_C_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY CXX_FLAGS ${GLOBAL_CXX_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY Fortran_FLAGS ${GLOBAL_Fortran_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIB_PATHS 
        ${GLOBAL_LIB_LINKING_LIB_PATHS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIBS
        ${GLOBAL_LIB_LINKING_LIBS})
    set_property(TARGET ${TRGT} PROPERTY LIB_INCLUDES ${GLOBAL_LIB_INCLUDES})
    set_property(TARGET ${TRGT} PROPERTY LIB_OPTIONS ${GLOBAL_LIB_OPTIONS})
endfunction()

function(llvm_compile_into_executable_target)
    # List of options without values (boolean flags)
    set(options)

    # Arguments that take exactly one value
    # TARGET: Name of the output executable target to be generated
    set(oneValueArgs TARGET DEPEND_TARGET)

    # Arguments that can take multiple values
    # DEPEND_TARGETS: List of CMake targets to generate BC from
    # ADDITIONAL_COMMANDS: Extra compiler flags to be appended to each compile 
    # command
    set(multiValueArgs 
        EXTRA_FLAGS 
        EXTRA_LIB_PATHS
        EXTRA_LIBS
    )

    # Parse the function arguments
    cmake_parse_arguments(LLVM_GENERATE 
        "${options}" 
        "${oneValueArgs}" 
        "${multiValueArgs}" 
        ${ARGN}
    )

    if(LLVM_FINAL_COMPILER STREQUAL "")
        message(FATAL_ERROR 
            "llvm_compile_executable: LLVM_FINAL_COMPILER is not set"
            " - please run llvmir_set_final_compiler(lang) to set the compiler"
            " - lang, i.e. C, CXX, Fortran"
        )
    endif()

    set(TRGT ${LLVM_GENERATE_TARGET})
    set(DEP_TRGT ${LLVM_GENERATE_DEPEND_TARGET})
    set(ADD_FLAGS ${LLVM_GENERATE_EXTRA_FLAGS})
    set(ADD_INCLUDES ${LLVM_GENERATE_EXTRA_INCLUDES})
    set(ADD_LIB_PATHS ${LLVM_GENERATE_EXTRA_LIB_PATHS})
    set(ADD_LIBS ${LLVM_GENERATE_EXTRA_LIBS})

    if(NOT TRGT)
        message(FATAL_ERROR "llvm_compile_executable: missing TARGET option")
    endif()

    if(NOT DEP_TRGT)
        message(FATAL_ERROR 
            "llvm_compile_executable: missing DEPEND_TARGET option")
    endif()

    # check if the necessary properties are set
    # for this function, we need the LLVM_TYPE property to be LLVM_BC_TYPE
    # or LLVM_OBJ_TYPE
    
    get_property(target_type TARGET ${DEP_TRGT} PROPERTY LLVM_TYPE)
    # Check if it equals LLVM_BC_TYPE or LLVM_OBJ_TYPE
    if(NOT "${target_type}" STREQUAL "${LLVM_BC_TYPE}" AND
        NOT "${target_type}" STREQUAL "${LLVM_OBJ_TYPE}")
        # Property matches LLVM_BC_TYPE or LLVM_OBJ_TYPE
        message(FATAL_ERROR "Target ${DEP_TRGT} is not of type LLVM_BC"
            " or LLVM_OBJ - cannot compile executable"
            " - it is of type ${target_type}")
    endif()

    # only one target can be generated into an executable so we don't need to
    # have a list of global properties

    set(WORK_DIR "${CMAKE_CURRENT_BINARY_DIR}/${LLVM_EXE_OUTPUT_DIR}/${TRGT}")
    if(NOT EXISTS "${WORK_DIR}")
        file(MAKE_DIRECTORY "${WORK_DIR}")
        if(NOT EXISTS "${WORK_DIR}")
            message(FATAL_ERROR 
                "[llvm_compile_executable]: "
                    "failed to create directory ${WORK_DIR}"
            )
        endif()
    endif()
    set(OUTPUT_FILENAME "${TRGT}")
    set(OUTPUT_LLVM_EXE_FILE_PATH "${WORK_DIR}/${OUTPUT_FILENAME}")

    get_property(INPUT_FILE TARGET ${DEP_TRGT} PROPERTY LLVM_GENERATED_FILES)
    get_property(INCLUDE TARGET ${DEP_TRGT} PROPERTY INCLUDES)
    get_property(DEFINITION TARGET ${DEP_TRGT} PROPERTY DEFINITION)
    get_property(COMPILE_OPTIONS TARGET ${DEP_TRGT} PROPERTY COMPILE_OPTIONS)
    get_property(COMPILE_FLAGS TARGET ${DEP_TRGT} PROPERTY COMPILE_FLAGS)
    get_property(C_FLAGS TARGET ${DEP_TRGT} PROPERTY C_FLAGS)
    get_property(CXX_FLAGS TARGET ${DEP_TRGT} PROPERTY CXX_FLAGS)
    get_property(Fortran_FLAGS TARGET ${DEP_TRGT} PROPERTY Fortran_FLAGS)
    get_property(LIB_LINKING_LIB_PATHS TARGET ${DEP_TRGT} 
        PROPERTY LIB_LINKING_LIB_PATHS)
    get_property(LIB_LINKING_LIBS TARGET ${DEP_TRGT}
        PROPERTY LIB_LINKING_LIBS)
    get_property(LIB_INCLUDES TARGET ${DEP_TRGT} PROPERTY LIB_INCLUDES)
    get_property(LIB_OPTIONS TARGET ${DEP_TRGT} PROPERTY LIB_OPTIONS)
    
    set(FILE_COMPILE_CMD ${${LLVM_FINAL_COMPILER_LANG}_FLAGS} 
        ${COMPILE_OPTIONS} ${COMPILE_FLAGS} ${LIB_OPTIONS} ${ADD_FLAGS}
        ${LIB_LINKING_LIB_PATHS} ${ADD_LIB_PATHS}
        -Wl,--start-group ${LIB_LINKING_LIBS} ${ADD_LIBS} -Wl,--end-group
        )
    
    # add custom command to compile the executable
    add_custom_command(OUTPUT ${OUTPUT_LLVM_EXE_FILE_PATH}
        COMMAND ${LLVM_FINAL_COMPILER} ${INPUT_FILE} ${FILE_COMPILE_CMD}
            -o ${OUTPUT_LLVM_EXE_FILE_PATH} ${ADD_CMDS}
        DEPENDS ${INPUT_FILE}
        COMMENT "Compiling executable from ${INPUT_FILE} with command:"
            "${LLVM_FINAL_COMPILER} ${FILE_COMPILE_CMD} ${INPUT_FILE} -o "
            "${OUTPUT_LLVM_EXE_FILE_PATH} ${ADD_CMDS}"
            VERBATIM)
    
    # add custom target to generate the executable
    add_custom_target(${TRGT} ALL DEPENDS ${OUTPUT_LLVM_EXE_FILE_PATH})
    # set the LLVM_TYPE to LLVM_EXE_TYPE
    set_property(TARGET ${TRGT} PROPERTY LLVM_TYPE ${LLVM_EXE_TYPE})
    set_property(TARGET ${TRGT} PROPERTY LLVM_SOURCE_FILES ${INPUT_FILE})
    set_property(TARGET ${TRGT} PROPERTY LLVM_CUSTOM_OUTPUT_DIR ${WORK_DIR})
    set_property(TARGET ${TRGT} 
        PROPERTY LLVM_GENERATED_FILES ${OUTPUT_LLVM_EXE_FILE_PATH})
    # setup the properties to carry forward
    set_property(TARGET ${TRGT} PROPERTY INCLUDES ${INCLUDE})
    set_property(TARGET ${TRGT} PROPERTY DEFINITION ${DEFINITION})
    set_property(TARGET ${TRGT} PROPERTY COMPILE_OPTIONS ${COMPILE_OPTIONS})
    set_property(TARGET ${TRGT} PROPERTY COMPILE_FLAGS ${COMPILE_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY C_FLAGS ${C_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY CXX_FLAGS ${CXX_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY Fortran_FLAGS ${Fortran_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIB_PATHS 
        ${LIB_LINKING_LIB_PATHS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIBS
        ${LIB_LINKING_LIBS})
    set_property(TARGET ${TRGT} PROPERTY LIB_INCLUDES ${LIB_INCLUDES})
    set_property(TARGET ${TRGT} PROPERTY LIB_OPTIONS ${LIB_OPTIONS})

endfunction()

function(llvm_llc_into_obj_target)
    # List of options without values (boolean flags)
    set(options)

    # Arguments that take exactly one value
    # TARGET: Name of the output object target to be generated
    set(oneValueArgs TARGET DEPEND_TARGET)

    # Arguments that can take multiple values
    # DEPEND_TARGETS: List of CMake targets to generate BC from
    # ADDITIONAL_COMMANDS: Extra compiler flags to be appended to each compile 
    # command
    set(multiValueArgs 
        LLC_COMMAND
    )

    # Parse the function arguments
    cmake_parse_arguments(LLVM_GENERATE 
        "${options}" 
        "${oneValueArgs}" 
        "${multiValueArgs}" 
        ${ARGN}
    )

    set(TRGT ${LLVM_GENERATE_TARGET})
    set(DEP_TRGT ${LLVM_GENERATE_DEPEND_TARGET})
    set(LLC_CMD ${LLVM_GENERATE_LLC_COMMAND})

    if(NOT TRGT)
        message(FATAL_ERROR "llvm_llc_into_obj_target: missing TARGET option")
    endif()

    if(NOT DEP_TRGT)
        message(FATAL_ERROR 
            "llvm_llc_into_obj_target: missing DEPEND_TARGET option")
    endif()

    if(NOT LLC_CMD)
        message(FATAL_ERROR 
            "llvm_llc_into_obj_target: missing LLC_COMMAND option")
    endif()

    # check if the necessary properties are set
    # for this function, we need the LLVM_TYPE property to be LLVM_BC_TYPE
    get_property(target_type TARGET ${DEP_TRGT} PROPERTY LLVM_TYPE)
    # Check if it equals LLVM_BC_TYPE
    if(NOT "${target_type}" STREQUAL "${LLVM_BC_TYPE}")
        # Property matches LLVM_BC_TYPE
        message(FATAL_ERROR "Target ${DEP_TRGT} is not of type LLVM_BC"
            " - cannot compile object file"
            " - it is of type ${target_type}")
    endif()

    # only one target can be generated into an object file so we don't need to
    # have a list of global properties

    set(WORK_DIR "${CMAKE_CURRENT_BINARY_DIR}/${LLVM_OBJ_OUTPUT_DIR}/${TRGT}")
    if(NOT EXISTS "${WORK_DIR}")
        file(MAKE_DIRECTORY "${WORK_DIR}")
        if(NOT EXISTS "${WORK_DIR}")
            message(FATAL_ERROR 
                "[llvm_llc_into_obj_target]: "
                    "failed to create directory ${WORK_DIR}"
            )
        endif()
    endif()

    set(OUTPUT_FILENAME "${TRGT}.${LLVM_OBJ_FILE_SUFFIX}")
    set(OUTPUT_LLVM_OBJ_FILE_PATH "${WORK_DIR}/${OUTPUT_FILENAME}")

    get_property(INPUT_FILE TARGET ${DEP_TRGT} PROPERTY LLVM_GENERATED_FILES)
    get_property(INCLUDE TARGET ${DEP_TRGT} PROPERTY INCLUDES)
    get_property(DEFINITION TARGET ${DEP_TRGT} PROPERTY DEFINITION)
    get_property(COMPILE_OPTIONS TARGET ${DEP_TRGT} PROPERTY COMPILE_OPTIONS)
    get_property(COMPILE_FLAGS TARGET ${DEP_TRGT} PROPERTY COMPILE_FLAGS)
    get_property(C_FLAGS TARGET ${DEP_TRGT} PROPERTY C_FLAGS)
    get_property(CXX_FLAGS TARGET ${DEP_TRGT} PROPERTY CXX_FLAGS)
    get_property(Fortran_FLAGS TARGET ${DEP_TRGT} PROPERTY Fortran_FLAGS)
    get_property(LIB_LINKING_LIB_PATHS TARGET ${DEP_TRGT} 
        PROPERTY LIB_LINKING_LIB_PATHS)
    get_property(LIB_LINKING_LIBS TARGET ${DEP_TRGT}
    PROPERTY LIB_LINKING_LIBS)
    get_property(LIB_INCLUDES TARGET ${DEP_TRGT} PROPERTY LIB_INCLUDES)
    get_property(LIB_OPTIONS TARGET ${DEP_TRGT} PROPERTY LIB_OPTIONS)
    
    add_custom_command(OUTPUT ${OUTPUT_LLVM_OBJ_FILE_PATH}
        COMMAND ${LLVM_LLC} --filetype=obj ${INPUT_FILE} ${LLC_CMD} -o 
            ${OUTPUT_LLVM_OBJ_FILE_PATH}
        DEPENDS ${INPUT_FILE}
        COMMENT "Compiling object file from ${INPUT_FILE} with command:"
            "${LLVM_LLC} ${LLC_CMD} ${INPUT_FILE} -o "
            "${OUTPUT_LLVM_OBJ_FILE_PATH}"
        VERBATIM
    )

    # add custom target to generate the object file
    add_custom_target(${TRGT} ALL DEPENDS ${OUTPUT_LLVM_OBJ_FILE_PATH})
    # set the LLVM_TYPE to LLVM_OBJ_TYPE
    set_property(TARGET ${TRGT} PROPERTY LLVM_TYPE ${LLVM_OBJ_TYPE})
    set_property(TARGET ${TRGT} PROPERTY LLVM_SOURCE_FILES ${INPUT_FILE})
    set_property(TARGET ${TRGT} PROPERTY LLVM_CUSTOM_OUTPUT_DIR ${WORK_DIR})
    set_property(TARGET ${TRGT} 
        PROPERTY LLVM_GENERATED_FILES ${OUTPUT_LLVM_OBJ_FILE_PATH})

    # setup the properties to carry forward
    set_property(TARGET ${TRGT} PROPERTY INCLUDES ${INCLUDE})
    set_property(TARGET ${TRGT} PROPERTY DEFINITION ${DEFINITION})
    set_property(TARGET ${TRGT} PROPERTY COMPILE_OPTIONS ${COMPILE_OPTIONS})
    set_property(TARGET ${TRGT} PROPERTY COMPILE_FLAGS ${COMPILE_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY C_FLAGS ${C_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY CXX_FLAGS ${CXX_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY Fortran_FLAGS ${Fortran_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIB_PATHS 
        ${LIB_LINKING_LIB_PATHS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIBS
        ${LIB_LINKING_LIBS})
    set_property(TARGET ${TRGT} PROPERTY LIB_INCLUDES ${LIB_INCLUDES})
    set_property(TARGET ${TRGT} PROPERTY LIB_OPTIONS ${LIB_OPTIONS})

endfunction()

function(apply_opt_to_bc_target)
    # List of options without values (boolean flags)
    set(options)

    # Arguments that take exactly one value
    # TARGET: Name of the output BC target to be optimized
    set(oneValueArgs TARGET DEPEND_TARGET)

    # Arguments that can take multiple values
    # DEPEND_TARGETS: List of CMake targets to generate BC from
    # ADDITIONAL_COMMANDS: Extra compiler flags to be appended to each compile 
    # command
    set(multiValueArgs 
        OPT_COMMAND
    )

    # Parse the function arguments
    cmake_parse_arguments(LLVM_GENERATE 
        "${options}" 
        "${oneValueArgs}" 
        "${multiValueArgs}" 
        ${ARGN}
    )

    set(TRGT ${LLVM_GENERATE_TARGET})
    set(DEP_TRGT ${LLVM_GENERATE_DEPEND_TARGET})
    set(OPT_CMD ${LLVM_GENERATE_OPT_COMMAND})

    if(NOT TRGT)
        message(FATAL_ERROR "apply_opt_to_bc_target: missing TARGET option")
    endif()

    if(NOT DEP_TRGT)
        message(FATAL_ERROR 
            "apply_opt_to_bc_target: missing DEPEND_TARGET option")
    endif()

    if(NOT OPT_CMD)
        message(FATAL_ERROR 
            "apply_opt_to_bc_target: missing OPT_COMMAND option")
    endif()

    # check if the necessary properties are set
    # for this function, we need the LLVM_TYPE property to be LLVM_BC_TYPE
    get_property(target_type TARGET ${DEP_TRGT} PROPERTY LLVM_TYPE)
    # Check if it equals LLVM_BC_TYPE
    if(NOT "${target_type}" STREQUAL "${LLVM_BC_TYPE}")
        # Property matches LLVM_BC_TYPE
        message(FATAL_ERROR "Target ${DEP_TRGT} is not of type LLVM_BC"
            " - cannot optimize BC file"
            " - it is of type ${target_type}")
    endif()

    # only one target can be generated into an optimized BC file so we don't 
    # need to have a list of global properties

    set(WORK_DIR "${CMAKE_CURRENT_BINARY_DIR}/${LLVM_BC_OUTPUT_DIR}/${TRGT}")
    if(NOT EXISTS "${WORK_DIR}")
        file(MAKE_DIRECTORY "${WORK_DIR}")
        if(NOT EXISTS "${WORK_DIR}")
            message(FATAL_ERROR 
                "[apply_opt_to_bc_target]: "
                    "failed to create directory ${WORK_DIR}"
            )
        endif()
    endif()

    set(OUTPUT_FILENAME "${TRGT}.${LLVM_BC_FILE_SUFFIX}")
    set(OUTPUT_LLVM_BC_FILE_PATH "${WORK_DIR}/${OUTPUT_FILENAME}")

    get_property(INPUT_FILE TARGET ${DEP_TRGT} PROPERTY LLVM_GENERATED_FILES)
    get_property(INCLUDE TARGET ${DEP_TRGT} PROPERTY INCLUDES)
    get_property(DEFINITION TARGET ${DEP_TRGT} PROPERTY DEFINITION)
    get_property(COMPILE_OPTIONS TARGET ${DEP_TRGT} PROPERTY COMPILE_OPTIONS)
    get_property(COMPILE_FLAGS TARGET ${DEP_TRGT} PROPERTY COMPILE_FLAGS)
    get_property(C_FLAGS TARGET ${DEP_TRGT} PROPERTY C_FLAGS)
    get_property(CXX_FLAGS TARGET ${DEP_TRGT} PROPERTY CXX_FLAGS)
    get_property(Fortran_FLAGS TARGET ${DEP_TRGT} PROPERTY Fortran_FLAGS)
    get_property(LIB_LINKING_LIB_PATHS TARGET ${DEP_TRGT} 
        PROPERTY LIB_LINKING_LIB_PATHS)
    get_property(LIB_LINKING_LIBS TARGET ${DEP_TRGT}
    PROPERTY LIB_LINKING_LIBS)
    get_property(LIB_INCLUDES TARGET ${DEP_TRGT} PROPERTY LIB_INCLUDES)
    get_property(LIB_OPTIONS TARGET ${DEP_TRGT} PROPERTY LIB_OPTIONS)

    add_custom_command(OUTPUT ${OUTPUT_LLVM_BC_FILE_PATH}
        COMMAND ${LLVM_OPT} ${INPUT_FILE} ${OPT_CMD} -o 
            ${OUTPUT_LLVM_BC_FILE_PATH}
        DEPENDS ${INPUT_FILE}
        COMMENT "Optimizing BC file from ${INPUT_FILE} with command:"
            "${LLVM_OPT} ${OPT_CMD} ${INPUT_FILE} -o "
            "${OUTPUT_LLVM_BC_FILE_PATH}"
        VERBATIM
    )

    # add custom target to generate the optimized BC file
    add_custom_target(${TRGT} ALL DEPENDS ${OUTPUT_LLVM_BC_FILE_PATH})
    # set the LLVM_TYPE to LLVM_BC_TYPE
    set_property(TARGET ${TRGT} PROPERTY LLVM_TYPE ${LLVM_BC_TYPE})
    set_property(TARGET ${TRGT} PROPERTY LLVM_SOURCE_FILES ${INPUT_FILE})
    set_property(TARGET ${TRGT} PROPERTY LLVM_CUSTOM_OUTPUT_DIR ${WORK_DIR})
    set_property(TARGET ${TRGT} 
        PROPERTY LLVM_GENERATED_FILES ${OUTPUT_LLVM_BC_FILE_PATH})
    
    # setup the properties to carry forward
    set_property(TARGET ${TRGT} PROPERTY INCLUDES ${INCLUDE})
    set_property(TARGET ${TRGT} PROPERTY DEFINITION ${DEFINITION})
    set_property(TARGET ${TRGT} PROPERTY COMPILE_OPTIONS ${COMPILE_OPTIONS})
    set_property(TARGET ${TRGT} PROPERTY COMPILE_FLAGS ${COMPILE_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY C_FLAGS ${C_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY CXX_FLAGS ${CXX_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY Fortran_FLAGS ${Fortran_FLAGS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIB_PATHS 
        ${LIB_LINKING_LIB_PATHS})
    set_property(TARGET ${TRGT} PROPERTY LIB_LINKING_LIBS
        ${LIB_LINKING_LIBS})
    set_property(TARGET ${TRGT} PROPERTY LIB_INCLUDES ${LIB_INCLUDES})
    set_property(TARGET ${TRGT} PROPERTY LIB_OPTIONS ${LIB_OPTIONS})
endfunction()
