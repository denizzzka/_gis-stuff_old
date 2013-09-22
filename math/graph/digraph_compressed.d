module math.graph.digraph_compressed;

import math.graph.digraph: DirectedBase;
import compression.compressed;

import std.traits;


//class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedGraph!( NodePayload, EdgePayload, "none" )
//{
//}

class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedBase!( NodePayload, EdgePayload )
{
    alias BaseClassesTuple!DirectedGraphCompressed[0] Super;
    
    struct Node
    {
        Super.Node node;
        alias node this;
        
        ubyte[] compress() const
        {
            ubyte[] res; // = node.compress;
            //res ~= idx.compress;
            
            return res;
        }
        
        size_t decompress( inout ubyte* from )
        {
            return 1;
        }
    }
    
    alias CompressedArray!( Node, 3 ) NodesArray;
    private NodesArray nodes;
    
    this()
    {
        nodes = new NodesArray;
    }
    
    override size_t getNodesNum() const
    {
        return nodes.length;
    }
    
    override const(Super.Node) getNode( inout NodeDescr node ) const
    {
        return nodes[ node.idx ];
    }
    
    override const(NodePayload) getNodePayload( inout NodeDescr node ) const
    {
        return nodes[ node.idx ].payload;
    }
}

unittest
{
    static class Compressed(T) : CompressedArray!( T, 3 ){}
    
    auto t1 = new DirectedGraphCompressed!( float, double );
}
