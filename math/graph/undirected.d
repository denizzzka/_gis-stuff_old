module math.graph.undirected;

import math.graph.iface;


struct NodeDescr { size_t idx; }
struct EdgeDescr { size_t idx; }

class UndirectedGraph( Point, EdgePayload ) : IGraph!( Point, EdgePayload, NodeDescr, EdgeDescr )
{
    struct Edge
    {
        ConnectionInfo connection;
        
        EdgePayload payload;
    }
    
    private struct GlobalEdgeDescr { size_t idx; }
    
    struct Node
    {
        private GlobalEdgeDescr[] edges;
        
        Point point;
        
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
    
    NodeDescr addPoint( Point v )
    {
        NodeDescr res = { idx: nodes.length };
        
        Node n = { point: v };
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
