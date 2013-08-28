module math.graph.graph;

debug import math.geometry;
debug(graph) import std.stdio;

import std.algorithm;
import std.range: isInputRange;


struct TEdge( _Weight, _Payload )
{
    alias _Payload Payload;
    alias _Weight Weight;
    
    const size_t to_node; /// direction
    Weight weight;
    Payload payload;
    
    invariant()
    {
        assert( weight >= 0 );
    }
}

struct TNode( _Edge, _Point )
{
    alias _Point Point;
    alias _Edge Edge;
    
    Edge[] edges_storage;
    
    Point point;
    
    struct EdgesRange
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
    alias Edge.Weight Weight;
    
private:
    
    // TODO: remove it
    size_t[ Node.Point ] points; /// AA used for fast search of stored points
    
    invariant()
    {
        //assert( isInputRange( typeof( Node.edges ) ) ); // FIXME
    }
    
public:
    
    Node[] nodes; /// contains nodes with all payload    
    
    size_t addPoint( in Node.Point v )
    {
        auto p = ( v in points );
        
        if( p !is null )
            return *p;
        else
        {
            points[v] = nodes.length;
            
            Node n = { point: v };
            nodes ~= n;
            
            return nodes.length-1;
        }
    }
    
    void addEdge(T)( in size_t from_idx, T edge )
    {
        nodes[ from_idx ].addEdge( edge );
    }
    
    // TODO: remove it?
    void addEdgeToPayload(T)( in Node.Point from, T edge )
    {
        size_t from_idx = addPoint( from );
        
        addEdge( from_idx, edge );
    }
    
    bool search( in Node.Point point, out size_t index )
    {
        auto p = point in points;
        
        if( p is null )
            return false;
        else
        {
            index = *p;
            return true;
        }
    }
}
