module math.graph.graph;

debug import math.geometry;
debug(graph) import std.stdio;

import std.algorithm;


struct TEdge( _Payload )
{
    alias _Payload Payload;
    
    const size_t to_node; /// direction
    Payload payload;
}

class Graph( _Node )
{
    alias _Node Node;
    alias Node.Edge Edge;
    
    Node[] nodes; /// contains nodes with all payload    
    
    size_t addPoint( Node.Point v )
    {
        Node n = { point: v };
        nodes ~= n;
        
        return nodes.length-1;
    }
    
    void addEdge( in size_t from_node_idx, Edge edge )
    {
        nodes[ from_node_idx ].addEdge( edge );
    }
}
