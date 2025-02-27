# Helper CMake Utils

Here contains all the CMake functions that can help to perform the Nugget methodology.# Nugget CMake Functions Documentation

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
