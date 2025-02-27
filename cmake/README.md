# Helper CMake Utils

Here contains all the CMake functions that can help to perform the Nugget methodology.

--- 

Below is a comprehensive Markdown documentation for the [Nugget.cmake](https://github.com/studyztp/nugget_util/blob/main/cmake/Nugget.cmake) module from the nugget_util project. This document details its purpose, prerequisites, provided functions, usage examples, troubleshooting tips, and contribution guidelines.

---

# Nugget.cmake Documentation

`Nugget.cmake` is a CMake module provided by the [nugget_util](https://github.com/studyztp/nugget_util) project. It defines a suite of custom CMake functions that streamline the process of generating, linking, profiling, and compiling LLVM bitcode for projects requiring instrumentation and region-based performance analysis.

> **Note:** This module is designed to work in an environment where LLVM (Clang, opt, llc) is available and where supporting modules (such as `LLVMIRUtil`, `NuggetInternal`, and `CMakeParseArguments`) have been properly included.

---

## Table of Contents

- [Helper CMake Utils](#helper-cmake-utils)
- [Nugget.cmake Documentation](#nuggetcmake-documentation)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
  - [Provided Functions](#provided-functions)
    - [nugget\_bbv\_profiling\_bc](#nugget_bbv_profiling_bc)
    - [nugget\_naive\_bc](#nugget_naive_bc)
    - [nugget\_nugget\_bc](#nugget_nugget_bc)
    - [nugget\_compile\_exe](#nugget_compile_exe)
  - [Usage Examples](#usage-examples)
  - [Troubleshooting](#troubleshooting)
  - [Contributing](#contributing)
  - [License](#license)

---

## Overview

The `Nugget.cmake` module is designed to support the following tasks:

- **LLVM IR Generation:**  
  Extract source file information (compile definitions, include directories, compiler flags, etc.) from one or more dependent targets and generate LLVM IR files accordingly.

- **Bitcode Linking and Optimization:**  
  Link generated IR files into bitcode targets, and apply LLVM optimization passes (such as phase-analysis) to produce profiling-enhanced bitcode.

- **Executable Compilation:**  
  Compile the optimized bitcode (and optionally, extract specific functions) into object files and ultimately link them into an executable binary.

The module defines several functions that are intended to be used sequentially or as needed, to integrate profiling instrumentation and code transformation into your CMake build process.

---

## Prerequisites

Before using `Nugget.cmake`, ensure that:

- **LLVM Toolchain:**  
  A working LLVM toolchain (Clang, opt, llc) is installed and accessible in your system's PATH.

- **CMake Version:**  
  Your project is using a CMake version that supports the features utilized in these functions (typically CMake 3.10 or higher).

- **Supporting Modules:**  
  The following modules must be available in your CMake module path:
  - `LLVMIRUtil`
  - `NuggetInternal`
  - `CMakeParseArguments`

- **Target Properties:**  
  Dependent targets (passed as `DEPEND_TARGETS`) must have their `SOURCES` property defined.

---

## Provided Functions

### nugget_bbv_profiling_bc

**Purpose:**  
Generates profiling bitcode that instruments basic block information by:
- Generating LLVM IR for both a hook target and source targets.
- Converting the generated IR to bitcode.
- Linking the bitcode targets.
- Applying an optimization pass (e.g., phase-analysis) to produce profiling data.

**Key Parameters:**
- **TARGET** (required): Base name for the output target.
- **REGION_LENGTH** (required): The region length used for phase-analysis.
- **BB_INFO_OUTPUT_PATH** (optional): Path to output the basic block information (defaults to `basic_block_info_output.txt` if not specified).
- **HOOK_TARGET** (required): Target used to generate hook IR.
- **DEPEND_TARGETS** (required): One or more source targets whose IR will be generated.
- **EXTRA_FLAGS, EXTRA_INCLUDES, EXTRA_LIB_PATHS, EXTRA_LIBS** (optional): Additional options for IR generation and linking.

**Usage Example:**
```cmake
nugget_bbv_profiling_bc(
    TARGET myProfiledTarget
    REGION_LENGTH 100
    HOOK_TARGET myHookTarget
    DEPEND_TARGETS sourceTarget1 sourceTarget2
    EXTRA_FLAGS "-O2"
    EXTRA_INCLUDES "/path/to/includes"
    EXTRA_LIB_PATHS "/path/to/libs"
    EXTRA_LIBS "mylib"
)
```

---

### nugget_naive_bc

**Purpose:**  
Creates a bitcode target from either pre-built bitcode files or by generating IR from dependent targets. It handles:
- Optionally using pre-generated bitcode files if provided.
- Otherwise, generating IR from source and hook targets, converting it to bitcode, and then linking the results.

**Key Parameters:**
- **TARGET** (required): Base name for the output target.
- **HOOK_TARGET** (required): Target for generating hook IR.
- **SOURCE_BC_FILE_PATH** (optional): Path to pre-generated source bitcode.
- **HOOK_BC_FILE_PATH** (optional): Path to pre-generated hook bitcode.
- **DEPEND_TARGETS** (required): List of source targets.
- **EXTRA_FLAGS, EXTRA_INCLUDES, EXTRA_LIB_PATHS, EXTRA_LIBS** (optional): Additional options.

**Usage Example:**
```cmake
nugget_naive_bc(
    TARGET myNaiveTarget
    HOOK_TARGET myHookTarget
    DEPEND_TARGETS sourceTarget1
    SOURCE_BC_FILE_PATH "/path/to/source.bc"
    HOOK_BC_FILE_PATH "/path/to/hook.bc"
)
```

---

### nugget_nugget_bc

**Purpose:**  
Generates a combined "nugget" bitcode target by:
- Linking source and hook bitcode targets.
- Applying phase-bound optimizations with optional labeling.
- Creating markers for each region based on basic block analysis.

**Key Parameters:**
- **TARGET** (required): Base name for the nugget target.
- **HOOK_TARGET** (required): Target for hook IR.
- **SOURCE_BC_FILE_PATH** (required): Path to the source bitcode file.
- **INPUT_FILE_DIR** (required): Directory containing input files for phase-bound processing.
- **INPUT_FILE_NAME_BASE** (required): Base name for input files.
- **BB_INFO_INPUT_PATH** (required): Path to basic block information input.
- **BB_INFO_OUTPUT_DIR** (optional): Output directory for basic block information (default is set to a subdirectory in the binary directory).
- **LABEL_TARGET, LABEL_WARMUP** (optional): Parameters for labeling during phase-bound analysis.
- **DEPEND_TARGETS** (required): List of dependent source targets.
- **ALL_NUGGET_RIDS** (required): List of nugget region IDs.
- **EXTRA_FLAGS, EXTRA_INCLUDES, EXTRA_LIB_PATHS, EXTRA_LIBS** (optional): Additional options.
- **HOOK_BC_FILE_PATH** (optional): Pre-generated hook bitcode file.

**Usage Example:**
```cmake
nugget_nugget_bc(
    TARGET myNuggetTarget
    HOOK_TARGET myHookTarget
    SOURCE_BC_FILE_PATH "/path/to/source.bc"
    INPUT_FILE_DIR "/input/dir"
    INPUT_FILE_NAME_BASE "input_base"
    BB_INFO_INPUT_PATH "/path/to/bb_info.txt"
    ALL_NUGGET_RIDS rid1 rid2
    EXTRA_FLAGS "-O3"
)
```

---

### nugget_compile_exe

**Purpose:**  
Compiles an executable from bitcode by:
- Determining the appropriate bitcode target (either from a provided file or generated from dependent targets).
- Optionally extracting or deleting specific functions.
- Applying additional optimization commands.
- Converting bitcode to object files (using `llc`) if necessary.
- Finally, linking the object files into an executable.

**Key Parameters:**
- **TARGET** (required): Name of the final executable target.
- **BC_FILE_PATH** (optional): Path to a pre-generated bitcode file.
- **DEPEND_TARGETS** (required): List of dependent targets.
- **ADDITIONAL_OPT** (optional): Additional optimization command(s).
- **EXTRA_FLAGS, EXTRA_INCLUDES, EXTRA_LIB_PATHS, EXTRA_LIBS** (optional): Additional compile options.
- **LLC_CMD** (optional): Custom command-line options for `llc`.
- **EXTRACT_FUNCTIONS** (optional): List of functions to extract from the bitcode.
- **FINAL_BC_FILE_PATHS** (optional): List of final bitcode file paths for handling multiple targets.

**Usage Example:**
```cmake
nugget_compile_exe(
    TARGET myFinalExecutable
    DEPEND_TARGETS target1 target2
    BC_FILE_PATH "/path/to/final.bc"
    LLC_CMD "llc -march=x86-64"
    EXTRA_FLAGS "-O2"
    EXTRA_LIBS "pthread"
)
```

---

## Usage Examples

Below is an example of how to integrate `Nugget.cmake` into your CMake project:

```cmake
cmake_minimum_required(VERSION 3.10)
project(MyNuggetProject)

# Update CMake module path to include Nugget.cmake and its dependencies.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
include(Nugget.cmake)

# Define source targets.
add_library(sourceTarget1 STATIC src/source1.cpp)
add_library(sourceTarget2 STATIC src/source2.cpp)
add_library(myHookTarget STATIC src/hook.cpp)

# Generate profiling bitcode.
nugget_bbv_profiling_bc(
    TARGET myProfiledTarget
    REGION_LENGTH 100
    HOOK_TARGET myHookTarget
    DEPEND_TARGETS sourceTarget1 sourceTarget2
    EXTRA_FLAGS "-O2"
)

# Generate naive bitcode.
nugget_naive_bc(
    TARGET myNaiveTarget
    HOOK_TARGET myHookTarget
    DEPEND_TARGETS sourceTarget1
    SOURCE_BC_FILE_PATH "/path/to/source.bc"
    HOOK_BC_FILE_PATH "/path/to/hook.bc"
)

# Create a nugget bitcode target.
nugget_nugget_bc(
    TARGET myNuggetTarget
    HOOK_TARGET myHookTarget
    SOURCE_BC_FILE_PATH "/path/to/source.bc"
    INPUT_FILE_DIR "/input/dir"
    INPUT_FILE_NAME_BASE "input_base"
    BB_INFO_INPUT_PATH "/path/to/bb_info.txt"
    ALL_NUGGET_RIDS rid1 rid2
    EXTRA_FLAGS "-O3"
)

# Compile the final executable.
nugget_compile_exe(
    TARGET myFinalExecutable
    DEPEND_TARGETS myNaiveTarget myProfiledTarget
    BC_FILE_PATH "/path/to/final.bc"
    LLC_CMD "llc -march=x86-64"
    EXTRA_FLAGS "-O2"
    EXTRA_LIBS "pthread"
)
```

---

## Troubleshooting

- **Missing Required Arguments:**  
  If any required parameter (e.g., `TARGET`, `DEPEND_TARGETS`) is omitted, a fatal error will be raised. Verify that all necessary parameters are provided.

- **LLVM Environment:**  
  Errors regarding LLVM setup indicate that the LLVM toolchain might not be correctly configured. Ensure that Clang, opt, and llc are accessible.

- **File and Directory Issues:**  
  Check that all file paths (for bitcode, CSV, etc.) exist and that the necessary directories can be created in your binary directory.

---

## Contributing

Contributions to enhance the Nugget.cmake module are welcome. To contribute:
1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Submit a pull request with a detailed description of your changes.
4. Include updates to documentation and tests as needed.

---

## License

This module is part of the [nugget_util](https://github.com/studyztp/nugget_util) project and is distributed under the same license as the main repository. Refer to the [LICENSE](https://github.com/studyztp/nugget_util/blob/main/LICENSE) file for more details.

---

This documentation is intended to serve as a comprehensive guide for developers using the functions defined in `Nugget.cmake`. For further details or issues, please refer to the [GitHub repository](https://github.com/studyztp/nugget_util). 

Feel free to update or expand upon this documentation as the module evolves.