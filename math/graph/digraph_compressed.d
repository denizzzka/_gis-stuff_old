module math.graph.digraph_compressed;

import dproto.dproto;
import math.graph.digraph;
import compression.compressed_array;
import compression.compressible_pbf_struct;


static struct pbf
{
    mixin ProtocolBuffer!"digraph_compressed.proto";
}

class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedBase!( NodePayload, EdgePayload )
{
    alias Node = CompressiblePbfStruct!(pbf.Node);

    alias CompressedArray!( Node, 3 ) CompressedArr;
    private const CompressedArr nodes;
    
    this( DirectedGraph!( NodePayload, EdgePayload ) g )
    {
        CompressedArr nodes = new CompressedArr;
        
        foreach( ref n; g.getNodesRange )
        {
            Node node;
            
            node.payload = g.getNodePayload(n).Serialize;
            
            foreach( ref e; g.getEdgesRange( n ) )
            {
                pbf.Edge edge;
                
                auto orig_edge = &g.getEdge( e );
                
                edge.to_node_idx = orig_edge.to_node.idx;
                edge.payload = orig_edge.payload.Serialize;
                
                if(node.edges.isNull)
                {
                    pbf.Edge[] zero_length;
                    node.edges = zero_length; // init nullified PBF array
                }
                
                node.edges ~= edge;
            }
            
            nodes ~= node;
        }
        
        this.nodes = nodes;
    }
    
    override size_t getNodesNum() const
    {
        return nodes.length;
    }
    
    override size_t getNodeEdgesNum( inout NodeDescr node ) const
    {
        return nodes[ node.idx ].edges.length;
    }
    
    override const(NodePayload) getNodePayload( inout NodeDescr node ) const
    {
        return NodePayload.Deserialize( nodes[ node.idx ].payload );
    }
    
    Edge getEdge( in EdgeDescr edge ) const
    in
    {
        auto node = edge.node;
        
        assert( node.idx < getNodesNum );
        assert( edge.idx < getNodeEdgesNum( node ) );
    }
    body
    {
        auto node = edge.node;
        auto e = nodes[ node.idx ].edges.get[ edge.idx ];
        
        Edge res = {
                to_node: e.to_node_idx,
                payload: EdgePayload.Deserialize( e.payload.get )
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
    
    auto t1 = new DirectedGraph!( Val, Val );
    
    alias DirectedGraphCompressed!( Val, Val ) DGC;
    
    auto t2 = new DGC( t1 );
}
