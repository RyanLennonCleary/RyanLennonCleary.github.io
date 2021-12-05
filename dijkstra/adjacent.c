#include <math.h>
#include "adjacent.h"
#include <stdio.h>
#include <stdlib.h>
int _parse_first_int_from_string(char* str){
    int first_int = 0;
    long l;
    l = strtol(str, NULL, 10);
    first_int = (int)l;
    return first_int;
}

int _parse_second_int_from_string(char* str){
    int second_int = 0;
    long l;
    char* endptr;
    strtol(str, &endptr, 10);
    l = strtol(endptr, NULL, 10);
    second_int = (int)l;
    return second_int;
}

int _parse_third_int_from_string(char* str) {
    int third_int = 0;
    long l;
    char* endptr;
    char* endptr2;
    strtol(str, &endptr, 10);
    strtol(endptr, &endptr2, 10);
    l = strtol(endptr2, NULL, 10);
    third_int = (int)l;
    return third_int;
}

void add_node_to_end_of_list(AdjacencyNode* adjnode, AdjacencyNode* newnode){
    if (adjnode->next_node != NULL) {
        add_node_to_end_of_list(adjnode->next_node, newnode);
    } else {
        adjnode->next_node = newnode;
    }
}

void print_adjacency_node(AdjacencyNode* a_node){
    if (a_node != NULL) {
        printf(" %d",a_node->index);
        print_adjacency_node(a_node->next_node);
    }
}

void print_adjacency_list(AdjacencyNode** a_list, int node_count, Vertex** vertex_list) {
    int i = 0;
    for (i = 0; i < node_count; i++) {
        printf("%d:", vertex_list[i]->index);
        print_adjacency_node(a_list[i]);
        printf("\n");
    }
}
int path_cost(Vertex* v1, Vertex* v2) {
    int distance = 0;
    double x = 0;
    double y = 0;
    double p = 0;
    double q = 0;
    x = v1->x_coor;
    y = v1-> y_coor;
    p = v2->x_coor;
    q = v2->y_coor;
    distance = sqrt(pow(p-x,2) + pow(q-y,2));
    return distance;
}

int return_list_index(HashEntry* hash_table, int vertex_label, int node_count){
    int i = 0;
    int hash = hash_code(vertex_label, node_count);
    while (hash_table[hash].key != vertex_label && i < node_count){
        hash++;
        hash = hash % node_count;
        i++;
    }
    int adjacency_list_index = 0;
    if (i == node_count){
        adjacency_list_index = -1;
    } else {
    adjacency_list_index = hash_table[hash].value;
    }
    return adjacency_list_index;
}

int hash_code(int label, int node_count){
    return label % node_count;
}

void add_list_index(HashEntry* hash_table, int vertex_label, int adj_list_index, int node_count){
    HashEntry new_entry;
    new_entry.key = vertex_label;
    new_entry.value = adj_list_index;
    int hash = hash_code(vertex_label, node_count);
    while(hash_table[hash].valid == 1) {
        hash++;
    }
    hash_table[hash].key = vertex_label;
    hash_table[hash].value = adj_list_index;
    hash_table[hash].valid = 1;
}

int list_adjacent(char* filename, AdjacencyNode*** a_list, Vertex*** v_list, HashEntry** h_t){
    FILE* file;
    file = fopen(filename,"r");
    int node_count = 0;
    int edge_count = 0;
    char line[256];
    fgets(line, sizeof line, file);
    node_count = _parse_first_int_from_string(line);
    edge_count = _parse_second_int_from_string(line);
    int i = 0;
    Vertex** vertex_list = malloc(node_count * sizeof *vertex_list);
    HashEntry* hash_table = calloc(node_count, sizeof* hash_table);
    for(i = 0; i < node_count; i++) {
        fgets(line, sizeof line, file);
        Vertex* new_vertex = malloc(sizeof *new_vertex);
        new_vertex->index = _parse_first_int_from_string(line);
        new_vertex->x_coor = _parse_second_int_from_string(line);
        new_vertex->y_coor = _parse_third_int_from_string(line);
        new_vertex->visited = 0;
        new_vertex->dist = 0; //inf
        new_vertex->prev = NULL;
        new_vertex->heap_loc = -1;
        vertex_list[i] = new_vertex;
        add_list_index(hash_table, new_vertex->index, i, node_count);
    }        
    AdjacencyNode** adjacency_list = calloc(node_count, sizeof *adjacency_list);
    int left_vertex = 0;
    int right_vertex = 0;
    for (i = 0; i < edge_count; i++) {
        AdjacencyNode* new_node1 = malloc(sizeof *new_node1);
        AdjacencyNode* new_node2 = malloc(sizeof *new_node2);
        fgets(line, sizeof line, file);
        left_vertex = _parse_first_int_from_string(line);
        right_vertex = _parse_second_int_from_string(line);
        new_node1->index = right_vertex;
        new_node1->next_node = NULL;
        new_node1->vertex = vertex_list[return_list_index(hash_table, right_vertex, node_count)];
        new_node2->index = left_vertex;
        new_node2->vertex = vertex_list[return_list_index(hash_table, left_vertex, node_count)];
        new_node2->next_node = NULL;
        new_node1->cost = path_cost(new_node1->vertex, new_node2->vertex);
        new_node2->cost = new_node1->cost;
        if (adjacency_list[return_list_index(hash_table, left_vertex, node_count)] != NULL) {
            add_node_to_end_of_list(adjacency_list[return_list_index(hash_table, left_vertex, node_count)], new_node1);
        } else {
            adjacency_list[return_list_index(hash_table, left_vertex, node_count)] = new_node1;
        }
        if (adjacency_list[return_list_index(hash_table, right_vertex, node_count)] != NULL) {
            add_node_to_end_of_list(adjacency_list[return_list_index(hash_table, right_vertex, node_count)], new_node2);
        } else {
            adjacency_list[return_list_index(hash_table, right_vertex, node_count)] = new_node2;
        }
    }
    fclose(file);
    *a_list = adjacency_list;
    *v_list = vertex_list;
    *h_t = hash_table;
    return node_count;
}

void destroy_node(AdjacencyNode* node){
    if (node != NULL){
        destroy_node(node->next_node);
    }
    free(node);
}

void destroy_list(AdjacencyNode** a_list, int node_count){
    int i = 0;
    for (i = 0; i < node_count; i++){
        destroy_node(a_list[i]);
    }
}

