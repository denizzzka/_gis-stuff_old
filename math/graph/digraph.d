module math.graph.digraph;

import math.graph.iface;

import std.random: uniform;


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
        
        private
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
    
    ref EdgePayload getEdgePayload( in NodeDescr node, in EdgeDescr edge )
    {
        return nodes[ node.idx ].edges[ edge.idx ].payload;
    }
    
    NodeDescr getRandomNode() const
    {
        NodeDescr res = { idx: uniform( 0, nodes.length ) };
        return res;
    }
    
    struct NodesRange
    {
        private
        {
            DirectedGraph graph;
            NodeDescr node;
        }
        
        NodeDescr front() { return node; }
        void popFront() { ++node.idx; }
        bool empty() const { return node.idx >= length; }
        size_t length() const { return graph.nodes.length; }
    }
    
    NodesRange getNodes() const
    {
        NodesRange res = { node: { idx: 0 } };
        return res;
    }
}

unittest
{
    auto t = new DirectedGraph!( float, float );
}
