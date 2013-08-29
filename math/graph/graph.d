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
    
    Edge[] edges;
    
    Point point;
    
    void addEdge( Edge edge )
    {
        edges ~= edge;
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
    
    auto getEdge( size_t node_idx, size_t edge_idx )
    {
        return nodes[ node_idx ].edges[ edge_idx ];
    }
}
