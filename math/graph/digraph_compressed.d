module math.graph.digraph_compressed;

import math.graph.digraph: DirectedBase;
import compression.compressed;

import std.traits;


//class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedGraph!( NodePayload, EdgePayload, "none" )
//{
//}

class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedBase!( NodePayload, EdgePayload )
{
}

unittest
{
    static class Compressed(T) : CompressedArray!( T, 3 ){}
    
    auto t1 = new DirectedGraphCompressed!( float, double );
}
