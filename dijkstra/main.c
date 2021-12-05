#include <stdio.h>
#include <stdlib.h>
#include "adjacent.h"
#include "dijkstra.h"
int main(int argc, char*argv[]){
    if (argc == 3) {
        char* filename = argv[1];
        AdjacencyNode** adjacency_list = NULL;
        Vertex** vertex_list = NULL;
        HashEntry* hash_table = NULL;
        int node_count = list_adjacent(filename, &adjacency_list, &vertex_list, &hash_table);
        print_adjacency_list(adjacency_list, node_count, vertex_list);    
        char* queryname = argv[2];
        int number_queries = 0;
        int* queries = NULL;
        read_query(queryname, &number_queries, &queries);
        Vertex** Q = NULL;
        int source = 0;
        int destination = 0;
        int i = 0;
        for (i = 0; i < 2 * number_queries; i = i + 2){
            source = queries[i];
            destination = queries[i + 1];
            create_min_heap(&Q, vertex_list, node_count); 
            find_shortest_path(Q, vertex_list, adjacency_list, node_count, source, destination, hash_table);
        }
        free(Q);
        destroy_list(adjacency_list, node_count);
        free(adjacency_list);
        free(hash_table);
        for (i = 0; i < node_count; i++){
            free(vertex_list[i]);
        }
        free(vertex_list);
        free(queries);
        return 0;
    } else {
        printf("include two command line arguments, a relative path to a graph file and query list\n");
        return 1;
    }
}
