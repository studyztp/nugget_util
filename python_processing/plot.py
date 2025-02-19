from matplotlib import pyplot as plt
from typing import List, Dict
from sklearn.metrics import pairwise_distances
import numpy as np

from .analysis_functions import(
    reverse_map,
    reduce_data_dim_with_pca
)

def plot_bbv_matrix(
    bbv_list: List[List[int]],
    bb_id_map: Dict[str, int],
    static_info: Dict[int, Dict] = None,
    num_reduced_dim: int = 100
):
    normalized_data = []
    reversed_bb_id_map = reverse_map(bb_id_map)
    # normalize the bbv data
    for row in bbv_list:
        weighted_with_inst = [row[i] * int(static_info[int(reversed_bb_id_map[i])]["basic_block_ir_inst_count"]) for i in range(len(row))]
        row_sum = sum(weighted_with_inst)
        if (row_sum == 0):
            print("Error: Row sum is 0")
            print(row)
            print(weighted_with_inst)
            raise ValueError("Row sum is 0")
        normalized_row = [val / row_sum for val in weighted_with_inst]
        normalized_data.append(normalized_row)

    data = np.array(normalized_data)

    # Reduce data dimensionality
    data = reduce_data_dim_with_pca(data, num_reduced_dim)

    # Calculate Manhattan distance matrix
    n_samples = data.shape[0]
    distance_matrix = np.zeros((n_samples, n_samples))
    
    for i in range(n_samples):
        for j in range(n_samples):
            distance_matrix[i, j] = np.sum(np.abs(data[i] - data[j]))
    
    # Create heatmap
    plt.figure(figsize=(10, 8))
    plt.imshow(distance_matrix, cmap='viridis')
    plt.colorbar(label='Manhattan Distance')
    plt.title('Manhattan Distance Heatmap between BBV Vectors')
    plt.xlabel('Vector Index')
    plt.ylabel('Vector Index')
    plt.savefig('manhattan_distance_heatmap.png')
    plt.close()

