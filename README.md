# nugget_util — CMake Utility Library for Nugget Pipeline Integration

`nugget_util` provides CMake functions that automate the entire Nugget pipeline, making it easy to integrate Nugget's LLVM passes into any CMake-based workload build flow. Instead of manually invoking `clang`, `opt`, `llvm-link`, and `llc` for every workload, you include a single CMake file and call high-level functions that handle compilation, pass application, runtime merging, and linking.

## Quick Start

Include the utility in your `CMakeLists.txt`:

```cmake
include(/path/to/nugget_util/nugget-function.cmake)
```

Then use the pipeline functions to build instrumented executables from your existing CMake targets. See the [full pipeline example](#example-full-pipeline-in-cmake) below.

---

## Configurable Variables

Set these **before** including `nugget-function.cmake` or pass them via `-D` on the CMake command line:

| Variable | Default | Description |
|----------|---------|-------------|
| `NUGGET_C_COMPILER` | `clang` | C compiler for LLVM IR emission |
| `NUGGET_CXX_COMPILER` | `clang++` | C++ compiler for LLVM IR emission |
| `NUGGET_Fortran_COMPILER` | `flang-new` (auto-detected) | Fortran compiler for LLVM IR emission |
| `NUGGET_LLVM_LINK` | `llvm-link` | Path to `llvm-link` binary |
| `NUGGET_LLVM_OPT` | `opt` | Path to `opt` binary |
| `NUGGET_LLVM_LLC` | `llc` | Path to `llc` binary |
| `NUGGET_PROJECT_SOURCE_DIRS` | `${CMAKE_SOURCE_DIR}/src` | Semicolon-separated list of directories containing project source code. Targets whose sources are not under any of these directories are treated as external and skipped by the IR pipeline. |

Output directories are set automatically:

| Variable | Default |
|----------|---------|
| `LLVM_IR_OUTPUT_DIR` | `${CMAKE_BINARY_DIR}/llvm-ir` |
| `LLVM_BC_OUTPUT_DIR` | `${CMAKE_BINARY_DIR}/llvm-bc` |
| `LLVM_OBJ_OUTPUT_DIR` | `${CMAKE_BINARY_DIR}/llvm-obj` |
| `LLVM_EXE_OUTPUT_DIR` | `${CMAKE_BINARY_DIR}/llvm-exec` |

---

## Pipeline Functions

These are the main functions you use to build the Nugget pipeline in CMake. Each function creates a CMake custom target with properties that chain into the next stage.

### `nugget_create_bc_file`

```cmake
nugget_create_bc_file(<ORIGINAL_TARGET> <OUTPUT_TARGET> <OUT_SKIPPED_TARGETS>)
```

Compiles all source files of `ORIGINAL_TARGET` (and its in-project dependencies, recursively) to LLVM IR, then links them into a single `.bc` file using `llvm-link`. This is the entry point of the pipeline.

- Automatically determines the correct compiler (`clang`, `clang++`, or `flang-new`) for each source file based on its extension.
- Collects and validates compile flags (global CMake flags, target compile options, language standards) against the Nugget compilers, dropping any unsupported flags.
- Skips imported targets, interface libraries, and targets whose sources are outside `NUGGET_PROJECT_SOURCE_DIRS`.
- Reports skipped targets in `OUT_SKIPPED_TARGETS` so they can be linked at the final executable stage.
- Sets the `NUGGET_BC_FILE` and `NUGGET_TARGET_TYPE` properties on `OUTPUT_TARGET`.

```cmake
nugget_create_bc_file(my_app my_app_bc SKIPPED_TARGETS)
```

### `nugget_compile_hook_bc`

```cmake
nugget_compile_hook_bc(<HOOK_SOURCE> <OUTPUT_TARGET>)
```

Compiles a runtime hook/library C source file to a `.bc` file at `-O0`. Use this to prepare runtime libraries (phase analysis runtime, phase bound runtime, etc.) as bitcode for merging.

- Creates the target only once (safe to call multiple times with the same `OUTPUT_TARGET`).
- Sets `NUGGET_BC_FILE` and `NUGGET_TARGET_TYPE` on `OUTPUT_TARGET`.

```cmake
nugget_compile_hook_bc(${CMAKE_SOURCE_DIR}/runtime/nugget_phase_analysis_runtime.c phase_analysis_hook_bc)
```

### `nugget_merge_bc_files`

```cmake
nugget_merge_bc_files(<INPUT_TARGET_LIST> <OUTPUT_TARGET>)
```

Merges multiple `.bc` targets into a single `.bc` file using `llvm-link`. Use this to merge the runtime library bitcode with the workload bitcode (after the bbid pass, before the analysis/bound pass).

- `INPUT_TARGET_LIST` is a CMake list of targets, each having a `NUGGET_BC_FILE` property.
- Sets `NUGGET_BC_FILE` and `NUGGET_TARGET_TYPE` on `OUTPUT_TARGET`.

```cmake
nugget_merge_bc_files("labeled_bc;phase_analysis_hook_bc" merged_bc)
```

### `nugget_apply_opt`

```cmake
nugget_apply_opt(<INPUT_TARGET> <CMD> <OUTPUT_TARGET>)
```

Runs `opt` with the given command string on the `.bc` file from `INPUT_TARGET`. Use this to apply any Nugget pass (or any LLVM pass).

- `CMD` is a string passed to `opt` (e.g., `-load-pass-plugin=... -passes="..."`). It is automatically split into a proper argument list.
- Sets `NUGGET_BC_FILE` and `NUGGET_TARGET_TYPE` on `OUTPUT_TARGET`.

```cmake
nugget_apply_opt(my_app_bc
    "-load-pass-plugin=${NUGGET_PLUGIN} -passes=\"ir-bb-label-pass<output_csv=bb_info.csv>\""
    labeled_bc)
```

### `nugget_create_obj`

```cmake
nugget_create_obj(<INPUT_TARGET> <CMD> <OUTPUT_TARGET>)
```

Lowers a `.bc` file to a native object file (`.o`) using `llc`. This avoids uncontrolled optimizations that `clang` might introduce when given bitcode directly.

- `CMD` is a string of extra `llc` flags (e.g., `"-O2"`).
- Automatically adds `--relocation-model=pic -filetype=obj`.
- Sets `NUGGET_OBJ_FILE` and `NUGGET_TARGET_TYPE` on `OUTPUT_TARGET`.

```cmake
nugget_create_obj(instrumented_bc "-O2" instrumented_obj)
```

### `nugget_create_link_cmd`

```cmake
nugget_create_link_cmd(<ORIGINAL_TARGET> <OUT_LINK_CMD> <OUT_LINK_DEPS>)
```

Builds the linker command for the final executable by recursively collecting all library dependencies from `ORIGINAL_TARGET`. Also compiles source files skipped by the IR pipeline (e.g., `.cu` CUDA files) into object files.

- `OUT_LINK_CMD` receives the list of linker arguments (object files, `-l` flags, library paths).
- `OUT_LINK_DEPS` receives the list of CMake targets that must be built before linking.

```cmake
nugget_create_link_cmd(my_app LINK_CMD LINK_DEPS)
```

### `nugget_create_exe`

```cmake
nugget_create_exe(<ORIGINAL_TARGET> <OBJ_TARGET> <CMD> <LINK_CMD> <LINK_DEPS> <OUTPUT_TARGET>)
```

Links the nugget object file with extra objects and libraries into a final executable.

- `ORIGINAL_TARGET` is the original CMake target (used to detect linker language).
- `OBJ_TARGET` is the nugget target with a `NUGGET_OBJ_FILE` property.
- `CMD` is extra linker flags as a string.
- `LINK_CMD` and `LINK_DEPS` come from `nugget_create_link_cmd`.
- Automatically detects the correct linker (`clang`, `clang++`, or `flang-new`). For mixed CXX+Fortran projects, prefers CXX to avoid `flang-new` linking `libFortran_main`.
- When linking with a non-Fortran linker in a Fortran-enabled project, automatically adds `-lFortranRuntime -lFortranDecimal`.
- Sets `NUGGET_EXE_FILE` and `NUGGET_TARGET_TYPE` on `OUTPUT_TARGET`.

```cmake
nugget_create_exe(my_app instrumented_obj "" "${LINK_CMD}" "${LINK_DEPS}" my_app_instrumented)
```

---

## Helper Functions

These are used internally but can be useful for advanced customization:

| Function | Description |
|----------|-------------|
| `nugget_helper_extract_file_type(FILE RESULT_VAR)` | Returns the language type (`C`, `CXX`, `Fortran`, `CUDA`, `Header`, `Text`) based on file extension. |
| `nugget_helper_dump_target_properties(TARGET)` | Prints all properties of a CMake target (debugging). |
| `nugget_is_ir_included_target(TARGET RESULT_VAR)` | Returns `TRUE` if the target has source files under `NUGGET_PROJECT_SOURCE_DIRS` (i.e., should be compiled to IR). |
| `nugget_find_target_dependencies(TARGET RESULT_VAR)` | Returns the direct dependencies of a target (from `LINK_LIBRARIES`, `INTERFACE_LINK_LIBRARIES`, `MANUALLY_ADDED_DEPENDENCIES`). |
| `nugget_validate_compiler_option(OPTIONS LANG OUT)` | Tests each flag against the Nugget compiler for `LANG` and returns only the supported ones. |

---

## Example: Full Pipeline in CMake

```cmake
include(/path/to/nugget_util/nugget-function.cmake)

set(NUGGET_PLUGIN "/path/to/NuggetPasses.so")

# --- Step 1: Create the workload .bc from an existing CMake target ---
nugget_create_bc_file(my_app my_app_bc SKIPPED_TARGETS)

# --- Step 2: Apply IRBBLabelPass ---
nugget_apply_opt(my_app_bc
    "-load-pass-plugin=${NUGGET_PLUGIN} -passes=\"ir-bb-label-pass<output_csv=bb_info.csv>\""
    labeled_bc)

# --- Step 3: Compile the phase analysis runtime to .bc and merge ---
nugget_compile_hook_bc(${CMAKE_SOURCE_DIR}/runtime/nugget_phase_analysis_runtime.c
    phase_analysis_hook_bc)
nugget_merge_bc_files("labeled_bc;phase_analysis_hook_bc" merged_analysis_bc)

# --- Step 4: Apply PhaseAnalysisPass ---
nugget_apply_opt(merged_analysis_bc
    "-load-pass-plugin=${NUGGET_PLUGIN} -passes=\"phase-analysis-pass<interval_length=100000>\""
    analysis_instrumented_bc)

# --- Step 5: Lower to object and link ---
nugget_create_obj(analysis_instrumented_bc "-O2" analysis_obj)
nugget_create_link_cmd(my_app LINK_CMD LINK_DEPS)
nugget_create_exe(my_app analysis_obj "" "${LINK_CMD}" "${LINK_DEPS}" my_app_analysis)
```

---

## Target Properties

Every nugget target carries these custom properties for pipeline chaining:

| Property | Set by | Description |
|----------|--------|-------------|
| `NUGGET_BC_FILE` | `nugget_create_bc_file`, `nugget_apply_opt`, `nugget_merge_bc_files`, `nugget_compile_hook_bc` | Path to the `.bc` file |
| `NUGGET_OBJ_FILE` | `nugget_create_obj` | Path to the `.o` file |
| `NUGGET_EXE_FILE` | `nugget_create_exe` | Path to the final executable |
| `NUGGET_TARGET_TYPE` | All pipeline functions | One of `NUGGET_BC_TARGET`, `NUGGET_OBJ_TARGET`, `NUGGET_EXE_TARGET` |
