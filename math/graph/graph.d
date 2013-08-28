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
    
    void addEdge( SIZE_T )( in SIZE_T from_node_idx, Edge edge )
    {
        nodes[ from_node_idx ].addEdge( edge );
    }
    
    void addEdge( SIZE_T )( in SIZE_T from_node_idx, in SIZE_T to_node_idx, Edge edge )
    {
        Node* to_node = &nodes[ to_node_idx ];
        
        nodes[ from_node_idx ].addEdge( edge, to_node );
    }
}
