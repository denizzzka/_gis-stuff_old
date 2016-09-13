module math.graph.undirected_compressed;

import dproto.dproto;
import math.graph.undirected;
import compression.compressed_array;
import compression.compressible_pbf_struct;


static struct pbf
{
    mixin ProtocolBuffer!"undirected_graph_compressed.proto";
}

class UndirectedGraphCompressed( NodePayload, EdgePayload ): UndirectedBase!( NodePayload, EdgePayload )
{
    alias UndirectedBase!(NodePayload, EdgePayload) Super;
    alias CompressiblePbfStruct!(pbf.Node) Node;
    alias CompressiblePbfStruct!(pbf.Edge) Edge;
    
    alias CompressedArray!( Node, 100 ) CompressedNodesArr;
    alias CompressedArray!( Edge, 10 ) CompressedEdgesArr;
    
    private const CompressedNodesArr nodes;
    private const CompressedEdgesArr edges;
    
    this( UndirectedGraph!( NodePayload, EdgePayload ) g )
    {
        {
            CompressedNodesArr nodes = new CompressedNodesArr;
            
            foreach( ref n; g.getNodesRange )
            {
                Node node;
                
                node.payload = g.getNodePayload(n).Serialize;
                
                foreach( ref e; g.getEdgesRange( n ) )
                {
                    auto global = g.getGlobalEdgeDescr( e );
                    
                    node.global_edge_idx ~= global.idx.to!uint;
                }
                
                nodes ~= node;
            }
            
            this.nodes = nodes;
        }
        {
            CompressedEdgesArr edges = new CompressedEdgesArr;
            
            foreach( ref e; g.edges )
            {
                Edge edge;
                
                edge.from_node_idx = e.connection.from.idx.to!uint;
                edge.to_node_idx = e.connection.to.idx.to!uint;
                edge.payload = e.payload.Serialize;
                
                edges ~= edge;
            }
            
            this.edges = edges;
        }
    }
    
    override size_t getNodesNum() const
    {
        return nodes.length;
    }
    
    override size_t getNodeEdgesNum( inout NodeDescr node ) const
    {
        auto n = nodes[node.idx];

        return n.global_edge_idx.length;
    }
    
    override protected GlobalEdgeDescr getGlobalEdgeDescr( inout EdgeDescr edge ) const
    in
    {
        auto node = edge.node;
        
        assert( node.idx < nodes.length );
        assert( edge.idx < nodes[ node.idx ].edges.length );
    }
    body
    {
        auto node = edge.node;
        
        GlobalEdgeDescr res = { idx: nodes[ node.idx ].global_edge_idx[ edge.idx ] };
        
        return res;
    }
    
    override const(NodePayload) getNodePayload( inout NodeDescr node ) const
    {
        return NodePayload.Deserialize( nodes[ node.idx ].payload );
    }
    
    override protected const(Super.Edge) getGlobalEdge( inout GlobalEdgeDescr global ) const
    {
        auto e = edges[global.idx];
        
        Super.Edge res =
            {
                connection:
                {
                    from: NodeDescr( e.from_node_idx ),
                    to: NodeDescr( e.to_node_idx )
                },
                payload: EdgePayload.Deserialize( e.payload )
            };
        
        return res;
    }
}

unittest
{
    import compression.pb_encoding;
    
    static struct Val
    {
        short v;
        alias v this;
        
        ubyte[] Serialize() const // node
        {
            return packVarint( v );
        }
        
        ubyte[] Serialize( Val unused ) const // edge
        {
            return packVarint( v );
        }
        
        static Val Deserialize( inout ubyte[] data )
        {
            Val res;
            const offset = res.v.unpackVarint( &data[0] );
            
            assert( offset == data.length );
            
            return res;
        }
    }
    
    auto t1 = new UndirectedGraph!( Val, Val );
    
    alias UndirectedGraphCompressed!( Val, Val ) UGC;
    
    auto t2 = new UGC( t1 );
}
