module math.graph.digraph;

import math.graph.iface;


struct EdgeDescr
{
    size_t idx;
}

struct NodeDescr
{
    size_t idx;
}

class DirectedGraph( Point, EdgePayload ) : IGraph!( Point, EdgePayload, NodeDescr, EdgeDescr )
{
    struct Edge
    {
        size_t to_node;
        EdgePayload payload;
    }
    
    struct Node
    {
        private Edge[] edges;
        
        Point point;
        
        EdgeDescr addEdge( Edge edge )
        {
            EdgeDescr res = { idx: edges.length };
            
            edges ~= edge;
            
            return res;
        }
    }
    
    private Node[] nodes;
    
    NodeDescr addPoint( Point v )
    {
        NodeDescr res = { idx: nodes.length };
        
        Node n = { point: v };
        nodes ~= n;
        
        return res;
    }
    
    EdgeDescr addEdge( in NodeDescr fromNode, Edge edge )
    {
        return nodes[ fromNode.idx ].addEdge( edge );
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
