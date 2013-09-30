module math.graph.digraph_compressed;

static import pbf = pbf.digraph_compressed;
import math.graph.digraph;
import compression.compressed_array;
import compression.pb_encoding;


class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedBase!( NodePayload, EdgePayload )
{
    struct Node
    {
        pbf.Node node;
        alias node this;
        
        ubyte[] compress()
        out(r)
        {
            Node d;
            size_t offset = d.decompress(&r[0]);
            
            assert( offset == r.length );
            assert( payload.isNull == d.payload.isNull );
        }
        body
        {
            auto bytes = node.Serialize;
            auto size = packVarint(bytes.length);
            
            return size ~ bytes;
        }
        
        size_t decompress( inout ubyte* from )
        {
            size_t blob_size;
            size_t offset = blob_size.unpackVarint( from );
            size_t end = offset + blob_size;
            
            auto arr = from[offset..end].dup;
            node = Deserialize( arr );
            
            return end;
        }
    }
    
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
