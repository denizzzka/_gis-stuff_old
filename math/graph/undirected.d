module math.graph.undirected;


class UndirectedGraph( NodePayload, EdgePayload )
{
    struct NodeDescr { size_t idx; }
    struct EdgeDescr { size_t idx; }
    
    struct ConnectionInfo
    {
        NodeDescr from;
        NodeDescr to;
    }
    
    struct Edge
    {
        ConnectionInfo connection;
        
        EdgePayload payload;
    }
    
    private struct GlobalEdgeDescr { size_t idx; }
    
    struct Node
    {
        private GlobalEdgeDescr[] edges;
        
        NodePayload payload;
        
        private
        EdgeDescr addEdge( GlobalEdgeDescr edge )
        {
            EdgeDescr res = { idx: edges.length };
            
            edges ~= edge;
            
            return res;
        }
    }
    
    package Node[] nodes;
    private Edge[] edges;
    
    bool isAvailable( in NodeDescr nd ) const
    {
        return nd.idx < nodes.length;
    }
    
    NodeDescr addNode( NodePayload v )
    {
        NodeDescr res = { idx: nodes.length };
        
        Node n = { payload: v };
        nodes ~= n;
        
        return res;
    }
    
    EdgeDescr addEdge( in ConnectionInfo conn, EdgePayload edgePayload )
    {
        GlobalEdgeDescr global = { idx: edges.length };
        
        Edge e = { connection: conn, payload: edgePayload };
        edges ~= e;
        
        nodes[ conn.to.idx ].addEdge( global );
        return nodes[ conn.from.idx ].addEdge( global );
    }
    
    EdgeDescr addOnewayEdge( ConnectionInfo conn, EdgePayload edgePayload )
    {
        GlobalEdgeDescr global = { idx: edges.length };
        
        NodeDescr from = conn.from;
        
        conn.from = conn.to;
        
        Edge e = { connection: conn, payload: edgePayload };
        edges ~= e;
        
        return nodes[ from.idx ].addEdge( global );
    }
    
    ref EdgePayload getEdgePayload( in NodeDescr node, in EdgeDescr edge )
    {
        GlobalEdgeDescr global = nodes[ node.idx ].edges[ edge.idx ];
        
        return edges[ global.idx ].payload;
    }
}

unittest
{
    auto t = new UndirectedGraph!( float, float );
}
