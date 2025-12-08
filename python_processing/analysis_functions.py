import random
import re
import numpy as np
import pandas as pd
from typing import List, Dict, Tuple, Final

# for k-means clustering
from sklearn.decomposition import PCA
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
from scipy.spatial import distance
from sklearn.metrics import pairwise_distances

# Random seed for reproducibility - DO NOT CHANGE
RANDOM_SEED: Final[int] = 627

random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

def print_library_version(lib):
    # Print the version of a library
    print(f"Version of {lib.__name__}: {lib.__version__}")

def extract_csv_data(file_path: str) -> List[List[str]]:
    """Extract data from a CSV file.
    
    Args:
        file_path: Path to the CSV file
        
    Returns:
        List of rows, where each row is a list of strings
        
    Raises:
        FileNotFoundError: If file doesn't exist
        IOError: If file can't be read
    """
    try:
        with open(file_path, 'r') as file:
            return [line.strip().split(',') for line in file]
    except FileNotFoundError:
        raise FileNotFoundError(f"CSV file not found: {file_path}")
    except IOError as e:
        raise IOError(f"Error reading CSV file: {str(e)}")

def form_dataframe_from_csv(file_path: str) -> pd.DataFrame:
    """Form a pandas dataframe from the CSV file formed by the hooks.
    
    Args:
        file_path: Path to the CSV file
        
    Returns:
        DataFrame with columns: type, region, thread, data1, data2, ...
    """
    try:
        data = extract_csv_data(file_path)
        data = data[1:-1]  # drop the header column and the last row
        df = pd.DataFrame(data)
        max_columns = df.shape[1]
        column_names = ['type', 'region', 'thread'] + [f'data{i}' for i in range(1, max_columns - 2)]
        df.columns = column_names
        return df
    except Exception as e:
        raise RuntimeError(f"Error creating DataFrame: {str(e)}")

def form_bb_id_map(df: pd.DataFrame) -> Dict[str, int]:
    """Form a map of basic block IDs to their indices in the bbv list.
    
    Args:
        df: DataFrame containing basic block information
        
    Returns:
        Dictionary mapping block IDs to indices
    """
    bb_id_map = {}
    try:
        filtered_df = df[df['type'] == 'bb_id'].drop(columns=['type', 'region', 'thread'])
        for _, row in filtered_df.iterrows():
            for col in filtered_df.columns:
                if pd.notna(row[col]) and row[col] not in bb_id_map:
                    bb_id_map[row[col]] = len(bb_id_map)
        return bb_id_map
    except Exception as e:
        raise RuntimeError(f"Error creating basic block map: {str(e)}")

def get_total_regions(df: pd.DataFrame) -> int:
    """Get the total number of regions in the dataframe.
    
    Args:
        df: DataFrame containing region information
        
    Returns:
        Number of valid regions
    """
    try:
        all_region_numbers = df['region'].unique()
        valid_region_numbers = [region for region in all_region_numbers 
                              if region not in ('region', 'N/A')]
        return len(valid_region_numbers)
    except Exception as e:
        raise RuntimeError(f"Error counting regions: {str(e)}")

def form_bbv_for_a_region(df: pd.DataFrame, 
                         region_number: int, 
                         bb_id_map: Dict[str, int]) -> List[int]:
    """Form the bbv list for a region.
    
    Args:
        df: DataFrame containing region information
        region_number: Region number to process
        bb_id_map: Dictionary mapping block IDs to indices
        
    Returns:
        List of basic block vector values
    """
    try:
        filtered_df = df[df['region'] == str(region_number)]
        bb_id_rows = filtered_df[filtered_df['type'] == 'bb_id'].drop(
            columns=['type', 'region', 'thread'])
        bbv_rows = filtered_df[filtered_df['type'] == 'bbv'].drop(
            columns=['type', 'region', 'thread'])
        
        bbv = [0 for _ in range(len(bb_id_map))]
        
        for (_, bb_row), (_, val_row) in zip(
                bb_id_rows.iterrows(), bbv_rows.iterrows()):
            for bb_id, val in zip(bb_row, val_row):
                if pd.notna(bb_id) and pd.notna(val):
                    bbv[bb_id_map[bb_id]] += int(val)
        return bbv
    except Exception as e:
        raise RuntimeError(f"Error forming BBV for region {region_number}: {str(e)}")

def form_count_stamp_for_a_region(df: pd.DataFrame, 
                                region_number: int, 
                                bb_id_map: Dict[str, int]) -> List[int]:
    """Form the count stamp list for a region.
    
    Args:
        df: DataFrame containing region information
        region_number: Region number to process
        bb_id_map: Dictionary mapping block IDs to indices
        
    Returns:
        List of count stamp values
    """
    try:
        filtered_df = df[df['region'] == str(region_number)]
        bb_id_rows = filtered_df[filtered_df['type'] == 'bb_id'].drop(
                columns=['type', 'region', 'thread'])
        csv_rows = filtered_df[filtered_df['type'] == 'csv'].drop(
                columns=['type', 'region', 'thread'])
        csv = [0 for _ in range(len(bb_id_map))]

        for (_, bb_id_row), (_, csv_row) in zip(
                    bb_id_rows.iterrows(), csv_rows.iterrows()):
            for bb_id, val in zip(bb_id_row, csv_row):
                if pd.notna(bb_id) and pd.notna(val):
                    csv[bb_id_map[bb_id]] = max(
                            csv[bb_id_map[bb_id]], int(val))
        return csv
    except Exception as e:
        raise RuntimeError(
            f"Error forming count stamp for region {region_number}: {str(e)}")

def get_all_bbv(
        df: pd.DataFrame, bb_id_map: Dict[str, int]
    ) -> List[List[int]]:
# Get the bbv list for all regions
    return [form_bbv_for_a_region(df, i, bb_id_map) 
                for i in range(get_total_regions(df))]

def combine_bbv(bbv_list1: List[int], bbv_list2: List[int]) -> List[int]:
    """Combine two bbv lists element-wise.
    
    Args:
        bbv_list1: First BBV list
        bbv_list2: Second BBV list
        
    Returns:
        Combined BBV list
    """
    if len(bbv_list1) != len(bbv_list2):
        raise ValueError("BBV lists must have same length")
    return [x + y for x, y in zip(bbv_list1, bbv_list2)]

def relative_bbv(bbv_list1: List[int], bbv_list2: List[int]) -> List[int]:
    """Get the relative bbv list.
    
    Args:
        bbv_list1: First BBV list
        bbv_list2: Second BBV list
        
    Returns:
        Relative BBV list
    """
    if len(bbv_list1) != len(bbv_list2):
        raise ValueError("BBV lists must have same length")
    return [x - y for x, y in zip(bbv_list1, bbv_list2)]

def reverse_map(map):
    return {v: k for k, v in map.items()}

def find_infrequent_bb(
        csv: List[int], 
        bbv: List[int],
        threshold: int
):
    # Find the least count inside the grace period
    least_count_index = -1
    least_count = max(bbv)+1

    for index, count_stamp in enumerate(csv):
        if count_stamp >= threshold:
            if bbv[index] < least_count:
                least_count = bbv[index]
                least_count_index = index
    # if no count stamp is greater than the threshold,
    # we take the maximum count stamp
    # this happens when the region is shorter than the planned
    # region length, for example, the last region
    if least_count_index == -1:
        least_count_index = \
            csv.index(max(csv))
        least_count = bbv[least_count_index]
    
    return least_count, least_count_index

def form_all_markers(
        df: pd.DataFrame,
        bb_id_map: Dict[str, int], 
        num_warmup_region: int, 
        grace_perc: float, 
        region_length: int
    ) -> pd.DataFrame:

    """Form all markers for regions based on BBV analysis.
    
    Args:
        file_path: Path to the CSV file
        num_warmup_region: Number of warmup regions
        grace_perc: Grace period percentage (0-1)
        region_length: Length of each region
        
    Returns:
        List of tuples (rid, warmup_bid, warmup_count, start_bid, start_count, end_bid, end_count)
    """
    try:
        total_num_regions = get_total_regions(df)
        
        # Initialize arrays
        zero_bbv = [0 for _ in range(len(bb_id_map))]
        global_bbv = zero_bbv.copy()
        threshold = region_length * grace_perc
        previous_global_bbvs = []

        reversed_bb_id_map = reverse_map(bb_id_map)

        marker_df = pd.DataFrame(columns=[
            'region', 'warmup_rid', 'start_rid', 'warmup_bid', 'warmup_count',
            'start_bid', 'start_count', 'end_bid', 'end_count'
        ])

        for i in range(total_num_regions):
            try:
                # if we are finding the end of region 0, it should be the 
                # bbv and csv of region 0
                end_bbv = form_bbv_for_a_region(df, i, bb_id_map)
                end_csv = form_count_stamp_for_a_region(df, i, bb_id_map)
                global_bbv = combine_bbv(global_bbv, end_bbv)

                # Calculate safe indices
                warmup_rid = \
                    max(-1, i - num_warmup_region - 1)
                start_rid = max(-1, i - 1)

                if warmup_rid == start_rid:
                    warmup_rid = -1

                # -1 is a special case for the first region
                if warmup_rid == -1:
                    warmup_bbv = zero_bbv.copy()
                    warmup_csv = zero_bbv.copy()
                else:
                    warmup_bbv = previous_global_bbvs[warmup_rid].copy()
                    warmup_csv = form_count_stamp_for_a_region(df, warmup_rid, bb_id_map)
                
                if start_rid == -1:
                    start_bbv = zero_bbv.copy()
                    start_csv = zero_bbv.copy()
                else:
                    start_bbv = previous_global_bbvs[start_rid].copy()
                    start_csv = form_count_stamp_for_a_region(df, start_rid, bb_id_map)

                # Calculate the relative BBV between the start and warmup
                relative_start_bbv = relative_bbv(start_bbv, warmup_bbv)

                # Calculate the relative BBV between the end and start
                relative_end_bbv = relative_bbv(global_bbv, start_bbv)

                # Find the least count for warmup marker
                least_warmup_count, least_warmup_count_index = find_infrequent_bb(
                    warmup_csv, warmup_bbv, threshold
                )
                
                # Find the least count for start marker inside the grace period
                least_start_count, least_start_count_index = find_infrequent_bb(
                    start_csv, relative_start_bbv, threshold
                )

                # Find the least count for end marker inside the grace period
                least_end_count, least_end_count_index = find_infrequent_bb(
                    end_csv, relative_end_bbv, threshold
                )

                # Create marker with actual indices
                warmup_bid = least_warmup_count_index
                warmup_count = least_warmup_count
                if warmup_count == 0:
                    warmup_bid = 0
                start_bid = least_start_count_index
                start_count = least_start_count
                if start_count == 0:
                    start_bid = 0
                end_bid = least_end_count_index
                end_count = least_end_count

                new_marker = pd.DataFrame({
                    'region': [i],
                    'warmup_rid': [warmup_rid],
                    'start_rid': [start_rid],
                    'warmup_bid': [reversed_bb_id_map[warmup_bid]],
                    'warmup_count': [warmup_count],
                    'start_bid': [reversed_bb_id_map[start_bid]],
                    'start_count': [start_count],
                    'end_bid': [reversed_bb_id_map[end_bid]],
                    'end_count': [end_count]
                })
                marker_df = pd.concat([marker_df, new_marker], ignore_index=True)
                previous_global_bbvs.append(global_bbv.copy())

            except Exception as e:
                print(f"Warning: Error processing region {i}: {str(e)}")
                continue

        return marker_df

    except Exception as e:
        raise RuntimeError(f"Failed to process markers: {str(e)}")

def form_a_list_markers(
        df: pd.DataFrame,
        bb_id_map: Dict[str, int], 
        num_warmup_region: int, 
        grace_perc: float, 
        region_length: int,
        targeted_markers = []
    ) -> pd.DataFrame:

    """Form all markers for regions based on BBV analysis.
    
    Args:
        file_path: Path to the CSV file
        num_warmup_region: Number of warmup regions
        grace_perc: Grace period percentage (0-1)
        region_length: Length of each region
        targeted_markers: List of targeted markers to find
        
    Returns:
        List of tuples (rid, warmup_bid, warmup_count, start_bid, start_count, end_bid, end_count)
    """
    try:
        total_num_regions = get_total_regions(df)
        
        # Initialize arrays
        zero_bbv = [0 for _ in range(len(bb_id_map))]
        global_bbv = zero_bbv.copy()
        threshold = region_length * grace_perc
        previous_global_bbvs = []

        reversed_bb_id_map = reverse_map(bb_id_map)

        marker_df = pd.DataFrame(columns=[
            'region', 'warmup_rid', 'start_rid', 'warmup_bid', 'warmup_count',
            'start_bid', 'start_count', 'end_bid', 'end_count'
        ])

        for i in range(len(targeted_markers)):
            targeted_markers[i] = int(targeted_markers[i])

        found_markers = []

        for i in range(total_num_regions):
            try:
                end_bbv = form_bbv_for_a_region(df, i, bb_id_map)
                global_bbv = combine_bbv(global_bbv, end_bbv)
                if i in targeted_markers:
                    # if we are finding the end of region 0, it should be the 
                    # bbv and csv of region 0
                    end_csv = form_count_stamp_for_a_region(df, i, bb_id_map)

                    # Calculate safe indices
                    warmup_rid = \
                        max(-1, i - num_warmup_region - 1)
                    start_rid = max(-1, i - 1)

                    if warmup_rid == start_rid:
                        warmup_rid = -1

                    # -1 is a special case for the first region
                    if warmup_rid == -1:
                        warmup_bbv = zero_bbv.copy()
                        warmup_csv = zero_bbv.copy()
                    else:
                        warmup_bbv = previous_global_bbvs[warmup_rid].copy()
                        warmup_csv = form_count_stamp_for_a_region(df, warmup_rid, bb_id_map)
                    
                    if start_rid == -1:
                        start_bbv = zero_bbv.copy()
                        start_csv = zero_bbv.copy()
                    else:
                        start_bbv = previous_global_bbvs[start_rid].copy()
                        start_csv = form_count_stamp_for_a_region(df, start_rid, bb_id_map)

                    # Calculate the relative BBV between the start and warmup
                    relative_start_bbv = relative_bbv(start_bbv, warmup_bbv)

                    # Calculate the relative BBV between the end and start
                    relative_end_bbv = relative_bbv(global_bbv, start_bbv)

                    # Find the least count for warmup marker
                    least_warmup_count, least_warmup_count_index = find_infrequent_bb(
                        warmup_csv, warmup_bbv, threshold
                    )
                    
                    # Find the least count for start marker inside the grace period
                    least_start_count, least_start_count_index = find_infrequent_bb(
                        start_csv, relative_start_bbv, threshold
                    )

                    # Find the least count for end marker inside the grace period
                    least_end_count, least_end_count_index = find_infrequent_bb(
                        end_csv, relative_end_bbv, threshold
                    )

                    # Create marker with actual indices
                    warmup_bid = least_warmup_count_index
                    warmup_count = least_warmup_count
                    if warmup_count == 0:
                        warmup_bid = 0
                    start_bid = least_start_count_index
                    start_count = least_start_count
                    if start_count == 0:
                        start_bid = 0
                    end_bid = least_end_count_index
                    end_count = least_end_count

                    new_marker = pd.DataFrame({
                        'region': [i],
                        'warmup_rid': [warmup_rid],
                        'start_rid': [start_rid],
                        'warmup_bid': [reversed_bb_id_map[warmup_bid]],
                        'warmup_count': [warmup_count],
                        'start_bid': [reversed_bb_id_map[start_bid]],
                        'start_count': [start_count],
                        'end_bid': [reversed_bb_id_map[end_bid]],
                        'end_count': [end_count]
                    })
                    marker_df = pd.concat([marker_df, new_marker], ignore_index=True)
                    found_markers.append(i)
                    if len(found_markers) == len(targeted_markers):
                        break
                previous_global_bbvs.append(global_bbv.copy())

            except Exception as e:
                print(f"Warning: Error processing region {i}: {str(e)}")
                continue

        return marker_df

    except Exception as e:
        raise RuntimeError(f"Failed to process markers: {str(e)}")
    
def get_total_count_of_list_of_markers(
        df: pd.DataFrame,
        markers: List[int],
        bb_id_map: Dict[str, int]
    ) -> Dict[str, int]:
    """Get the total count of a list of markers.
    Args:
        df: DataFrame containing region information
        markers: List of marker region numbers
        bb_id_map: Dictionary mapping block IDs to indices
    Returns:
        Dictionary with marker region as key and total count as value
    """
    try:
        if not markers:
            raise ValueError("Markers list is empty")
        if not isinstance(markers, list):
            raise TypeError("Markers should be a list of integers")
        if not all(isinstance(marker, int) for marker in markers):
            raise TypeError("All markers should be integers")
        if len(markers) <= 0:
            raise ValueError("Markers list should contain at least one marker")
        
        total_counts = {}

        total_num_regions = get_total_regions(df)
        
        # Initialize arrays
        global_bbv = [0 for _ in range(len(bb_id_map))]

        for marker in markers:
            total_counts[marker] = 0

        for i in range(total_num_regions):
            try:
                end_bbv = form_bbv_for_a_region(df, i, bb_id_map)
                # print(f"Processing region {i}, BBV: {end_bbv}")
                global_bbv = combine_bbv(global_bbv, end_bbv)
                # print(f"Global BBV after region {i}: {global_bbv}")
            except Exception as e:
                # print(f"Warning: Error processing region {i}: {str(e)}")
                continue
        # print(f"Global BBV after processing all regions: {global_bbv}")
        for marker in markers:
            try:
                marker_bb_id = bb_id_map[marker]
                marker_count = global_bbv[marker_bb_id]
                print(f"Marker {marker} with bb_id {marker_bb_id} has count {marker_count}")
                total_counts[marker] = marker_count
            except KeyError:
                print(f"Warning: Marker {marker} not found in BBV map")
                total_counts[marker] = 0
        return total_counts

    except Exception as e:
        raise RuntimeError(f"Failed to process markers: {str(e)}")


def get_static_info(file_path):
    info = {}
    with open(file_path, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                function_match = re.match(r'\[(\d+):([^\]]+)\]', line)
                if function_match:
                    function_id, function_name = function_match.groups()
                    basic_blocks = re.findall(r'\[(\d+):([^\]]*):(\d+)\]', line)
                    for basic_block in basic_blocks:
                        basic_block_id, basic_block_name, basic_block_ir_inst_count = basic_block
                        info[int(basic_block_id)] = {
                            "basic_block_name": basic_block_name,
                            "basic_block_ir_inst_count": int(basic_block_ir_inst_count),
                            "function_name": function_name,
                            "function_id": int(function_id)
                        }
    return info

def create_input_for_pass(marker_df: pd.DataFrame, 
                         static_info: Dict[int, Dict], 
                         region_id: int) -> Tuple[int, int, int, int, int, int, int, int, int]:
    """Create input for the LLVM pass for a specific region.
    
    Args:
        marker_df: DataFrame containing marker information
        static_info: Dictionary containing static basic block information
        region_id: Region ID to process
        
    Returns:
        Tuple containing (warmup_function_id, warmup_bb_id, warmup_count,
                         start_function_id, start_bb_id, start_count,
                         end_function_id, end_bb_id, end_count)
    """
    try:
        # Convert region_id to match DataFrame's type
        region_marker = marker_df[marker_df["region"] == region_id]
        
        if region_marker.empty:
            raise ValueError(f"No marker found for region {region_id}")

        # Extract values safely with type conversion
        warmup_rid = int(region_marker["warmup_rid"].iloc[0])
        start_rid = int(region_marker["start_rid"].iloc[0])
        warmup_bid = int(region_marker["warmup_bid"].iloc[0])
        start_bid = int(region_marker["start_bid"].iloc[0])
        end_bid = int(region_marker["end_bid"].iloc[0])
        warmup_count = int(region_marker["warmup_count"].iloc[0])
        start_count = int(region_marker["start_count"].iloc[0])
        end_count = int(region_marker["end_count"].iloc[0])

        # Handle warmup region
        if warmup_rid == -1:
            output_warmup_function_id = 0
            output_warmup_basic_block_id = 0
            output_warmup_count = 0
        else:
            output_warmup_function_id = static_info[warmup_bid]["function_id"]
            output_warmup_basic_block_id = warmup_bid
            output_warmup_count = warmup_count
        
        # Handle start region
        if start_rid == -1:
            output_start_function_id = 0
            output_start_basic_block_id = 0
            output_start_count = 0
        else:
            output_start_function_id = static_info[start_bid]["function_id"]
            output_start_basic_block_id = start_bid
            output_start_count = start_count
        
        # Handle end region
        output_end_function_id = static_info[end_bid]["function_id"]
        output_end_basic_block_id = end_bid
        output_end_count = end_count

        return (output_warmup_function_id, 
                output_warmup_basic_block_id, 
                output_warmup_count,
                output_start_function_id, 
                output_start_basic_block_id, 
                output_start_count,
                output_end_function_id, 
                output_end_basic_block_id, 
                output_end_count)

    except Exception as e:
        raise RuntimeError(f"Error creating input for region {region_id}: {str(e)}")

def randomly_select_regions(num_regions: int, num_select: int) -> List[int]:
    """Randomly select regions to analyze.
    
    Args:
        num_regions: Total number of regions
        num_select: Number of regions to select
        
    Returns:
        List of region IDs
    """
    if num_select > num_regions:
        raise ValueError("Number of regions to select exceeds total regions")
    return random.sample(range(num_regions), num_select)

def compute_bic(kmeans: KMeans, X: np.ndarray) -> float:
    """Compute the Bayesian Information Criterion (BIC) for K-means clustering.
    
    Args:
        kmeans: Fitted KMeans model
        X: Input data matrix
        
    Returns:
        BIC score (lower is better)
    """
    n_points = X.shape[0]
    n_dimensions = X.shape[1]
    n_clusters = kmeans.n_clusters
    
    # Number of free parameters
    n_parameters = (n_clusters - 1) + (n_dimensions * n_clusters) + 1
    
    # Compute log likelihood
    labels = kmeans.labels_
    distances = np.min(kmeans.transform(X), axis=1)
    log_likelihood = np.sum(-0.5 * distances)
    
    # Compute BIC
    bic = -2 * log_likelihood + n_parameters * np.log(n_points)
    return bic

def find_optimal_kmeans(data: np.ndarray, max_k: int = 10) -> int:
    """Find optimal k-means clusters using BIC.
    
    Args:
        data: Normalized data matrix
        max_k: Maximum number of clusters to try
        
    Returns:
        Optimal number of clusters
    """
    silhouette_scores = []
    k_values = range(2, max_k + 1)
    all_kmeans_results = []
    
    for k in k_values:
        kmeans = KMeans(n_clusters=k, random_state=RANDOM_SEED)
        kmeans.fit(data)
        labels = kmeans.labels_
        silhouette_scores.append(silhouette_score(data, labels))
        all_kmeans_results.append(kmeans)
    
    # Find elbow point or minimum BIC
    optimal_k = k_values[np.argmax(silhouette_scores)]
    optimal_kmeans = all_kmeans_results[np.argmax(silhouette_scores)]

    return optimal_k, optimal_kmeans

def find_optimal_kmeans_memory_usage_optimized(data: np.ndarray, max_k: int = 10) -> int:
    """Find optimal k-means clusters using BIC.
    
    Args:
        data: Normalized data matrix
        max_k: Maximum number of clusters to try
        
    Returns:
        Optimal number of clusters
    """
    silhouette_scores = []
    k_values = range(2, max_k + 1)
    
    for k in k_values:
        kmeans = KMeans(n_clusters=k, random_state=RANDOM_SEED)
        kmeans.fit(data)
        labels = kmeans.labels_
        silhouette_scores.append(silhouette_score(data, labels))
        # do not store the kmeans data to save memory
    
    # Find elbow point or minimum BIC
    optimal_k = k_values[np.argmax(silhouette_scores)]

    # after knowing the optimized k, get the kmeans data
    optimal_kmeans = KMeans(n_clusters=optimal_k, random_state=RANDOM_SEED)
    optimal_kmeans.fit(data)

    return optimal_k, optimal_kmeans

def find_rep_rid(data, labels, centers):
    rep_rid = {}
    for i, center in enumerate(centers):
        min = float('inf')
        min_rid = -1
        count = 0
        for j, label in enumerate(labels):
            if label == i:
                count += 1
                dist = distance.euclidean(center, data[j])
                if dist < min:
                    min = dist
                    min_rid = j
        if min_rid != -1:
            rep_rid[i] = min_rid
        else:
            print("Error: No representative RID found for cluster")
            print(f"There are {count} RIDs in cluster {i}")

    return rep_rid

def find_cluster_rid(labels):
    clusters = {}
    for i, label in enumerate(labels):
        if str(label) not in clusters.keys():
            clusters[str(label)] = []
        clusters[str(label)].append(i)
    return clusters

def find_cluster_weights(clusters_info):
    cluster_weights = {}
    for cluster, rid_list in clusters_info.items():
        total_weight = len(rid_list)
        cluster_weights[cluster] = total_weight
    return cluster_weights

def reduce_data_dim_with_pca(data, n_components):
    """Reduce dimensionality of data using PCA.
    
    Args:
        data: Input data matrix
        n_components: Number of PCA components to keep
        
    Returns:
        Transformed data with reduced dimensions
    """
    pca = PCA(n_components=n_components, random_state=RANDOM_SEED)
    pca.fit(data)  # First fit the model
    return pca.transform(data)  # Then transform the data

def k_means_select_regions(
    num_clusters: int,
    bbv_list: List[List[int]],
    bb_id_map: Dict[str, int],
    static_info: Dict[int, Dict] = None,
    n_reduce_components: int = 100
) -> Dict[str, List[int]]:
    k = num_clusters
    reversed_bb_id_map = reverse_map(bb_id_map)

    # Vectorized normalization: weight by static inst counts, divide by row sums.
    weights = np.array(
        [int(static_info[int(reversed_bb_id_map[i])]["basic_block_ir_inst_count"]) for i in range(len(reversed_bb_id_map))],
        dtype=np.float64,
    )
    data = np.asarray(bbv_list, dtype=np.float64)
    data *= weights  # scale each column by inst count

    row_sums = data.sum(axis=1, keepdims=True)
    if np.any(row_sums == 0):
        raise ValueError("Row sum is 0 after weighting; check BBV input")
    data = data / row_sums

    # Dimensionality reduction only when beneficial
    n_comp = min(n_reduce_components, data.shape[0], data.shape[1])
    if n_comp and n_comp < data.shape[1]:
        data = reduce_data_dim_with_pca(data, n_components=n_comp)

    k, optimal_kmeans = find_optimal_kmeans_memory_usage_optimized(data, max_k=k)

    centers = optimal_kmeans.cluster_centers_
    labels = optimal_kmeans.labels_
    inertia = optimal_kmeans.inertia_
    n_iter = optimal_kmeans.n_iter_

    rep_rid = find_rep_rid(data, labels.tolist(), centers.tolist())
    clusters = find_cluster_rid(labels.tolist())
    clusters_weights = find_cluster_weights(clusters)

    return {
        "num_clusters": k,
        "inertia": inertia,
        "n_iter": n_iter,
        "rep_rid": rep_rid,
        "clusters": clusters,
        "clusters_weights": clusters_weights,
        "bbv": data.tolist()
    }


