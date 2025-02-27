# Helper Python Scripts

Below is a Markdown document that serves as documentation for the [analysis_functions.py](https://github.com/studyztp/nugget_util/blob/main/python_processing/analysis_functions.py) module. You can save this content as `ANALYSIS_FUNCTIONS.md` (or similar) in your repository.

---

# Analysis Functions Documentation

`analysis_functions.py` is a Python module that provides a comprehensive suite of functions for processing profiling data, analyzing basic block execution vectors (BBV), and selecting representative regions for further analysis (e.g., for LLVM passes). The module includes utilities to:

- Extract CSV data and form Pandas DataFrames.
- Map basic block IDs to indices.
- Compute and manipulate basic block vectors (BBV) and count stamps for individual regions.
- Form markers for regions based on BBV data.
- Generate static basic block metadata.
- Prepare input parameters for LLVM passes.
- Randomly select regions.
- Perform k-means clustering (with PCA-based dimensionality reduction) to choose representative regions from a set of BBV profiles.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Overview](#overview)
3. [Utility Functions](#utility-functions)
4. [Basic Block and Region Analysis](#basic-block-and-region-analysis)
5. [Marker Generation and Input Preparation](#marker-generation-and-input-preparation)
6. [Region Selection and Clustering](#region-selection-and-clustering)
7. [Usage Examples](#usage-examples)
8. [Troubleshooting](#troubleshooting)
9. [Contributing](#contributing)
10. [License](#license)

---

## Prerequisites

- **Python Version:** Python 3.x  
- **Required Libraries:**  
  - `numpy`
  - `pandas`
  - `scikit-learn`
  - `scipy`
  - Standard libraries: `random`, `re`
- **Input Data Format:**  
  CSV files are expected to have a header row and a consistent structure.  
  A static info file (for basic block metadata) must follow a specific format (e.g., `[function_id:function_name]` followed by basic block details).

---

## Overview

This module is designed for analyzing program execution at the basic block level. It converts CSV profiling data into structured formats, computes execution vectors per region, and uses clustering techniques (with PCA and k-means) to identify representative regions for further optimization or instrumentation. The functions provided here are used in the context of dynamic analysis and region-based performance profiling.

---

## Utility Functions

### `print_library_version(lib)`

Prints the version of the given library.

- **Parameters:**  
  - `lib`: A library module (e.g., `numpy`, `pandas`).

**Example:**

```python
import numpy as np
print_library_version(np)
```

---

### `extract_csv_data(file_path: str) -> List[List[str]]`

Extracts data from a CSV file and returns it as a list of rows, where each row is a list of strings.

- **Parameters:**  
  - `file_path` (str): The path to the CSV file.

- **Returns:**  
  - A list of rows extracted from the CSV.

- **Exceptions:**  
  - Raises `FileNotFoundError` if the file does not exist.
  - Raises `IOError` if there is an error reading the file.

---

### `form_dataframe_from_csv(file_path: str) -> pd.DataFrame`

Forms a Pandas DataFrame from a CSV file.

- **Description:**  
  Reads CSV data (using `extract_csv_data`), drops the header row and the last row, and assigns columns: `type`, `region`, `thread`, followed by dynamically generated data columns.

- **Parameters:**  
  - `file_path` (str): Path to the CSV file.

- **Returns:**  
  - A `pd.DataFrame` representing the CSV data.

---

## Basic Block and Region Analysis

### `form_bb_id_map(df: pd.DataFrame) -> Dict[str, int]`

Generates a mapping from basic block IDs (from rows with `type == 'bb_id'`) to unique integer indices.

- **Parameters:**  
  - `df`: DataFrame containing basic block information.

- **Returns:**  
  - A dictionary mapping each basic block ID to an integer index.

---

### `get_total_regions(df: pd.DataFrame) -> int`

Calculates the total number of valid regions in the DataFrame (excluding non-valid entries such as `'region'` or `'N/A'`).

- **Parameters:**  
  - `df`: DataFrame with a `region` column.

- **Returns:**  
  - The number of regions as an integer.

---

### `form_bbv_for_a_region(df: pd.DataFrame, region_number: int, bb_id_map: Dict[str, int]) -> List[int]`

Computes the basic block vector (BBV) for a specified region by summing the counts for each basic block.

- **Parameters:**  
  - `df`: DataFrame containing profiling data.
  - `region_number` (int): The region to process.
  - `bb_id_map`: Mapping from basic block IDs to indices.

- **Returns:**  
  - A list of integers representing the BBV for the region.

---

### `form_count_stamp_for_a_region(df: pd.DataFrame, region_number: int, bb_id_map: Dict[str, int]) -> List[int]`

Forms a list of count stamps for a region. Each element corresponds to the maximum observed count for a basic block within the region.

- **Parameters:**  
  - `df`: DataFrame with region data.
  - `region_number` (int): The region identifier.
  - `bb_id_map`: Basic block ID mapping.

- **Returns:**  
  - A list of count stamps (integers) for the region.

---

### `get_all_bbv(df: pd.DataFrame, bb_id_map: Dict[str, int]) -> List[List[int]]`

Generates BBV lists for all regions in the DataFrame.

- **Parameters:**  
  - `df`: DataFrame containing region data.
  - `bb_id_map`: Mapping of basic block IDs to indices.

- **Returns:**  
  - A list of BBV lists (one per region).

---

### `combine_bbv(bbv_list1: List[int], bbv_list2: List[int]) -> List[int]`

Element-wise sums two BBV lists.

- **Parameters:**  
  - `bbv_list1`: First BBV list.
  - `bbv_list2`: Second BBV list.

- **Returns:**  
  - A new BBV list where each element is the sum of the corresponding elements.

- **Exceptions:**  
  - Raises `ValueError` if the lists are of different lengths.

---

### `relative_bbv(bbv_list1: List[int], bbv_list2: List[int]) -> List[int]`

Computes the element-wise difference between two BBV lists.

- **Parameters:**  
  - `bbv_list1`: The minuend BBV list.
  - `bbv_list2`: The subtrahend BBV list.

- **Returns:**  
  - A BBV list representing the difference (`x - y` for each element).

- **Exceptions:**  
  - Raises `ValueError` if the lists have different lengths.

---

### `reverse_map(map)`

Reverses a dictionary, swapping its keys and values.

- **Parameters:**  
  - `map`: The dictionary to reverse.

- **Returns:**  
  - A new dictionary with keys and values swapped.

---

### `find_infrequent_bb(csv: List[int], bbv: List[int], threshold: int)`

Finds the basic block with the least count (above a given threshold) in the provided BBV list.

- **Parameters:**  
  - `csv`: List of count stamps.
  - `bbv`: BBV list for the region.
  - `threshold` (int): Threshold for determining infrequent counts.

- **Returns:**  
  - A tuple `(least_count, index)` where `least_count` is the minimum count and `index` is the corresponding basic block index.

---

## Marker Generation and Input Preparation

### `form_all_markers(df: pd.DataFrame, bb_id_map: Dict[str, int], num_warmup_region: int, grace_perc: float, region_length: int) -> pd.DataFrame`

Generates markers for each region based on BBV analysis. Markers include warmup, start, and end identifiers along with their respective counts.

- **Parameters:**  
  - `df`: DataFrame containing region data.
  - `bb_id_map`: Mapping from basic block IDs to indices.
  - `num_warmup_region` (int): Number of regions used as warmup.
  - `grace_perc` (float): Grace period percentage (between 0 and 1).
  - `region_length` (int): Expected region length.

- **Returns:**  
  - A DataFrame with marker information (columns include `region`, `warmup_rid`, `start_rid`, `warmup_bid`, `warmup_count`, `start_bid`, `start_count`, `end_bid`, `end_count`).

---

### `get_static_info(file_path)`

Reads static basic block information from a file and returns it as a dictionary.

- **Parameters:**  
  - `file_path` (str): Path to the static info file.

- **Returns:**  
  - A dictionary mapping basic block IDs (as integers) to metadata (including basic block name, instruction count, function name, and function ID).

---

### `create_input_for_pass(marker_df: pd.DataFrame, static_info: Dict[int, Dict], region_id: int) -> Tuple[int, int, int, int, int, int, int, int, int]`

Prepares input parameters for an LLVM pass for a given region based on marker data and static basic block information.

- **Parameters:**  
  - `marker_df`: DataFrame containing marker information.
  - `static_info`: Dictionary with static basic block metadata.
  - `region_id` (int): The region for which to prepare input.

- **Returns:**  
  - A tuple of nine integers representing:  
    `(warmup_function_id, warmup_bb_id, warmup_count, start_function_id, start_bb_id, start_count, end_function_id, end_bb_id, end_count)`

---

## Region Selection and Clustering

### `randomly_select_regions(num_regions: int, num_select: int) -> List[int]`

Randomly selects a subset of region IDs.

- **Parameters:**  
  - `num_regions` (int): Total number of regions.
  - `num_select` (int): Number of regions to randomly select.

- **Returns:**  
  - A list of randomly selected region IDs.

- **Exceptions:**  
  - Raises `ValueError` if `num_select` exceeds `num_regions`.

---

### `compute_bic(kmeans: KMeans, X: np.ndarray) -> float`

Computes the Bayesian Information Criterion (BIC) for a k-means clustering model.

- **Parameters:**  
  - `kmeans`: A fitted scikit-learn `KMeans` model.
  - `X`: The input data matrix.

- **Returns:**  
  - The computed BIC score (lower is better).

---

### `find_optimal_kmeans(data: np.ndarray, max_k: int = 10) -> Tuple[int, KMeans]`

Determines the optimal number of clusters using k-means clustering by evaluating silhouette scores.

- **Parameters:**  
  - `data`: Normalized data matrix.
  - `max_k` (int): Maximum number of clusters to try (default: 10).

- **Returns:**  
  - A tuple `(optimal_k, optimal_kmeans)` where `optimal_k` is the optimal number of clusters and `optimal_kmeans` is the corresponding k-means model.

---

### `find_rep_rid(data, labels, centers)`

Identifies a representative region ID for each cluster by finding the data point closest to the cluster center.

- **Parameters:**  
  - `data`: The data points (after dimensionality reduction).
  - `labels`: Cluster labels for each data point.
  - `centers`: Coordinates of the cluster centers.

- **Returns:**  
  - A dictionary mapping cluster indices to the representative region ID.

---

### `find_cluster_rid(labels)`

Groups region IDs by their cluster labels.

- **Parameters:**  
  - `labels`: List of cluster labels.

- **Returns:**  
  - A dictionary mapping each cluster label (as a string) to a list of region IDs belonging to that cluster.

---

### `find_cluster_weights(clusters_info)`

Calculates the weight (number of regions) for each cluster.

- **Parameters:**  
  - `clusters_info`: Dictionary mapping cluster labels to lists of region IDs.

- **Returns:**  
  - A dictionary mapping each cluster label to its corresponding weight (region count).

---

### `reduce_data_dim_with_pca(data, n_components) -> np.ndarray`

Reduces the dimensionality of the input data using Principal Component Analysis (PCA).

- **Parameters:**  
  - `data`: The input data matrix.
  - `n_components` (int): Number of principal components to retain.

- **Returns:**  
  - The transformed data with reduced dimensions.

---

### `k_means_select_regions(num_clusters: int, bbv_list: List[List[int]], bb_id_map: Dict[str, int], static_info: Dict[int, Dict] = None, n_reduce_components: int = 100) -> Dict[str, List[int]]`

Performs k-means clustering on normalized BBV data to select representative regions.

- **Process Overview:**  
  1. **Normalization:** Each BBV row is weighted by the basic block IR instruction count from `static_info` and normalized.  
  2. **Dimensionality Reduction:** PCA reduces the data dimensions (default to 100 components).  
  3. **Optimal Clustering:** The function finds the optimal number of clusters (using silhouette scores) within the provided maximum number of clusters.  
  4. **Representative Regions:** Determines representative region IDs and computes cluster weights.

- **Parameters:**  
  - `num_clusters` (int): Maximum number of clusters to consider.
  - `bbv_list`: A list of BBV lists, each representing a region.
  - `bb_id_map`: Mapping from basic block IDs to indices.
  - `static_info` (optional): Static basic block metadata (required for weighting).
  - `n_reduce_components` (int, default=100): Number of PCA components to retain.

- **Returns:**  
  - A dictionary containing:  
    - `"num_clusters"`: Optimal number of clusters.
    - `"inertia"`: Clustering inertia.
    - `"n_iter"`: Number of iterations run by k-means.
    - `"rep_rid"`: Mapping of cluster indices to representative region IDs.
    - `"clusters"`: Dictionary grouping region IDs by cluster.
    - `"clusters_weights"`: Cluster weights (region counts).
    - `"bbv"`: Normalized and PCA-transformed BBV data as a list.

---

## Usage Examples

### Example 1: Extracting CSV Data and Forming a DataFrame

```python
from analysis_functions import extract_csv_data, form_dataframe_from_csv

file_path = "data/profile_data.csv"
data = extract_csv_data(file_path)
df = form_dataframe_from_csv(file_path)
print(df.head())
```

---

### Example 2: Basic Block Vector (BBV) Analysis

```python
from analysis_functions import form_bb_id_map, get_total_regions, get_all_bbv

bb_id_map = form_bb_id_map(df)
total_regions = get_total_regions(df)
all_bbv = get_all_bbv(df, bb_id_map)
print(f"Total Regions: {total_regions}")
print(f"BBV for Region 0: {all_bbv[0]}")
```

---

### Example 3: Generating Markers and Preparing LLVM Pass Input

```python
from analysis_functions import form_all_markers, get_static_info, create_input_for_pass

marker_df = form_all_markers(df, bb_id_map, num_warmup_region=3, grace_perc=0.1, region_length=100)
static_info = get_static_info("data/static_info.txt")
llvm_pass_input = create_input_for_pass(marker_df, static_info, region_id=0)
print("LLVM Pass Input:", llvm_pass_input)
```

---

### Example 4: K-Means Clustering for Region Selection

```python
from analysis_functions import k_means_select_regions

# Assume all_bbv is computed and static_info is available.
clustering_result = k_means_select_regions(
    num_clusters=5,
    bbv_list=all_bbv,
    bb_id_map=bb_id_map,
    static_info=static_info,
    n_reduce_components=50
)
print("Clustering Result:", clustering_result)
```

---

## Troubleshooting

- **CSV Format Issues:**  
  Ensure that your CSV file has the expected header and data format. Inconsistent formatting may lead to DataFrame creation errors.

- **Missing Basic Block Data:**  
  If functions like `form_bb_id_map` or `form_bbv_for_a_region` fail, verify that your CSV contains rows with the correct `type` (e.g., `'bb_id'`, `'bbv'`, `'csv'`).

- **Clustering Errors:**  
  Confirm that the BBV lists are non-zero and that `static_info` contains valid basic block counts for proper weighting and normalization.

---

## Contributing

Contributions to improve these analysis functions are welcome. To contribute:

1. Fork the repository.
2. Create a new branch with your changes.
3. Submit a pull request with a detailed description of your changes.
4. Include tests and update the documentation if necessary.

---

## License

This module is part of the [nugget_util](https://github.com/studyztp/nugget_util) project and is distributed under the same license as the main project. Please see the [LICENSE](https://github.com/studyztp/nugget_util/blob/main/LICENSE) file for details.

---

This documentation is intended to serve as a comprehensive guide for developers working with the `analysis_functions.py` module. For further questions or issues, please refer to the [GitHub repository](https://github.com/studyztp/nugget_util).

