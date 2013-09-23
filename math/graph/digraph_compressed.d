module math.graph.digraph_compressed;

static import pbf = math.graph.digraph_compressed_pbf;
import math.graph.digraph;
//import compression.delta;

import std.traits;


class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedBase!( NodePayload, EdgePayload )
{
    alias BaseClassesTuple!DirectedGraphCompressed[0] Super;
    
    private pbf.DirectedGraph storage;
    
    this( Digraph )( Digraph g )
    if( isInstanceOf!(DirectedGraph, Digraph) )
    {
        foreach( ref n; g.getNodesRange )
        {
            pbf.Node node;
            
            foreach( ref e; g.getEdgesRange( n ) )
            {
                pbf.Edge edge;
                edge.to_node_idx = g.getEdge( e ).to_node.idx;
            }
        }
    }
    
    override size_t getNodesNum() const
    {
        return storage.nodes.length;
    }
    
    override size_t getNodeEdgesNum( inout NodeDescr node ) const
    {
        return 666; // FIXME: // was: nodes[ node.idx ].edges.length;
    }
    
    override const(NodePayload) getNodePayload( inout NodeDescr node ) const
    {
        return 777; //storage.nodes[ node.idx ].payload;
    }
}

version(unittest)
{
    import compression.pb_encoding;
    
    static ubyte[] toPbf(T)( inout T x )
    {
        T t = cast(T) x;
        return packVarint( t );
    }
}

unittest
{
    auto t1 = new DirectedGraph!( float, double );
    
    alias DirectedGraphCompressed!( short, ulong ) CDG;
    
    auto t2 = new CDG( t1 );
}
