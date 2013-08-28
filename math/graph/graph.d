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

struct TNode( _Edge, _Point )
{
    alias _Point Point;
    alias _Edge Edge;
    
    Edge[] edges_storage;
    
    Point point;
    
    struct EdgesRange // TODO: remove it?
    {
        private
        {
            const TNode* node;
            size_t edge_idx;
        }
        
        ref const (Edge) opIndex( size_t idx ) const
        {
            return node.edges_storage[ edge_idx ];
        }
        
        ref const (Edge) front() { return opIndex( edge_idx ); }
        void popFront() { ++edge_idx; }
        bool empty() const { return edge_idx >= length; }
        size_t length() const { return node.edges_storage.length; }
    }
    
    EdgesRange edges( size_t unused ) const
    {
        return EdgesRange( &this, 0 );
    }
    
    void addEdge( Edge edge )
    {
        edges_storage ~= edge;
    }
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
