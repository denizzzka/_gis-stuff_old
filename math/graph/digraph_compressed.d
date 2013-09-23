module math.graph.digraph_compressed;

static import pbf = pbf.digraph_compressed;
import math.graph.digraph;
import compression.compressed: CompressedArray;

import std.traits;


class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedBase!( NodePayload, EdgePayload )
{
    alias BaseClassesTuple!DirectedGraphCompressed[0] Super;
    
    struct Node
    {
        pbf.Node node;
        alias node this;
        
        ubyte[] compress()
        {
            return node.Serialize;
        }
        
        size_t decompress( inout ubyte* from )
        {
            size_t size;
            size.unpackVarint( from );
            
            auto arr = cast(ubyte[]) from[0..size];
            node.Deserialize( arr );
            
            return size;
        }
    }
    
    alias CompressedArray!( Node, 3 ) CompressedArr;
    
    private const CompressedArr nodes;
    
    this( Digraph )( Digraph g )
    if( isInstanceOf!(DirectedGraph, Digraph) )
    {
        CompressedArr nodes;
        
        foreach( ref n; g.getNodesRange )
        {
            Node node;
            
            foreach( ref e; g.getEdgesRange( n ) )
            {
                pbf.Edge edge;
                
                auto edge_ptr = &g.getEdge( e );
                
                edge.to_node_idx = edge_ptr.to_node.idx;
                edge.payload = edge_ptr.payload.Serialize;
                
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
        NodePayload res;
        return res;
        //return nodes[ node.idx ].payload.Deserialize!NodePayload;
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
                payload: Deserialize!EdgePayload( e.payload.get )
            };
        
        return res;
    }
}

version(unittest)
{
    import compression.pb_encoding;
    
    static ubyte[] Serialize(T)( inout T x )
    if( is( T == short ) || is( T == ulong ) )
    {
        T t = cast(T) x;
        return packVarint( t );
    }
    
    static T Deserialize(T)( inout ubyte[] data )
    if( is( T == short ) || is( T == ulong ) )
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
