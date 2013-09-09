module math.graph.iface;


interface IGraph( Point, EdgePayload, NodeDescr, EdgeDescr )
{
    NodeDescr addPoint( Point point );
    
    EdgeDescr addEdge( ConnectionInfo )( ConnectionInfo ci, EdgePayload edgePayload );
    
    const (EdgePayload)* getEdgePayload( in NodeDescr node, in EdgeDescr edge ) const;
}
