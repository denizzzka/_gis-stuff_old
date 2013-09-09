module math.graph.iface;


interface IGraph( NodePayload, EdgePayload, NodeDescr, EdgeDescr )
{
    NodeDescr addNode( NodePayload nodePayload );
    
    struct ConnectionInfo
    {
        NodeDescr from;
        NodeDescr to;
    }
    
    EdgeDescr addEdge( in ConnectionInfo ci, EdgePayload edgePayload );
    
    ref EdgePayload getEdgePayload( in NodeDescr node, in EdgeDescr edge );
}
