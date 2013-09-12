module math.graph.digraph;

import std.random: uniform;


class DirectedGraph( NodePayload, EdgePayload )
{
    struct NodeDescr { private size_t idx; }
    
    immutable NodeDescr NodeMagic = { idx: size_t.max }; // magic for correct path reconstruct
    
    struct EdgeDescr
    {
        NodeDescr node;
        private size_t idx;
    }
    
    struct Edge
    {
        NodeDescr to_node;
        
        EdgePayload payload;
    }
    
    struct Node
    {
        private Edge[] edges;
        
        NodePayload payload;
        
        private
        EdgeDescr addEdge( Edge edge )
        {
            EdgeDescr res = { idx: edges.length };
            
            edges ~= edge;
            
            return res;
        }
    }
    
    private Node[] nodes;
    
    bool isAvailable( in NodeDescr nd ) const
    {
        return nd.idx < nodes.length;
    }
    
    NodeDescr addNode( NodePayload nodePayload )
    {
        NodeDescr res = { idx: nodes.length };
        
        Node n = { payload: nodePayload };
        nodes ~= n;
        
        return res;
    }
    
    struct ConnectionInfo
    {
        NodeDescr from;
        NodeDescr to;
    }
    
    EdgeDescr addEdge( in ConnectionInfo conn, EdgePayload edgePayload )
    {
        Edge e = { to_node: conn.to, payload: edgePayload };
        
        return nodes[ conn.from.idx ].addEdge( e );
    }
    
    ref const(NodePayload) getNodePayload( in NodeDescr node ) const
    {
        return nodes[ node.idx ].payload;
    }
    
    ref const(Edge) getEdge( in NodeDescr node, in EdgeDescr edge ) const
    in
    {
        assert( node.idx < nodes.length );
        assert( edge.idx < nodes[ node.idx ].edges.length );
    }
    body
    {
        return nodes[ node.idx ].edges[ edge.idx ];
    }
    
    NodeDescr getRandomNode() const
    {
        NodeDescr res = { idx: uniform( 0, nodes.length ) };
        return res;
    }
    
    void forAllEdges( void delegate( NodeDescr node, EdgeDescr edge ) dg ) const
    {
        for( NodeDescr n = { idx: 0 }; n.idx < nodes.length; n.idx++ )
            foreach( ref e; getEdgesRange( n ) )
                dg( n, e );
    }
    
    struct EdgesRange
    {
        private
        {
            const DirectedGraph graph;
            EdgeDescr edge;
        }
        
        EdgeDescr front() { return edge; }
        void popFront() { ++edge.idx; }
        bool empty() const { return edge.idx >= length; }
        size_t length() const { return graph.nodes[ edge.node.idx ].edges.length; }
    }
    
    EdgesRange getEdgesRange( in NodeDescr node ) const
    {
        EdgesRange res =
        {
            graph: this,
            edge:
            {
                node: node,
                idx: 0
            }
        };
        
        return res;
    }
}

unittest
{
    auto t = new DirectedGraph!( float, double );
}
