module math.graph.undirected_compressed;

static import pbf = pbf.undirected_graph_compressed;
import math.graph.undirected;


class UndirectedGraphCompressed( NodePayload, EdgePayload ): UndirectedBase!( NodePayload, EdgePayload )
{
    this( UndirectedGraph!( NodePayload, EdgePayload ) g )
    {
    }
}

unittest
{
    alias UndirectedGraphCompressed!( float, double ) UGC;
    
    //auto t = new UGC("asd");
}
