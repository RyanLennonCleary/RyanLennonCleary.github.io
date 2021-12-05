#ifndef ADJACENT
#define ADJACENT
typedef struct _HashEntry {
    int key;
    int value;
    int valid;
} HashEntry;
typedef struct _Vertex {
    int index;
    int x_coor;
    int y_coor;
    int visited;
    int dist;
    int heap_loc;
    struct _Vertex* prev;
} Vertex;
typedef struct _AdjacencyNode {
    Vertex* vertex;
    int index;
    int cost;
    struct _AdjacencyNode* next_node;
} AdjacencyNode;
int _parse_first_int_from_string(char* str);
int _parse_second_int_from_string(char* str);
int _parse_third_int_from_string(char* str);
void add_node_to_end_of_list(AdjacencyNode* adjnode, AdjacencyNode* newnode);
void print_adjacency_node(AdjacencyNode* a_node);
void print_adjacency_list(AdjacencyNode** a_list, int node_count, Vertex**);
int list_adjacent(char* filename, AdjacencyNode*** a_list, Vertex*** v_list, HashEntry** hash_table);
void destroy_node(AdjacencyNode* node);
void destroy_list(AdjacencyNode** a_list, int node_count);
int path_cost(Vertex* v1, Vertex* v2);
int return_list_index(HashEntry*, int, int);
void add_list_index(HashEntry*, int, int, int);
int hash_code(int, int);
#endif
