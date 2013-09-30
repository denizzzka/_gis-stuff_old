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
