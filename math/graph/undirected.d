module math.graph.undirected;

import std.random: uniform;


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
    
    // TODO: maybe blocking by weight will be better
    EdgeDescr addOnewayEdge( ConnectionInfo conn, EdgePayload edgePayload )
    {
        GlobalEdgeDescr global = { idx: edges.length };
        
        NodeDescr from = conn.from;
        
        conn.from = conn.to;
        
        Edge e = { connection: conn, payload: edgePayload };
        edges ~= e;
        
        return nodes[ from.idx ].addEdge( global );
    }
    
    ref const(NodePayload) getNodePayload( in NodeDescr node ) const
    {
        return nodes[ node.idx ].payload;
    }
    
    DirectedEdge getEdge( in NodeDescr node, in EdgeDescr edge ) const
    {
        GlobalEdgeDescr global = nodes[ node.idx ].edges[ edge.idx ];
        
        const (Edge)* e = &edges[ global.idx ];
        
        DirectedEdge directed = {
                edge: e,
                forward_direction: node == e.connection.from
            };
        
        return directed;
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
                if( getEdge( n, e ).connection.from == n )
                    dg( n, e );
    }
    
    struct EdgesRange
    {
        private
        {
            const UndirectedGraph graph;
            const NodeDescr node;
            EdgeDescr edge;
        }
        
        EdgeDescr front() { return edge; }
        void popFront() { ++edge.idx; }
        bool empty() const { return edge.idx >= length; }
        size_t length() const { return graph.nodes.length; }
    }
    
    EdgesRange getEdgesRange( in NodeDescr node ) const
    {
        EdgesRange res = { graph: this, node: node, edge: { idx: 0 } };
        return res;
    }
}

unittest
{
    auto t = new UndirectedGraph!( float, float );
}
