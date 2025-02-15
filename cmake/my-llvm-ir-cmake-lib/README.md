

llvm_generate_ir_target:
    takes in 
        TARGET the output target
        DEPEND_TARGETS the input target that is either a library or an executable that contains source code and everything needed for it to be compiled


    what this function does is that it first extract all the flags for the depend targets, then it combine all of them together to generate LLVM IR

    it removes the dependency between the targets inside depend targets

# list of all the output files and their names
    set(GLOBAL_SOURCES "")
    set(OUTPUT_LLVM_IR_FILE_PATHS "")

# list of all the dependencies
    set(GLOBAL_LIB_LINKINGS "")
    set(GLOBAL_LIB_INCLUDES "")
    set(GLOBAL_LIB_OPTIONS "")

# list of all the include directories
    set(GLOBAL_INCLUDES "")
    set(GLOBAL_DEFINITIONS "")

    set(GLOBAL_COMPILE_OPTIONS "")
    set(GLOBAL_COMPILE_FLAGS "")
    
# list of the language flags
    set(GLOBAL_C_FLAGS "")
    set(GLOBAL_CXX_FLAGS "")
    set(GLOBAL_FORTRAN_FLAGS "")


    
```


        get_property(SOURCE_DIR TARGET ${dep_trgt} PROPERTY SOURCE_DIR)

        set(TARGET_WORKDIR ${WORK_DIR}/${dep_trgt})
        file(MAKE_DIRECTORY ${TARGET_WORKDIR} result)
        if(result EQUAL 0)
            # Directory created successfully
            message(STATUS "Created directory: ${TARGET_WORKDIR}")
        else()
            message(FATAL_ERROR 
                "[llvm_generate_ir_target]:" 
                    "failed to create directory ${TARGET_WORKDIR}")
        endif()

        foreach(file ${IN_FILES})
            
            cmake_path(
                RELATIVE_PATH file 
                BASE_DIRECTORY SOURCE_DIR 
                OUTPUT_VARIABLE rel_path
            )
            cmake_path(GET file FILENAME filename)
            if(NOT rel_path)
                message(FATAL_ERROR 
                    "[llvm_generate_ir_target]: failed to get relative path")
                set(rel_path ${file})
            endif()
            cmake_path(REMOVE_FILENAME rel_path OUTPUT_VARIABLE file_dir)
            set(FILE_WORKDIR ${TARGET_WORKDIR}/${file_dir})
            file(MAKE_DIRECTORY ${FILE_WORKDIR} result)

            # make the output file path
            set(OUTPUT_FILENAME ${filename}.ll)
            set(OUTPUT_FILE_PATH ${FILE_WORKDIR}/${OUTPUT_FILENAME})

        endforeach()
```

