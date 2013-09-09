module math.graph.iface;


interface IGraph( Point, EdgePayload, NodeDescr, EdgeDescr )
{
    NodeDescr addPoint( Point point );
    
    struct ConnectionInfo
    {
        NodeDescr from;
        NodeDescr to;
    }
    
    EdgeDescr addEdge( in ConnectionInfo ci, EdgePayload edgePayload );
    
    ref EdgePayload getEdgePayload( in NodeDescr node, in EdgeDescr edge );
}
