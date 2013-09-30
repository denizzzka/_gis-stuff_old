module math.graph.undirected_compressed;

import std.random: uniform;
import std.algorithm: sort;


class UndirectedGraphCompressed( NodePayload, EdgePayload ): UndirectedBase!( NodePayload, EdgePayload )
{
}

unittest
{
    auto t = new UndirectedGraphCompressed!( float, double );
}
