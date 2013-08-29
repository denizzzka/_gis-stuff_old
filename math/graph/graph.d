module math.graph.graph;


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
    
    private Edge[] edges_storage;
    
    Point point;
    
    void addEdge( Edge edge )
    {
        edges_storage ~= edge;
    }
    
    auto edgesFromNode( in size_t from_node_idx ) const
    {
        return edges_storage;
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
    
    void addBidirectionalEdge()( Edge edge )
    {
        size_t to_idx = edge.forward.to_node;
        size_t from_idx = edge.backward.to_node;
        
        auto edge_idx = nodes[ from_idx ].addEdge( edge ); // from --> to
        nodes[ to_idx ].addEdge( edge_idx ); // to --> from
    }
    
    ref auto getEdge()( in size_t node_idx, in size_t edge_idx ) const
    {
        return nodes[ node_idx ].edgesFromNode( node_idx )[ edge_idx ];
    }
}
