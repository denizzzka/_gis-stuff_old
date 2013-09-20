module math.graph.digraph;

import std.random: uniform;
import std.traits;


class DirectedGraph( NodePayload, EdgePayload ) : DirectedGraph!( NodePayload, EdgePayload, "none" )
{
}

class DirectedGraph( NodePayload, EdgePayload, alias Storage )
{
    private
    {
        static if( isSomeString!(typeof(Storage)) ) // "none"
            Node[] nodes;
        else
            Storage!Node nodes = new Storage!Node;
    }
    
    struct NodeDescr
    {
        private size_t idx;
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
        
        ubyte[] compress() const работать_здесь
        {
            ubyte[] res;
            
            return res;
        }
        
        size_t decompress( inout ubyte* from )
        {
            return 1;
        }
    }
    
    struct Edge
    {
        NodeDescr to_node;
        
        EdgePayload payload;
        
        ubyte[] compress() const
        {
            ubyte[] res;
            
            return res;
        }
        
        size_t decompress( inout ubyte* from )
        {
            return 1;
        }
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
        
        ubyte[] compress() const
        {
            ubyte[] res;
            
            return res;
        }
        
        size_t decompress( inout ubyte* from )
        {
            return 1;
        }
    }
    
    bool isAvailable( in NodeDescr nd ) const
    {
        return nd.idx < nodes.length;
    }
    
    NodeDescr addNode( NodePayload nodePayload )
    {
        auto res = NodeDescr( nodes.length );
        
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
        
        return EdgeDescr(
                conn.from,
                nodes[ conn.from.idx ].addEdge( e )
            );
    }
    
    ref const(NodePayload) getNodePayload( inout NodeDescr node ) const
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
    
    NodeDescr getRandomNode() const
    {
        return NodeDescr( uniform( 0, nodes.length ) );
    }
    
    void forAllEdges( void delegate( EdgeDescr edge ) dg ) const
    {
        for( auto n = NodeDescr( 0 ); n.idx < nodes.length; n.idx++ )
            foreach( ref e; getEdgesRange( n ) )
                dg( e );
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
        EdgesRange res = {
                graph: this,
                EdgeDescr( node, 0 )
            };
        
        return res;
    }
}

unittest
{
    auto t1 = new DirectedGraph!( float, double );
    
    import compression.compressed;
    import compression.digraph;
    
    static class Compressed(T) : CompressedArray!( T, 3 ){}
    
    auto t2 = new DirectedGraph!( float, double, Compressed );
}
