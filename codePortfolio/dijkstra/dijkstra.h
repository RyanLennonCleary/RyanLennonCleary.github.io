#ifndef DIJKSTRA
#define DIJKSTRA
void create_min_heap(Vertex*** Q, Vertex** vertex_list, int node_count);
void downward_heapify(Vertex** Q, int node_count, int node);
void find_shortest_path(Vertex** Q, Vertex** vertex_list, AdjacencyNode** adjacency_list, int node_count, int source, int destination, HashEntry* hash_table);
void read_query(char* queryname, int* src, int** dst);
void remove_root(Vertex** Q, int node_count);
void print_path(Vertex** vertex_list, int destination, int source, HashEntry* hash_table, int node_count);
void print_path_node(Vertex current, int source);
void upward_heapify(Vertex** Q, int node_count, int node);
#endif
