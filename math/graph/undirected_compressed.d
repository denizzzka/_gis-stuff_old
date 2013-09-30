module math.graph.undirected_compressed;

static import pbf = pbf.undirected_graph_compressed;
import math.graph.undirected;
import compression.compressed_array;
import compression.compressible_pbf_struct;


class UndirectedGraphCompressed( NodePayload, EdgePayload ): UndirectedBase!( NodePayload, EdgePayload )
{    
    alias CompressiblePbfStruct!(pbf.Node) Node;
    
    alias CompressedArray!( Node, 3 ) CompressedNodesArr;
    private const CompressedNodesArr nodes;
    
    this( UndirectedGraph!( NodePayload, EdgePayload ) g )
    {
        CompressedNodesArr nodes;
        
        foreach( ref n; g.getNodesRange )
        {
        }
        
        this.nodes = nodes;
    }
    
    override size_t getNodesNum() const
    {
        return nodes.length;
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
