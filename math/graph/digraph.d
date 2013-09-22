module math.graph.digraph;

import std.random: uniform;


package
class DirectedBase( NodePayload, EdgePayload )
{
    struct NodeDescr
    {
        package size_t idx;
        this( size_t idx ){ this.idx = idx; }
    }
    
    immutable auto NodeMagic = NodeDescr( -1 );
    
    struct EdgeDescr
    {
        NodeDescr node;
        private size_t idx;
        
        this( NodeDescr node, size_t idx )
        {
            this.node = node;
            this.idx = idx;
        }
    }
    
    struct Edge
    {
        NodeDescr to_node;
        EdgePayload payload;
    }
    
    struct Node
    {
        NodePayload payload;
        private Edge[] edges;
        
        private size_t addEdge( Edge edge )
        {
            edges ~= edge;
            
            return edges.length - 1;
        }
    }
        
    struct ConnectionInfo
    {
        NodeDescr from;
        NodeDescr to;
    }
    
    abstract size_t getNodesNum() const;
    
    NodeDescr getRandomNode() const
    {
        return NodeDescr( uniform( 0, getNodesNum ) );
    }
    
    void forAllEdges( void delegate( EdgeDescr edge ) dg ) const
    {
        for( auto n = NodeDescr( 0 ); n.idx < getNodesNum(); n.idx++ )
            foreach( ref e; getEdgesRange( n ) )
                dg( e );
    }
    
    abstract protected const(Node) getNode( inout NodeDescr node ) const;
    
    abstract const(NodePayload) getNodePayload( inout NodeDescr node ) const;
    
    struct EdgesRange
    {
        private
        {
            const DirectedBase graph;
            EdgeDescr edge;
        }
        
        EdgeDescr front() { return edge; }
        void popFront() { ++edge.idx; }
        bool empty() const { return edge.idx >= length; }
        size_t length() const { return graph.getNode( edge.node ).edges.length; }
    }
    
    EdgesRange getEdgesRange( in NodeDescr node ) const
    {
        EdgesRange res = {
                graph: this,
                EdgeDescr( node, 0 )
            };
        
        return res;
    }
}

class DirectedGraph( NodePayload, EdgePayload ) : DirectedBase!( NodePayload, EdgePayload )
{
    private Node[] nodes;
    
    NodeDescr addNode( NodePayload nodePayload )
    {
        auto res = NodeDescr( nodes.length );
        
        Node n = { payload: nodePayload };
        nodes ~= n;
        
        return res;
    }
    
    EdgeDescr addEdge( in ConnectionInfo conn, EdgePayload edgePayload )
    {
        Edge e = { to_node: conn.to, payload: edgePayload };
        
        return EdgeDescr(
                conn.from,
                nodes[ conn.from.idx ].addEdge( e )
            );
    }
    
    override const(Node) getNode( inout NodeDescr node ) const
    {
        return nodes[ node.idx ];
    }
    
    override
    const(NodePayload) getNodePayload( inout NodeDescr node ) const
    {
        return nodes[ node.idx ].payload;
    }
    
    ref const(Edge) getEdge( in EdgeDescr edge ) const
    in
    {
        auto node = edge.node;
        
        assert( node.idx < nodes.length );
        assert( edge.idx < nodes[ node.idx ].edges.length );
    }
    body
    {
        auto node = edge.node;
        return nodes[ node.idx ].edges[ edge.idx ];
    }
    
    override
    size_t getNodesNum() const
    {
        return nodes.length;
    }
    
    bool isAvailable( in NodeDescr nd ) const
    {
        return nd.idx < nodes.length;
    }
}

unittest
{
    auto t1 = new DirectedGraph!( float, double );
}
