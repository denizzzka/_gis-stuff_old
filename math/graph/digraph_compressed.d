module math.graph.digraph_compressed;

static import pbf = pbf.digraph_compressed;
import math.graph.digraph;
import compression.compressed: CompressedArray;
import compression.pb_encoding;

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
    
    this()( DirectedGraph!( NodePayload, EdgePayload ) g )
    {
        auto nodes = new CompressedArr;
        
        foreach( ref n; g.getNodesRange )
        {
            Node node;
            
            auto node_payload = getNodePayload(n);
            node.payload = node_payload.Serialize;
            
            foreach( ref e; g.getEdgesRange( n ) )
            {
                pbf.Edge edge;
                
                auto edge_ptr = &g.getEdge( e );
                
                edge.to_node_idx = edge_ptr.to_node.idx;
                edge.payload = edge_ptr.payload.Serialize( node_payload );
                
                if( node.edges.isNull ) // init nullified array?
                {
                    pbf.Edge[] zero_length;
                    node.edges = zero_length;
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
    
    alias DirectedGraphCompressed!( Val, Val ) CDG;
    
    auto t2 = new CDG( t1 );
}
