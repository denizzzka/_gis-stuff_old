module math.graph.digraph;

import math.graph.iface;


struct NodeDescr { size_t idx; }
struct EdgeDescr { size_t idx; }

class DirectedGraph( Point, EdgePayload ) : IGraph!( Point, EdgePayload, NodeDescr, EdgeDescr )
{
    struct Edge
    {
        NodeDescr to_node;
        EdgePayload payload;
    }
    
    struct Node
    {
        package Edge[] edges;
        
        Point point;
        
        EdgeDescr addEdge( Edge edge )
        {
            EdgeDescr res = { idx: edges.length };
            
            edges ~= edge;
            
            return res;
        }
    }
    
    package Node[] nodes;
    
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
        Edge e = { to_node: conn.to, payload: edgePayload };
        
        return nodes[ conn.from.idx ].addEdge( e );
    }
    
    const (EdgePayload)* getEdgePayload( in NodeDescr node, in EdgeDescr edge ) const
    {
        return &nodes[ node.idx ].edges[ edge.idx ].payload;
    }
}

unittest
{
    auto t = new DirectedGraph!( float, float );
}
