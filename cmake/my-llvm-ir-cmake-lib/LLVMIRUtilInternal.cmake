# internal utility macros/functions

include(CMakeParseArguments)

function(debug message_txt)
    if($ENV{LLVMIR_CMAKE_DEBUG})
        message(STATUS "[DEBUG] ${message_txt}")
    endif()
endfunction()

macro(catuniq lst)
    list(APPEND ${lst} ${ARGN})
    if(${lst})
        list(REMOVE_DUPLICATES ${lst})
    endif()
endmacro()

macro(llvmir_setup)
    set(LLVM_SETUP_DONE TRUE)
    # if the output directories are not defined, set the default values
    if (NOT DEFINED LLVM_IR_OUTPUT_DIR)
        set(LLVM_IR_OUTPUT_DIR "llvm-ir")
    endif()

    if (NOT DEFINED LLVM_BC_OUTPUT_DIR)
        set(LLVM_BC_OUTPUT_DIR "llvm-bc")
    endif()

    if (NOT DEFINED LLVM_EXECUTABLE_OUTPUT_DIR)
        set(LLVM_EXECUTABLE_OUTPUT_DIR "llvm-exec")
    endif()

    # LLVM BIN indicates where to find the LLVM executables
    if (NOT DEFINED LLVM_BIN)
        set(LLVM_BIN "")
    endif()

    # if not defined, set the default values for where to find 
    # the LLVM executables
    if (NOT DEFINED LLVM_C_COMPILER)
        set(LLVM_C_COMPILER ${LLVM_BIN}/clang)
    endif()

    if (NOT DEFINED LLVM_CXX_COMPILER)
        set(LLVM_CXX_COMPILER ${LLVM_BIN}/clang++)
    endif()

    if (NOT DEFINED LLVM_Fortran_COMPILER)
        set(LLVM_Fortran_COMPILER ${LLVM_BIN}/flang-new)
    endif()

    if (NOT DEFINED LLVM_OPT)
        set(LLVM_OPT ${LLVM_BIN}/opt)
    endif()

    if (NOT DEFINED LLVM_LLC)
        set(LLVM_LLC ${LLVM_BIN}/llc)
    endif()

    if (NOT DEFINED LLVM_LINK)
        set(LLVM_LINK ${LLVM_BIN}/llvm-link)
    endif()

    if (NOT DEFINED LLVM_ASSEMBLER)
        set(LLVM_ASSEMBLER ${LLVM_BIN}/llvm-as)
    endif()

    if (NOT DEFINED LLVM_DISASSEMBLER)
        set(LLVM_DISASSEMBLER ${LLVM_BIN}/llvm-dis)
    endif()

    # set the final compiler for the project
    if (NOT DEFINED LLVM_FINAL_COMPILER)
        set(LLVM_FINAL_COMPILER "")
        set(LLVM_FINAL_COMPILER_LANG "")
    endif()

    # set the suffix for LLVM IR files
    set(LLVM_BC_FILE_SUFFIX "bc")
    set(LLVM_LL_FILE_SUFFIX "ll")
    set(LLVM_OBJ_FILE_SUFFIX "o")

    # This library creates three types of files:
    # 1. LLVM bitcode files (.bc)
    # 2. LLVM IR text files (.ll)
    # 3. LLVM object files (.o)
    set(LLVM_BC_TYPE "LLVM_BC")
    set(LLVM_LL_TYPE "LLVM_LL")
    set(LLVM_OBJ_TYPE "LLVM_OBJ")

    # set macro to allow us to track the types of files
    set(LLVM_TYPES ${LLVMIR_BC_TYPE} ${LLVMIR_LL_TYPE} ${LLVMIR_OBJ_TYPE})
    set(LLVM_SUFFICES ${LLVM_BC_FILE_SUFFIX} ${LLVM_LL_FILE_SUFFIX} ${LLVM_OBJ_FILE_SUFFIX})

    # I copied this from the original llvm-ir-cmake-utils library
    set(LLVM_COMPILER_IDS "Clang" "AppleClang")

    message(STATUS "LLVM IR Utils setup")

    # define properties for the target
    define_property(TARGET PROPERTY LLVM_TYPE
        BRIEF_DOCS "type of LLVM files"
        FULL_DOCS "type of LLVM files that can be generated by this library")
    define_property(TARGET PROPERTY LLVM_CUSTOM_OUTPUT_DIR
        BRIEF_DOCS "custom output directory for LLVM files"
        FULL_DOCS "custom output directory for LLVM files")
    define_property(TARGET PROPERTY LLVM_SOURCE_FILES
        BRIEF_DOCS "list of the source files ([original sources], .ll, .bc, .o)"
        FULL_DOCS "list of LLVM source files ([original sources], .ll, .bc, .o)")
    define_property(TARGET PROPERTY LLVM_GENERATED_FILES
        BRIEF_DOCS "list of the generated files (.ll, .bc, .o)"
        FULL_DOCS "list of the generated files (.ll, .bc, .o)")

    # define properties to carry over flags
    define_property(TARGET PROPERTY INCLUDE
        BRIEF_DOCS "include directories"
        FULL_DOCS "include directories for the target")
    define_property(TARGET PROPERTY DEFINITION
        BRIEF_DOCS "definitions"
        FULL_DOCS "definitions for the target")
    define_property(TARGET PROPERTY COMPILE_OPTIONS
        BRIEF_DOCS "compile options"
        FULL_DOCS "compile options for the target")
    define_property(TARGET PROPERTY COMPILE_FLAGS
        BRIEF_DOCS "compile flags"
        FULL_DOCS "compile flags for the target")
    define_property(TARGET PROPERTY C_FLAGS
        BRIEF_DOCS "C flags"
        FULL_DOCS "C flags for the target")
    define_property(TARGET PROPERTY CXX_FLAGS
        BRIEF_DOCS "C++ flags"
        FULL_DOCS "C++ flags for the target") 
    define_property(TARGET PROPERTY Fortran_FLAGS
        BRIEF_DOCS "Fortran flags"
        FULL_DOCS "Fortran flags for the target")
    define_property(TARGET PROPERTY LIB_LINKING_LIB_PATH
        BRIEF_DOCS "library linking paths, i.e. -L"
        FULL_DOCS "library linking paths for the target")
    define_property(TARGET PROPERTY LIB_LINKING_LIBS
        BRIEF_DOCS "library linking libraries, i.e. -l or absolute path"
        FULL_DOCS "library linking libraries for the target")
    define_property(TARGET PROPERTY LIB_INCLUDES
        BRIEF_DOCS "library includes"
        FULL_DOCS "library includes for the target")
    define_property(TARGET PROPERTY LIB_OPTIONS
        BRIEF_DOCS "library compile options"
        FULL_DOCS "library compile options for the target")
    
endmacro()

macro(llvmir_set_final_compiler lang)
    set(COMPILER ${LLVM_${lang}_COMPILER})
    set(LLVM_FINAL_COMPILER ${COMPILER})
    set(LLVM_FINAL_COMPILER_LANG ${lang})
endmacro()

function(llvmir_extract_compile_defs_properties out_compile_defs from)
  set(defs "")
  set(compile_defs "")
  set(prop_name "COMPILE_DEFINITIONS")

  # per directory
  get_property(defs DIRECTORY PROPERTY ${prop_name})
  foreach(def ${defs})
    list(APPEND compile_defs -D${def})
  endforeach()

  get_property(defs DIRECTORY PROPERTY ${prop_name}_${CMAKE_BUILD_TYPE})
  foreach(def ${defs})
    list(APPEND compile_defs -D${def})
  endforeach()

  # per target
  if(TARGET ${from})
    get_property(defs TARGET ${from} PROPERTY ${prop_name})
    foreach(def ${defs})
      list(APPEND compile_defs -D${def})
    endforeach()

    get_property(defs TARGET ${from} PROPERTY ${prop_name}_${CMAKE_BUILD_TYPE})
    foreach(def ${defs})
      list(APPEND compile_defs -D${def})
    endforeach()

    get_property(defs TARGET ${from} PROPERTY INTERFACE_${prop_name})
    foreach(def ${defs})
      list(APPEND compile_defs -D${def})
    endforeach()
  else()
    # per file
    get_property(defs SOURCE ${from} PROPERTY ${prop_name})
    foreach(def ${defs})
      list(APPEND compile_defs -D${def})
    endforeach()

    get_property(defs SOURCE ${from} PROPERTY ${prop_name}_${CMAKE_BUILD_TYPE})
    foreach(def ${defs})
      list(APPEND compile_defs -D${def})
    endforeach()
  endif()

  list(REMOVE_DUPLICATES compile_defs)

  debug("@llvmir_extract_compile_defs_properties ${from}: ${compile_defs}")

  set(${out_compile_defs} ${compile_defs} PARENT_SCOPE)
endfunction()

function(llvmir_extract_compile_option_properties out_compile_options trgt)
  set(options "")
  set(compile_options "")
  set(prop_name "COMPILE_OPTIONS")

  # per directory
  get_property(options DIRECTORY PROPERTY ${prop_name})
  foreach(opt ${options})
    list(APPEND compile_options ${opt})
  endforeach()

  # per target
  get_property(options TARGET ${trgt} PROPERTY ${prop_name})
  foreach(opt ${options})
    list(APPEND compile_options ${opt})
  endforeach()

  get_property(options TARGET ${trgt} PROPERTY INTERFACE_${prop_name})
  foreach(opt ${options})
    list(APPEND compile_options ${opt})
  endforeach()

  list(REMOVE_DUPLICATES compile_options)

  debug("@llvmir_extract_compile_option_properties ${trgt}: ${compile_options}")

  set(${out_compile_options} ${compile_options} PARENT_SCOPE)
endfunction()

function(llvmir_extract_include_dirs_properties out_include_dirs trgt)
  set(dirs "")
  set(prop_name "INCLUDE_DIRECTORIES")

  # per directory
  get_property(dirs DIRECTORY PROPERTY ${prop_name})
  foreach(dir ${dirs})
    list(APPEND include_dirs -I${dir})
  endforeach()

  # per target
  get_property(dirs TARGET ${trgt} PROPERTY ${prop_name})
  foreach(dir ${dirs})
    list(APPEND include_dirs -I${dir})
  endforeach()

  get_property(dirs TARGET ${trgt} PROPERTY INTERFACE_${prop_name})
  foreach(dir ${dirs})
    list(APPEND include_dirs -I${dir})
  endforeach()

  get_property(dirs TARGET ${trgt} PROPERTY INTERFACE_SYSTEM_${prop_name})
  foreach(dir ${dirs})
    list(APPEND include_dirs -I${dir})
  endforeach()

  if(include_dirs)
    list(REMOVE_DUPLICATES include_dirs)
  endif()

  debug("@llvmir_extract_include_dirs_properties ${trgt}: ${include_dirs}")

  set(${out_include_dirs} ${include_dirs} PARENT_SCOPE)
endfunction()

function(llvmir_extract_lang_flags out_lang_flags lang)
  set(lang_flags "")

  set(lang_flags ${CMAKE_${lang}_FLAGS})
  set(lang_flags "${lang_flags} ${CMAKE_${lang}_FLAGS_${CMAKE_BUILD_TYPE}}")

  string(REPLACE "\ " ";" lang_flags ${lang_flags})

  debug("@llvmir_extract_lang_flags ${lang}: ${lang_flags}")

  set(${out_lang_flags} ${lang_flags} PARENT_SCOPE)
endfunction()

function(llvmir_extract_standard_flags out_standard_flags trgt lang)
  set(standard_flags "")
  set(std_prop "${lang}_STANDARD")
  set(ext_prop "${lang}_EXTENSIONS")

  get_property(std TARGET ${trgt} PROPERTY ${std_prop})
  get_property(ext TARGET ${trgt} PROPERTY ${ext_prop})

  set(lang_prefix "")

  if(std)
    if(${lang} STREQUAL "Fortran")
      # Handle Fortran standards differently
      if(ext)
        set(lang_prefix "gnu")
      else()
        set(lang_prefix "f")
      endif()
      # Map Fortran standard years to compiler flags
      if(std EQUAL "95")
        set(std "95")
      elseif(std EQUAL "2003")
        set(std "03")
      elseif(std EQUAL "2008")
        set(std "08")
      elseif(std EQUAL "2018")
        set(std "18")
      endif()
    else()
      # Original C/C++ handling
      if(ext)
        set(lang_prefix "gnu")
      else()
        string(TOLOWER ${lang} lang_prefix)
      endif()
      if(lang_prefix STREQUAL "cxx")
        set(lang_prefix "c++")
      endif()
    endif()
  endif()
  
  set(flag "${lang_prefix}${std}")

  if(flag)
    set(standard_flags "-std=${flag}")
  endif()

  debug("@llvmir_extract_standard_flags ${lang}: ${standard_flags}")

  set(${out_standard_flags} ${standard_flags} PARENT_SCOPE)
endfunction()


function(llvmir_extract_compile_flags out_compile_flags from)
  set(compile_flags "")
  set(prop_name "COMPILE_FLAGS")

  if(TARGET ${from})
    get_property(compile_flags TARGET ${from} PROPERTY ${prop_name})
  else()
    get_property(compile_flags SOURCE ${from} PROPERTY ${prop_name})
  endif()

  # deprecated according to cmake docs
  if(NOT "${compile_flags}" STREQUAL "")
    message(WARNING "COMPILE_FLAGS property is deprecated.")
  endif()

  debug("@llvmir_extract_compile_flags ${from}: ${compile_flags}")

  set(${out_compile_flags} ${compile_flags} PARENT_SCOPE)
endfunction()

function(llvmir_extract_library_include out_include link_libs)
  set(all_include "")

  foreach(lib ${link_libs})
    if(TARGET ${lib})
      get_property(include_dirs TARGET ${lib} PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
      foreach(dir ${include_dirs})
        if(dir MATCHES "\\$<BUILD_INTERFACE:([^>]+)>")
          # Fixed: using dir instead of path in the pattern match
          set(BUILD_PATH "${CMAKE_MATCH_1}")
          list(APPEND all_include -I${BUILD_PATH})
        elseif(dir MATCHES "\\$<INSTALL_INTERFACE:([^>]+)>")
          # Fixed: using dir instead of path in the pattern match
          set(INSTALL_PATH "${CMAKE_MATCH_1}")
          list(APPEND all_include -I${INSTALL_PATH})
        elseif(dir MATCHES "\\$<COMPILE_LANGUAGE:([^>]+)>")
          message(WARNING "The compile language ${CMAKE_MATCH_1} is a generator.")
        else()
          list(APPEND all_include -I${dir})
        endif()
      endforeach()
    else()
      message(WARNING "Library ${lib} is not a target.")
    endif()
  endforeach()

  list(REMOVE_DUPLICATES all_include)

  debug("@llvm_extract_library_include ${trgt}: ${all_include}")

  set(${out_include} ${all_include} PARENT_SCOPE)
endfunction()

function(llvmir_extract_library_linking 
                            out_linking_lib_paths out_linking_libs link_libs)
  set(lib_paths "")
  set(libs "")
  set(static_library_types "STATIC_LIBRARY" "SHARED_LIBRARY")
  set(interface_library_types "INTERFACE_LIBRARY")

  foreach(lib ${link_libs})
    if(TARGET ${lib})
      get_property(type TARGET ${lib} PROPERTY TYPE)
      if(type IN_LIST static_library_types)
        get_property(imported_location TARGET ${lib} PROPERTY IMPORTED_LOCATION)
        if(imported_location)
          if(NOT EXISTS ${imported_location})
            message(WARNING "Library ${lib} does not exist at ${imported_location}.")
          else()
            list(APPEND libs ${imported_location})
          endif()
        else()
          get_property(binary_bin TARGET ${lib} PROPERTY BINARY_DIR)
          get_property(binary_name TARGET ${lib} PROPERTY NAME)
          list(APPEND lib_paths -L${binary_bin})
          list(APPEND libs -l${binary_name})
        endif()
      elseif(type IN_LIST interface_library_types)
        get_property(interface_link_libraries TARGET ${lib} PROPERTY INTERFACE_LINK_LIBRARIES)
        foreach(link_lib ${interface_link_libraries})
          if(NOT EXISTS ${link_lib})
            message(WARNING "Library ${link_lib} does not exists.")
          else()
            list(APPEND libs ${link_lib})
          endif()
        endforeach()
      else()
        message(WARNING "Library ${lib} is not a static or interface library.")
      endif()
    else()
      message(WARNING "Library ${lib} is not a target.")
    endif()
  endforeach()

  debug("@llvmir_extract_library_linking ${trgt}: ${all_linking}")

  set(${out_linking_lib_paths} ${lib_paths} PARENT_SCOPE)
  set(${out_linking_libs} ${libs} PARENT_SCOPE)
endfunction()

function(llvmir_extract_library_compile_option out_lib_opt link_libs)
  set(lib_opt "")

  foreach(lib ${link_libs})
    if(TARGET ${lib})
      get_property(opt TARGET ${lib} PROPERTY INTERFACE_COMPILE_OPTIONS)
      if (opt MATCHES "\\$<COMPILE_LANGUAGE:([^>]+)>")
        if(opt MATCHES "\\$<\\$<COMPILE_LANGUAGE:([^>]+)>:([^>]+)>")
          if("${CMAKE_MATCH_1}" STREQUAL "CXX")
            # Extract the actual flag (removing SHELL: if present)
            string(REGEX REPLACE "^SHELL:" "" actual_flag "${CMAKE_MATCH_2}")
            list(APPEND lib_opt ${actual_flag})
            message(WARNING "The compile language ${CMAKE_MATCH_1} is a generator. The compile option ${actual_flag} is added to compile options.")
          endif()
        endif()
      else()
        list(APPEND lib_opt ${opt})
      endif()
    else()
      message(WARNING "Library ${lib} is not a target.")
    endif()
  endforeach()

  debug("@llvmir_extract_library_compile_option ${target}: ${lib_opt}")

  set(${out_lib_opt} ${lib_opt} PARENT_SCOPE)
endfunction()

function(llvmir_extract_file_lang out_lang file_ext)
  set(lang "")

  set(cxx_extensions ".cpp" ".cc" ".cxx" ".c++" ".C")
  set(fortran_extensions ".f" ".F" ".f90" ".F90" ".f95" ".F95" ".f03" ".F03" ".f08" ".F08")
  set(c_extensions ".c")

  # Fallback for older CMake versions
  list(FIND cxx_extensions "${file_ext}" cxx_idx)
  list(FIND fortran_extensions "${file_ext}" fortran_idx)
  list(FIND c_extensions "${file_ext}" c_idx)

  if(NOT ${cxx_idx} EQUAL -1)
    set(lang "CXX")
  elseif(NOT ${fortran_idx} EQUAL -1)
    set(lang "Fortran")
  elseif(NOT ${c_idx} EQUAL -1)
    set(lang "C")
  else()
    message(FATAL_ERROR "Unknown file extension ${file_ext}.")
  endif()

  debug("@llvmir_extract_file_lang ${file_ext}: ${lang}")

  set(${out_lang} ${lang} PARENT_SCOPE)
endfunction()

function(print_target_properties target)
    if(NOT TARGET ${target})
        message(STATUS "There is no target '${target}'")
        return()
    endif()

    message(STATUS "Properties for target '${target}':")
    
    # Get all properties that can exist
    execute_process(
        COMMAND cmake --help-property-list
        OUTPUT_VARIABLE CMAKE_PROPERTY_LIST
    )
    
    # Convert the list into a CMake list
    string(REGEX REPLACE "[\r\n]+" ";" CMAKE_PROPERTY_LIST "${CMAKE_PROPERTY_LIST}")

    foreach(prop ${CMAKE_PROPERTY_LIST})
        string(REPLACE "<CONFIG>" "${CMAKE_BUILD_TYPE}" prop ${prop})
        
        # Fix https://stackoverflow.com/questions/32197663/how-can-i-remove-the-property-debuggercommand-from-the-list-of-properties-when-i
        if(prop STREQUAL "LOCATION" OR prop MATCHES "^LOCATION_" OR prop MATCHES "_LOCATION$")
            continue()
        endif()
        
        get_property(propval TARGET ${target} PROPERTY ${prop} SET)
        if(propval)
            get_target_property(propval ${target} ${prop})
            if(propval)
                message(STATUS "  ${prop} = ${propval}")
            endif()
        endif()
    endforeach()
    
    message(STATUS "End of properties for '${target}'")
endfunction()

function(check_lang_flag_works_with_llvm_compiler flag lang result)
    # Create a clean temporary directory for testing the flag
    set(test_dir "${CMAKE_BINARY_DIR}/CMakeFiles/FlagTest")
    file(MAKE_DIRECTORY "${test_dir}" RESULT_VARIABLE make_dir_result)
    if(NOT "${make_dir_result}" STREQUAL "")
        message(FATAL_ERROR "Failed to create test directory: ${make_dir_result}")
    endif()

    # Create appropriate test source file based on language
    if(${lang} STREQUAL "CXX")
        set(src_file "${test_dir}/test.cpp")
        file(WRITE "${src_file}" "int main() { return 0; }\n")
    elseif(${lang} STREQUAL "C")
        set(src_file "${test_dir}/test.c")
        file(WRITE "${src_file}" "int main() { return 0; }\n")
    elseif(${lang} STREQUAL "Fortran")
        set(src_file "${test_dir}/test.f90")
        file(WRITE "${src_file}" "program test\nend program\n")
    else()
        message(FATAL_ERROR "Unsupported language: ${lang}")
    endif()

    # Execute compiler directly to test the flag
    execute_process(
        COMMAND ${LLVM_${lang}_COMPILER} ${flag} -c ${src_file} -o "${test_dir}/test.o"
        WORKING_DIRECTORY ${test_dir}
        RESULT_VARIABLE compile_result
        OUTPUT_VARIABLE compile_output
        ERROR_VARIABLE compile_output
    )

    # Check compilation result
    if(compile_result EQUAL 0)
        debug("Flag ${flag} works for ${lang}")
        set(${result} TRUE PARENT_SCOPE)
    else()
        debug("Flag ${flag} does not work for ${lang}: ${compile_output}")
        set(${result} FALSE PARENT_SCOPE)
    endif()

    # Clean up test directory
    file(REMOVE_RECURSE ${test_dir})
endfunction()

