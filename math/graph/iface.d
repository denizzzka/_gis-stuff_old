module math.graph.iface;


struct EdgeIdx
{
    size_t edgeIdx;
}

struct NodeIdx
{
    size_t nodeIdx;
}

interface IGraph( Point, EdgePayload )
{
    NodeIdx addPoint( Point point );
    
    EdgeIdx addEdge( ConnectionInfo )( ConnectionInfo ci, EdgePayload edgePayload );
    
    ref EdgePayload getEdgePayload( in size_t node_idx, in size_t edge_idx ) const;
}
