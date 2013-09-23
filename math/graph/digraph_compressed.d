module math.graph.digraph_compressed;

import pbf = math.graph.digraph_compressed_pbf;
import math.graph.digraph: DirectedBase;
import compression.compressed;

import std.traits;


class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedBase!( NodePayload, EdgePayload )
{
    alias BaseClassesTuple!DirectedGraphCompressed[0] Super;
    
    struct Edge
    {
        Super.Edge edge;
        alias edge this;
        
        ubyte[] compress() const
        {
            pbf.Edge e;
            e.to_node_idx = to_node.idx;
            //e.payload = payload.compress;
            
            return e.Serialize;
        }        
    }
    
    struct Node
    {
        Super.Node node;
        alias node this;
        
        this( Super.Node n )
        {
            node = n;
        }
        
        ubyte[] compress() const
        {
            pbf.Node n;
            //n.edges = node.edges;
            
            return n.Serialize;
        }
        
        size_t decompress( inout ubyte* from )
        {
            return 1;
        }
    }
    
    alias CompressedArray!( Node, 10 ) NodesArray;
    private NodesArray nodes;
    
    this()
    {
        nodes = new NodesArray;
    }
    
    override size_t getNodesNum() const
    {
        return nodes.length;
    }
    
    override size_t getNodeEdgesNum( inout NodeDescr node ) const
    {
        return 666; // FIXME: // was: nodes[ node.idx ].edges.length;
    }
    
    override const(NodePayload) getNodePayload( inout NodeDescr node ) const
    {
        return nodes[ node.idx ].payload;
    }
}

unittest
{
    //static class Compressed(T) : CompressedArray!( T, 3 ){}
    
    auto t1 = new DirectedGraphCompressed!( float, double );
}
