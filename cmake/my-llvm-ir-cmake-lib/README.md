Below is a Markdown document that explains how to use these functions, including details about parameters, usage examples, and prerequisites.

# Bigger Table of Contents
- [Nugget Cmake Functions Documentation](#nugget-cmake-functions-documentation)
- [LLVMIRUtil Documentation](#llvmirutil-documentation)

---

# Nugget CMake Functions Documentation

This document provides detailed information on the custom CMake functions used for LLVM IR generation, bitcode processing, optimization, and executable compilation. These functions help streamline the process of instrumenting and compiling code with LLVM utilities within a CMake-based build system.

---

## Table of Contents

- [Bigger Table of Contents](#bigger-table-of-contents)
- [Nugget CMake Functions Documentation](#nugget-cmake-functions-documentation)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Function Overview](#function-overview)
    - [nugget\_bbv\_profiling\_bc](#nugget_bbv_profiling_bc)
    - [nugget\_naive\_bc](#nugget_naive_bc)
    - [nugget\_nugget\_bc](#nugget_nugget_bc)
    - [nugget\_compile\_exe](#nugget_compile_exe)
  - [Integration Example](#integration-example)
- [LLVMIRUtil Documentation](#llvmirutil-documentation)
  - [Table of Contents](#table-of-contents-1)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites-1)
  - [Functions Overview](#functions-overview)
    - [llvm\_generate\_ir\_target](#llvm_generate_ir_target)
    - [llvm\_link\_ir\_into\_bc\_target](#llvm_link_ir_into_bc_target)
    - [llvm\_link\_bc\_targets](#llvm_link_bc_targets)
    - [apply\_opt\_to\_bc\_target](#apply_opt_to_bc_target)
    - [llvm\_llc\_into\_obj\_target](#llvm_llc_into_obj_target)
    - [llvm\_compile\_into\_executable\_target](#llvm_compile_into_executable_target)
    - [llvm\_extract\_functions\_to\_bc](#llvm_extract_functions_to_bc)
    - [llvm\_delete\_functions\_from\_bc](#llvm_delete_functions_from_bc)
  - [Helper Functions](#helper-functions)
  - [Usage Examples](#usage-examples)
  - [Troubleshooting](#troubleshooting)
  - [License](#license)

---

## Prerequisites

Before using these functions, ensure that:

- **LLVM Setup:** LLVM must be properly configured and initialized. The variable `LLVM_SETUP_DONE` should be set (typically via a call to an `llvm_setup` function) before using any of these functions.
- **Module Paths:** The custom CMake modules (e.g., `LLVMIRUtil`, `NuggetInternal`, and `CMakeParseArguments`) are available. This is usually achieved by appending your custom module path:
  ```cmake
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/my-llvm-ir-cmake-lib")
  ```
- **CMake Version:** Use a CMake version that supports the features used in these scripts (typically CMake 3.10 or higher).

---

## Function Overview

### nugget_bbv_profiling_bc

**Purpose:**  
Generates profiling bitcode that instruments basic block information. It processes LLVM IR from both source and hook targets, converts them to bitcode, links them, and then applies a phase-analysis optimization pass.

**Key Parameters:**

- **TARGET** (required):  
  The base name for the output target.
- **REGION_LENGTH** (required):  
  Region length used for phase-analysis.
- **BB_INFO_OUTPUT_PATH** (optional):  
  Output file for basic block information. Defaults to `basic_block_info_output.txt` if not specified.
- **HOOK_TARGET** (required):  
  The target to be used as the hook for generating IR.
- **DEPEND_TARGETS** (required):  
  The dependent targets (typically source targets) whose IR is used.
- **EXTRA_FLAGS**, **EXTRA_INCLUDES**, **EXTRA_LIB_PATHS**, **EXTRA_LIBS** (optional):  
  Additional flags and paths for generating IR and linking bitcode.

**Usage Example:**
```cmake
nugget_bbv_profiling_bc(
    TARGET myProfiledTarget
    REGION_LENGTH 100
    HOOK_TARGET myHookTarget
    DEPEND_TARGETS sourceTarget1 sourceTarget2
    EXTRA_FLAGS "-O2"
    EXTRA_INCLUDES "/path/to/includes"
    EXTRA_LIB_PATHS "/path/to/lib"
    EXTRA_LIBS "mylib"
)
```

---

### nugget_naive_bc

**Purpose:**  
Creates a bitcode target either from pre-built bitcode files or by generating LLVM IR and then converting it into bitcode. It handles both source and hook targets.

**Key Parameters:**

- **TARGET** (required):  
  Base name for the output target.
- **HOOK_TARGET** (required):  
  Target used to generate or supply the hook bitcode.
- **SOURCE_BC_FILE_PATH** (optional):  
  Path to a pre-generated source bitcode file. If provided, the bitcode is used directly.
- **HOOK_BC_FILE_PATH** (optional):  
  Path to a pre-generated hook bitcode file.
- **DEPEND_TARGETS** (required):  
  The source dependent targets.
- **EXTRA_FLAGS**, **EXTRA_INCLUDES**, **EXTRA_LIB_PATHS**, **EXTRA_LIBS** (optional):  
  Additional parameters for IR generation and bitcode conversion.

**Usage Example:**
```cmake
nugget_naive_bc(
    TARGET myNaiveTarget
    HOOK_TARGET myHookTarget
    DEPEND_TARGETS sourceTarget1 sourceTarget2
    SOURCE_BC_FILE_PATH "/path/to/source.bc"
    HOOK_BC_FILE_PATH "/path/to/hook.bc"
)
```

---

### nugget_nugget_bc

**Purpose:**  
Creates a "nugget" bitcode target by combining source and hook bitcode, then applies phase-bound optimizations (with optional labeling) to generate enhanced bitcode targets.

**Key Parameters:**

- **TARGET** (required):  
  Base name for the combined nugget target.
- **HOOK_TARGET** (required):  
  Target used for hook bitcode generation.
- **SOURCE_BC_FILE_PATH** (required):  
  Path to the source bitcode file.
- **HOOK_BC_FILE_PATH** (optional):  
  Path to a pre-generated hook bitcode file.
- **INPUT_FILE_DIR** (required):  
  Directory for input files used in the optimization process.
- **INPUT_FILE_NAME_BASE** (required):  
  Base name for input files.
- **BB_INFO_INPUT_PATH** (required):  
  File path for the input basic block information.
- **BB_INFO_OUTPUT_DIR** (optional):  
  Output directory for optimized basic block information. Defaults to a directory in `${CMAKE_CURRENT_BINARY_DIR}` if not provided.
- **LABEL_TARGET** (optional):  
  Label target for phase-bound analysis.
- **LABEL_WARMUP** (optional):  
  Boolean flag indicating whether to warm up labels.
- **DEPEND_TARGETS** (required):  
  Dependent source targets.
- **ALL_NUGGET_RIDS** (required):  
  List of all nugget RIDs used to generate individual optimization targets.
- **EXTRA_FLAGS**, **EXTRA_INCLUDES**, **EXTRA_LIB_PATHS**, **EXTRA_LIBS** (optional):  
  Additional parameters.

**Usage Example:**
```cmake
nugget_nugget_bc(
    TARGET myNuggetTarget
    HOOK_TARGET myHookTarget
    SOURCE_BC_FILE_PATH "/path/to/source.bc"
    INPUT_FILE_DIR "/path/to/input/dir"
    INPUT_FILE_NAME_BASE "input_base"
    BB_INFO_INPUT_PATH "/path/to/bb_info.txt"
    ALL_NUGGET_RIDS rid1 rid2 rid3
    EXTRA_FLAGS "-O3"
)
```

---

### nugget_compile_exe

**Purpose:**  
Compiles an executable from bitcode by handling function extraction, additional optimizations, and optionally converting bitcode to object files using LLC.

**Key Parameters:**

- **TARGET** (required):  
  Name of the final executable target.
- **BC_FILE_PATH** (optional):  
  Path to a pre-generated bitcode file. If not provided, the function may use dependent targets.
- **DEPEND_TARGETS** (required):  
  Dependent targets that provide source bitcode.
- **ADDITIONAL_OPT** (optional):  
  Additional optimization commands to be applied.
- **EXTRA_FLAGS**, **EXTRA_INCLUDES**, **EXTRA_LIB_PATHS**, **EXTRA_LIBS** (optional):  
  Extra compilation flags and paths.
- **LLC_CMD** (optional):  
  Custom command for the LLVM static compiler (LLC) to generate object files.
- **EXTRACT_FUNCTIONS** (optional):  
  List of functions to extract from the bitcode.
- **FINAL_BC_FILE_PATHS** (optional):  
  List of final bitcode file paths used to create separate bitcode targets.

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

## Integration Example

Below is a sample CMake configuration that demonstrates how to integrate and use the above functions:

```cmake
cmake_minimum_required(VERSION 3.10)
project(NuggetProject)

# Append the custom module path to include necessary LLVM utilities.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/my-llvm-ir-cmake-lib")

# Include custom modules.
include(LLVMIRUtil)
include(NuggetInternal)
include(CMakeParseArguments)

# Ensure LLVM is properly set up.
set(LLVM_SETUP_DONE TRUE)

# Generate profiling bitcode with instrumentation.
nugget_bbv_profiling_bc(
    TARGET myProfiledTarget
    REGION_LENGTH 50
    HOOK_TARGET myHookTarget
    DEPEND_TARGETS sourceTarget1 sourceTarget2
    EXTRA_FLAGS "-O2"
)

# Generate naive bitcode, using pre-built bitcode files.
nugget_naive_bc(
    TARGET myNaiveTarget
    HOOK_TARGET myHookTarget
    DEPEND_TARGETS sourceTarget1
    SOURCE_BC_FILE_PATH "/path/to/source.bc"
)

# Create a nugget bitcode target with phase-bound optimizations.
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

# Compile the final executable from the bitcode.
nugget_compile_exe(
    TARGET myFinalExecutable
    DEPEND_TARGETS myNaiveTarget myProfiledTarget
    BC_FILE_PATH "/path/to/final.bc"
    LLC_CMD "llc -march=x86-64"
    EXTRA_FLAGS "-O2"
)
```

Below is an extended Markdown documentation for the [LLVMIRUtil.cmake](https://github.com/studyztp/nugget_util/blob/main/cmake/my-llvm-ir-cmake-lib/LLVMIRUtil.cmake) module. This document covers not only the primary function for IR generation but also the additional functions (e.g. `llvm_link_ir_into_bc_target`) that are available in the module.

---

# LLVMIRUtil Documentation

The `LLVMIRUtil.cmake` module provides a set of functions to facilitate generating, linking, optimizing, and compiling LLVM Intermediate Representation (IR) files from CMake targets. It is designed to extract the compile properties from one or more targets and then use LLVM tools (such as Clang, opt, and llc) to produce IR and bitcode files that mimic the original build configuration.

> **Note:** This module requires CMake version 3.30.3 (or later) and depends on additional modules (e.g., `CMakeParseArguments` and `LLVMIRUtilInternal`). A proper LLVM toolchain must also be installed and available on your system.

---

## Table of Contents

- [Bigger Table of Contents](#bigger-table-of-contents)
- [Nugget CMake Functions Documentation](#nugget-cmake-functions-documentation)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Function Overview](#function-overview)
    - [nugget\_bbv\_profiling\_bc](#nugget_bbv_profiling_bc)
    - [nugget\_naive\_bc](#nugget_naive_bc)
    - [nugget\_nugget\_bc](#nugget_nugget_bc)
    - [nugget\_compile\_exe](#nugget_compile_exe)
  - [Integration Example](#integration-example)
- [LLVMIRUtil Documentation](#llvmirutil-documentation)
  - [Table of Contents](#table-of-contents-1)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites-1)
  - [Functions Overview](#functions-overview)
    - [llvm\_generate\_ir\_target](#llvm_generate_ir_target)
    - [llvm\_link\_ir\_into\_bc\_target](#llvm_link_ir_into_bc_target)
    - [llvm\_link\_bc\_targets](#llvm_link_bc_targets)
    - [apply\_opt\_to\_bc\_target](#apply_opt_to_bc_target)
    - [llvm\_llc\_into\_obj\_target](#llvm_llc_into_obj_target)
    - [llvm\_compile\_into\_executable\_target](#llvm_compile_into_executable_target)
    - [llvm\_extract\_functions\_to\_bc](#llvm_extract_functions_to_bc)
    - [llvm\_delete\_functions\_from\_bc](#llvm_delete_functions_from_bc)
  - [Helper Functions](#helper-functions)
  - [Usage Examples](#usage-examples)
  - [Troubleshooting](#troubleshooting)
  - [License](#license)

---

## Overview

The module automates the following tasks:

- **IR Generation:**  
  Compiles the source files (excluding headers and other non-compilable files) from specified targets into LLVM IR files (typically with a `.ll` extension).  
- **Property Extraction:**  
  Retrieves compile definitions, include directories, compile options, language standard flags, and library linking information from one or more CMake targets.  
- **Bitcode Linking and Optimization:**  
  Provides functions to link IR files into bitcode (.bc), combine multiple bitcode targets, apply optimization passes via LLVM’s `opt`, and even compile bitcode into object files and executables.
- **Function Extraction/Deletion:**  
  Offers utilities to extract or remove specific functions from bitcode—useful when isolating instrumentation code.

---

## Prerequisites

Before using the functions provided by this module, ensure that:

- **CMake Version:**  
  Your project uses CMake 3.30.3 or later.
- **Module Availability:**  
  The modules `CMakeParseArguments` and `LLVMIRUtilInternal` are in your module path.
- **LLVM Toolchain:**  
  LLVM (including Clang, opt, llc, etc.) is correctly installed and in your PATH.
- **Target Setup:**  
  Dependent targets must have their `SOURCES` property correctly defined.

---

## Functions Overview

### llvm_generate_ir_target

**Description:**  
Generates LLVM IR files from the source files of one or more dependent targets. This function:

- Parses required arguments such as `TARGET` and `DEPEND_TARGETS`.
- Extracts properties (include directories, compile definitions, flags, etc.) from each target.
- Constructs a working directory that mirrors the source tree.
- Adds custom commands to compile each source file (except headers or excluded files) into an IR file.

**Parameters:**

- **TARGET (required):**  
  The name of the output IR target. A dedicated working directory is created under this name.
- **DEPEND_TARGETS (required):**  
  List of CMake targets whose sources will be compiled to IR.
- **EXTRA_FLAGS (optional):**  
  Additional compiler flags to add.
- **EXTRA_INCLUDES (optional):**  
  Extra include directories.
- **EXTRA_LIB_PATHS (optional):**  
  Additional library search paths.
- **EXTRA_LIBS (optional):**  
  Additional libraries to link.

**Usage Example:**

```cmake
llvm_generate_ir_target(
  TARGET my_ir_target
  DEPEND_TARGETS target1 target2
  EXTRA_FLAGS "-O2"
  EXTRA_INCLUDES "${CMAKE_CURRENT_SOURCE_DIR}/include"
  EXTRA_LIB_PATHS "/usr/local/lib"
  EXTRA_LIBS "mylib"
)
```

---

### llvm_link_ir_into_bc_target

**Description:**  
Links one or more LLVM IR files (generated by `llvm_generate_ir_target`) into a single LLVM bitcode file (.bc). This step aggregates IR files so they can be processed as a unified bitcode target.

**Parameters:**

- **TARGET (required):**  
  Name of the output bitcode target.
- **DEPEND_TARGETS (required):**  
  List of targets (usually produced by `llvm_generate_ir_target`) whose IR files will be linked.

**Usage Example:**

```cmake
llvm_link_ir_into_bc_target(
  TARGET my_bitcode_target
  DEPEND_TARGETS my_ir_target
)
```

---

### llvm_link_bc_targets

**Description:**  
Combines multiple bitcode targets into one unified bitcode target. This is useful when you have generated bitcode from different parts of your project and wish to link them into a single file for further processing or optimization.

**Parameters:**

- **TARGET (required):**  
  The name for the final linked bitcode target.
- **DEPEND_TARGETS (required):**  
  A list of bitcode targets to be linked together.

**Usage Example:**

```cmake
llvm_link_bc_targets(
  TARGET final_bitcode
  DEPEND_TARGETS bitcode_target1 bitcode_target2
)
```

---

### apply_opt_to_bc_target

**Description:**  
Applies LLVM optimization passes (using the `opt` tool) to a bitcode target. This function runs the provided optimization commands on the given bitcode to generate an optimized version.

**Parameters:**

- **TARGET (required):**  
  The name of the output target after optimization.
- **DEPEND_TARGET (required):**  
  The bitcode target to which the optimizations are applied.
- **OPT_COMMAND (required):**  
  A list of optimization flags or passes (for example, `-passes=phase-analysis`, etc.) to apply.

**Usage Example:**

```cmake
apply_opt_to_bc_target(
  TARGET optimized_bitcode
  DEPEND_TARGET final_bitcode
  OPT_COMMAND "-passes=mem2reg;-O3"
)
```

---

### llvm_llc_into_obj_target

**Description:**  
Compiles LLVM bitcode into an object file using the LLVM static compiler (llc). This step is usually performed after optimization and before linking an executable.

**Parameters:**

- **TARGET (required):**  
  The name of the object file target.
- **DEPEND_TARGET (required):**  
  The bitcode target to compile.
- **LLC_COMMAND (required):**  
  The command-line options for llc (e.g., specifying the target architecture).

**Usage Example:**

```cmake
llvm_llc_into_obj_target(
  TARGET my_object
  DEPEND_TARGET optimized_bitcode
  LLC_COMMAND "-march=x86-64"
)
```

---

### llvm_compile_into_executable_target

**Description:**  
Links object files (or bitcode targets) into a final executable. This function aggregates all required objects, applies additional flags, and invokes the compiler/linker to produce an executable binary.

**Parameters:**

- **TARGET (required):**  
  The name of the final executable target.
- **DEPEND_TARGETS (required):**  
  A list of object targets (or bitcode targets, if linking is performed directly) to be linked.
- **EXTRA_FLAGS (optional):**  
  Additional compiler or linker flags.
- **EXTRA_LIB_PATHS (optional):**  
  Additional library search paths.
- **EXTRA_LIBS (optional):**  
  Extra libraries to link.

**Usage Example:**

```cmake
llvm_compile_into_executable_target(
  TARGET my_executable
  DEPEND_TARGETS my_object1 my_object2
  EXTRA_FLAGS "-O2"
  EXTRA_LIB_PATHS "/usr/local/lib"
  EXTRA_LIBS "pthread;ssl"
)
```

---

### llvm_extract_functions_to_bc

**Description:**  
Extracts specific functions from an existing bitcode target into a new bitcode target. This is useful when you want to isolate certain functions (for example, instrumentation or hook routines) for separate handling.

**Parameters:**

- **TARGET (required):**  
  The name of the output bitcode target containing only the extracted functions.
- **DEPEND_TARGET (required):**  
  The original bitcode target from which functions will be extracted.
- **FUNCTIONS (required):**  
  A list of function names to extract.

**Usage Example:**

```cmake
llvm_extract_functions_to_bc(
  TARGET extracted_bc
  DEPEND_TARGET full_bitcode
  FUNCTIONS "funcA" "funcB" "funcC"
)
```

---

### llvm_delete_functions_from_bc

**Description:**  
Removes specified functions from a bitcode target. This function is useful to remove unwanted or redundant code (such as hook functions) from a source bitcode target.

**Parameters:**

- **TARGET (required):**  
  The name of the new bitcode target after deletion.
- **DEPEND_TARGET (required):**  
  The original bitcode target.
- **FUNCTIONS (required):**  
  A list of function names to be removed.

**Usage Example:**

```cmake
llvm_delete_functions_from_bc(
  TARGET cleaned_bc
  DEPEND_TARGET full_bitcode
  FUNCTIONS "funcA" "funcB"
)
```

---

## Helper Functions

In addition to the main functions described above, the module relies on several helper routines (typically defined in the `LLVMIRUtilInternal` module) to extract properties from targets:

- **llvmir_extract_compile_defs_properties:**  
  Extracts compile definitions (e.g., `-D` flags).

- **llvmir_extract_include_dirs_properties:**  
  Extracts include directories (e.g., `-I` paths).

- **llvmir_extract_standard_flags:**  
  Retrieves language standard flags (e.g., `-std=c++11`) for a specified language.

- **llvmir_extract_compile_option_properties:**  
  Gathers compile options from the target.

- **llvmir_extract_compile_flags:**  
  Extracts compile flags specific to the target’s build configuration.

- **llvmir_extract_lang_flags:**  
  Extracts language-specific flags (such as optimization flags like `-O3`).

- **llvmir_extract_library_linking:**  
  Retrieves library linking information, including library paths and libraries.
  
- **llvmir_extract_library_compile_option:**  
  Extracts additional compile options related to linked libraries.
  
- **llvmir_extract_library_include:**  
  Retrieves include directories coming from library dependencies.
  
- **llvmir_extract_file_lang:**  
  Determines the language of a source file based on its file extension.

These helper functions ensure that the IR and bitcode generation processes accurately mirror the original compilation environment.

---

## Usage Examples

Below is an example integration of several functions from the module into a CMake project:

```cmake
cmake_minimum_required(VERSION 3.30.3)
project(MyLLVMProject)

# Add custom module path to locate LLVMIRUtil.cmake and related modules.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/my-llvm-ir-cmake-lib")
include(LLVMIRUtil.cmake)

# Define some targets with sources.
add_library(target1 STATIC src/target1.cpp)
add_library(target2 STATIC src/target2.cpp)

# Set output directory for LLVM IR files.
set(LLVM_IR_OUTPUT_DIR "llvm_ir")

# Generate LLVM IR files from the targets.
llvm_generate_ir_target(
  TARGET my_ir_target
  DEPEND_TARGETS target1 target2
  EXTRA_FLAGS "-O2"
  EXTRA_INCLUDES "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

# Link the generated IR files into a single bitcode target.
llvm_link_ir_into_bc_target(
  TARGET my_bitcode
  DEPEND_TARGETS my_ir_target
)

# Optionally, link multiple bitcode targets together.
llvm_link_bc_targets(
  TARGET combined_bitcode
  DEPEND_TARGETS my_bitcode another_bitcode_target
)

# Apply LLVM optimization passes to the bitcode.
apply_opt_to_bc_target(
  TARGET optimized_bitcode
  DEPEND_TARGET my_bitcode
  OPT_COMMAND "-passes=mem2reg;-O3"
)

# Compile the optimized bitcode into an object file.
llvm_llc_into_obj_target(
  TARGET my_object
  DEPEND_TARGET optimized_bitcode
  LLC_COMMAND "-march=x86-64"
)

# Link the object file(s) into a final executable.
llvm_compile_into_executable_target(
  TARGET my_executable
  DEPEND_TARGETS my_object
  EXTRA_FLAGS "-O2"
  EXTRA_LIBS "pthread"
)

# (Optional) Extract specific functions from a bitcode target.
llvm_extract_functions_to_bc(
  TARGET extracted_bc
  DEPEND_TARGET optimized_bitcode
  FUNCTIONS "hook_function"
)

# (Optional) Delete unwanted functions from a bitcode target.
llvm_delete_functions_from_bc(
  TARGET cleaned_bc
  DEPEND_TARGET optimized_bitcode
  FUNCTIONS "debug_function"
)
```

---

## Troubleshooting

- **Missing SOURCES Property:**  
  If a dependent target lacks the `SOURCES` property, `llvm_generate_ir_target` will trigger a fatal error. Verify that each target properly defines its source files.

- **Directory Creation Errors:**  
  If the working directory for IR generation cannot be created, check your write permissions and the correctness of the specified output path.

- **Unsupported Flags:**  
  The module checks for LLVM compiler flag support; unsupported flags are dropped with a warning message. Adjust your extra flags as needed.

- **Dependency Ordering:**  
  Ensure that targets specified in `DEPEND_TARGETS` are built (or defined) before invoking these functions to guarantee proper dependency tracking.

---

## License

This module is part of the [nugget_util](https://github.com/studyztp/nugget_util) project and is distributed under the same license as the main repository. See the [LICENSE](https://github.com/studyztp/nugget_util/blob/main/LICENSE) file for details.

