module math.graph.undirected_compressed;

static import pbf = pbf.undirected_graph_compressed;
import math.graph.undirected;
import compression.compressed_array;
import compression.pb_encoding;


class UndirectedGraphCompressed( NodePayload, EdgePayload ): UndirectedBase!( NodePayload, EdgePayload )
{
    struct CompressiblePbfStruct(T)
    {
        T s;
        alias s this;
        
        ubyte[] compress()
        out(r)
        {
            CompressiblePbfStruct d;
            size_t offset = d.decompress(&r[0]);
            
            assert( offset == r.length );
        }
        body
        {
            auto bytes = s.Serialize;
            auto size = packVarint(bytes.length);
            
            return size ~ bytes;
        }
        
        size_t decompress( inout ubyte* from )
        {
            size_t blob_size;
            size_t offset = blob_size.unpackVarint( from );
            size_t end = offset + blob_size;
            
            auto arr = from[offset..end].dup;
            s = Deserialize( arr );
            
            return end;
        }
    }
    
    alias CompressiblePbfStruct!(pbf.Node) Node;
    
    alias CompressedArray!( Node, 3 ) CompressedNodesArr;
    private const CompressedNodesArr nodes;
    
    this( UndirectedGraph!( NodePayload, EdgePayload ) g )
    {
        CompressedNodesArr nodes;
        
        //foreach( ref n; g.getNodesRange )
        {
        }
        
        this.nodes = nodes;
    }
}

unittest
{
    alias UndirectedGraphCompressed!( float, double ) UGC;
    
    //auto t = new UGC("asd");
}
