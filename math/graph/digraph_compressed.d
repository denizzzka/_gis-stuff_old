module math.graph.digraph_compressed;

static import pbf = math.graph.digraph_compressed_pbf;
import math.graph.digraph;

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
                
                auto edge_ptr = &g.getEdge( e );
                
                edge.to_node_idx = edge_ptr.to_node.idx;
                edge.payload = edge_ptr.payload.Serialize;
                
                node.edges ~= edge;
            }
            
            storage.nodes ~= node;
        }
    }
    
    override size_t getNodesNum() const
    {
        return storage.nodes.length;
    }
    
    override size_t getNodeEdgesNum( inout NodeDescr node ) const
    {
        return storage.nodes[ node.idx ].edges.length;
    }
    
    override const(NodePayload) getNodePayload( inout NodeDescr node ) const
    {
        return storage.nodes[ node.idx ].payload.Deserialize!NodePayload;
    }
}

version(unittest)
{
    import compression.pb_encoding;
    
    static ubyte[] Serialize(T)( inout T x )
    {
        T t = cast(T) x;
        return packVarint( t );
    }
    
    static T Deserialize(T)( inout ubyte[] data )
    {
        T res;
        const offset = res.unpackVarint( &data[0] );
        
        assert( offset == data.length );
        
        return res;
    }
}

unittest
{
    auto t1 = new DirectedGraph!( short, ulong );
    
    alias DirectedGraphCompressed!( short, ulong ) CDG;
    
    auto t2 = new CDG( t1 );
}
