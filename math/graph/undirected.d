module math.graph.undirected;

import std.random: uniform;
import std.algorithm: sort;


package
class UndirectedBase( NodePayload, EdgePayload )
{
    struct NodeDescr
    {
        package size_t idx;
        this( size_t idx ){ this.idx = idx; }
    }
    
    immutable static auto NodeMagic = NodeDescr( -1 );
    
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
    
    package struct GlobalEdgeDescr { private size_t idx; }
    
    struct ConnectionInfo
    {
        NodeDescr from;
        NodeDescr to;
    }
    
    struct Edge
    {
        const ConnectionInfo connection;
        
        EdgePayload payload;
    }
    
    struct DirectedEdge
    {
        const Edge* edge;
        alias edge this;
        const bool forward_direction;
        
        NodeDescr to_node() const
        {
            return forward_direction ? edge.connection.to : edge.connection.from;
        }
    }
    
    abstract size_t getNodesNum() const;
    
    struct NodesRange
    {
        private
        {
            const UndirectedBase graph;
            NodeDescr node;
        }
        
        NodeDescr front() { return node; }
        void popFront() { ++node.idx; }
        bool empty() const { return node.idx >= length; }
        size_t length() const { return graph.getNodesNum(); }
    }
    
    NodesRange getNodesRange() const
    {
        NodesRange res = {
                graph: this,
                NodeDescr( 0 )
            };
            
        return res;
    }
}

class UndirectedGraph( NodePayload, EdgePayload ): UndirectedBase!( NodePayload, EdgePayload )
{
    struct Node
    {
        private GlobalEdgeDescr[] edges;
        
        NodePayload payload;
        
        private
        size_t addEdge( GlobalEdgeDescr edge )
        {
            edges ~= edge;
            
            return edges.length - 1;
        }
    }
    
    private Node[] nodes;
    package Edge[] edges;
    
    bool isAvailable( in NodeDescr nd ) const
    {
        return nd.idx < nodes.length;
    }
    
    NodeDescr addNode( NodePayload v )
    {
        auto res = NodeDescr( nodes.length );
        
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
        
        return EdgeDescr(
                conn.from,
                nodes[ conn.from.idx ].addEdge( global )
            );
    }
    
    ref const(NodePayload) getNodePayload( in NodeDescr node ) const
    {
        return nodes[ node.idx ].payload;
    }
    
    DirectedEdge getEdge( in EdgeDescr edge ) const
    in
    {
        auto node = edge.node;
        
        assert( node.idx < nodes.length );
        assert( edge.idx < nodes[ node.idx ].edges.length );
    }
    body
    {
        auto node = edge.node;
        
        GlobalEdgeDescr global = nodes[ node.idx ].edges[ edge.idx ];
        
        const (Edge)* e = &edges[ global.idx ];
        
        DirectedEdge directed = {
                edge: e,
                forward_direction: e.connection.from == node
            };
        
        return directed;
    }
    
    override size_t getNodesNum() const
    {
        return nodes.length;
    }
    
    NodeDescr getRandomNode() const
    {
        return NodeDescr( uniform( 0, nodes.length ) );
    }
    
    void forAllNodes( void delegate( NodeDescr node ) dg ) const
    {
        for( auto n = NodeDescr( 0 ); n.idx < nodes.length; n.idx++ )
            dg( n );
    }
    
    void forAllEdges( void delegate( EdgeDescr edge ) dg ) const
    {
        void nodeDg( NodeDescr node )
        {
            foreach( e; getEdgesRange( node ) )
                if( getEdge( e ).forward_direction )
                    dg( e );
        }
        
        forAllNodes( &nodeDg );
    }
    
    struct EdgesRange
    {
        private
        {
            const UndirectedGraph graph;
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
            edge: EdgeDescr( node, 0 )
        };
        
        return res;
    }
    
    EdgeDescr getFirstEdgeDescr( in NodeDescr node ) const
    {
        auto range = getEdgesRange( node );
        
        assert( range.length );
        
        return range.front();
    }
    
    void sortEdges(T)( T delegate( in EdgeDescr edge, in EdgeDescr edge ) less )
    {
        void sortNode( NodeDescr node )
        {
            EdgeDescr[] be_sorted;
            
            foreach( e; getEdgesRange( node ) )
                be_sorted ~= e;
            
            sort!( less )( be_sorted );
            
            GlobalEdgeDescr[] res_edges;
            
            foreach( e; be_sorted )
                res_edges ~= nodes[ node.idx ].edges[ e.idx ];
                
            nodes[ node.idx ].edges = res_edges;
        }
        
        forAllNodes( &sortNode );
    }
}

unittest
{
    auto t = new UndirectedGraph!( float, double );
}
