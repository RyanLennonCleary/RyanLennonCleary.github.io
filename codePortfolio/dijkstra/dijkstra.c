#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "adjacent.h"
#include "dijkstra.h"

void create_min_heap(Vertex*** Q, Vertex** vertex_list, int node_count){
    if (*Q == NULL) {
    Vertex** vertex_min_heap = malloc(node_count * sizeof *vertex_min_heap);    
    *Q = vertex_min_heap;
    }
    int i = 0;
    for (i = 0; i < node_count; i++){
        (*Q)[i] = vertex_list[i];
        (*Q)[i]->visited = 0;
        (*Q)[i]->dist = -1;
        (*Q)[i]->heap_loc = i;
    }
}
void upward_heapify(Vertex** Q, int node_count, int node){
    Vertex* temp = NULL;
    int child = 0;
    int parent;
    child = node;
    parent = (child - 1) / 2;
    if (parent >= 0 && Q[child] != NULL && Q[child]->dist != -1 && (Q[parent] == NULL || Q[child]->dist < Q[parent]->dist || Q[parent]->dist == -1)){
        temp = Q[parent];
        Q[parent] = Q[child];
        Q[child] = temp;
        if (Q[parent] != NULL) {
        Q[parent]->heap_loc = parent;
        }
        if (Q[child] != NULL) {
        Q[child]->heap_loc = child;
        }
        upward_heapify(Q, node_count, parent);
    }

}

void downward_heapify(Vertex** Q, int node_count, int i){
    int parent_dist = -1;
    int left_child_dist = -1;
    int right_child_dist = -1;
    Vertex* temp = NULL;
    if (i * 2 + 1 < node_count && Q[i * 2 + 1] != NULL){
        left_child_dist = Q[i * 2 + 1]->dist;
    } else {
        left_child_dist = -1;
    }
    if (i * 2 + 2 < node_count && Q[i * 2 + 2] !=NULL) {
        right_child_dist = Q[i * 2 + 2]->dist;
    } else {
        right_child_dist = -1;
    }
    if (Q[i] != NULL) {
        parent_dist = Q[i]->dist;
    } else {
        parent_dist = -1;
    }
    if ((left_child_dist < parent_dist || parent_dist == -1) && (left_child_dist <= right_child_dist || right_child_dist == -1) && left_child_dist != -1){
        temp = Q[i];
        Q[i] = Q[i * 2 + 1];
        Q[i * 2 + 1] = temp;
        if (Q[i] != NULL){
        Q[i]->heap_loc = i;
        }
        if (Q[i * 2 + 1] != NULL) {
        Q[ i * 2 + 1]->heap_loc = i * 2 + 1;
        }
        downward_heapify(Q, node_count, i * 2 + 1);
    }
    else if ((right_child_dist < parent_dist || parent_dist == -1) && (right_child_dist < left_child_dist || left_child_dist == -1)  && right_child_dist != -1){
        temp = Q[i];
        Q[i] = Q[i * 2 + 2];
        Q[i * 2 + 2] = temp;
        if (Q[i] != NULL){
        Q[i]->heap_loc = i;
        }
        if (Q[i * 2 + 2] != NULL) {
        Q[ i * 2 + 2]->heap_loc = i * 2 + 2;
        }
        downward_heapify(Q, node_count, i * 2 + 2);
    }
}
void remove_root(Vertex** Q, int node_count){
    Q[0] = Q[node_count - 1];
    //printf("replacing root with last element  %d\n",Q[node_count - 1]->index);
    Q[node_count-1] = NULL;
    downward_heapify(Q, node_count, 0);
}

void print_path(Vertex** vertex_list, int destination, int source, HashEntry* hash_table, int node_count){
    Vertex current = *(vertex_list[return_list_index(hash_table, destination, node_count)]);
    printf("%d\n",current.dist);
    print_path_node(current, source);
    printf("\n");
}

void print_path_node(Vertex current, int source) {
    if (current.index != source) {
        Vertex prev = *current.prev;
        print_path_node(prev, source);
    }
    printf("%d ",current.index);
}
void find_shortest_path(Vertex** Q, Vertex** vertex_list, AdjacencyNode** adjacency_list, int node_count, int source, int destination, HashEntry* hash_table){
    bool is_there_query = source >= 0 && destination >= 0 && return_list_index(hash_table, destination, node_count) > -1;
    if (is_there_query) {
        Vertex* current = vertex_list[return_list_index(hash_table, source, node_count)];
        current->dist = 0;
        upward_heapify(Q, node_count, current->heap_loc);
        remove_root(Q, node_count);
        AdjacencyNode* neighbor = adjacency_list[return_list_index(hash_table, current->index, node_count)];
        int proposed_distance = 0;
        while(current != NULL && vertex_list[return_list_index(hash_table, destination, node_count)]->visited == 0){
            while (neighbor != NULL /*&& neighbor->vertex->visited == 0*/){
                //printf("current node: %d\n",current->index);
                //printf("current neighbor: %d\n",neighbor->index);
                proposed_distance = current->dist + neighbor->cost;
                if (proposed_distance < neighbor->vertex->dist || neighbor->vertex->dist == -1) {
                    neighbor->vertex->dist = proposed_distance;
                    neighbor->vertex->prev = current;
                    upward_heapify(Q, node_count, neighbor->vertex->heap_loc);
                }
                neighbor = neighbor->next_node;
            }
            current->visited = 1;
            current = Q[0];
            if (current != NULL) {
                neighbor = adjacency_list[return_list_index(hash_table, current->index, node_count)];
                remove_root(Q, node_count);
            } else {
                neighbor = NULL;
            }
        }
        if (vertex_list[return_list_index(hash_table, destination, node_count)] == NULL || vertex_list[return_list_index(hash_table, destination, node_count)]->dist != -1){
    Vertex dest = *(vertex_list[return_list_index(hash_table, destination, node_count)]);
    printf("%d\n",dest.dist);
    print_path_node(dest, source);
    printf("\n");
        } else {
            printf("INF\n%d %d\n",source, destination);
        }
    } else {
        printf("INF\n%d %d\n",source, destination);
    }

    //    else if (source >= node_count){
    //        printf("INF\n%d %d", source, destination);
    //    }
}

void read_query(char* queryname, int* n_q, int** q) {
    FILE* file;
    file = fopen(queryname, "r");
    char line[256];
    int number_queries = 0;
    fgets(line, sizeof line, file);
    number_queries = _parse_first_int_from_string(line);
    if (number_queries == 0) {
        *q = NULL;

    }
    else {
        int i = 0;
        int* queries = malloc(2 * number_queries * sizeof *queries); 
        while(fgets(line, sizeof line, file)) {
            queries[i] = _parse_first_int_from_string(line);
            queries[i+1] =  _parse_second_int_from_string(line);
            i=i + 2;
        }
        *q = queries;
    }
    *n_q = number_queries;
    fclose(file);
}
