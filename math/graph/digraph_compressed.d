module math.graph.digraph_compressed;

static import pbf = math.graph.digraph_compressed_pbf;
import math.graph.digraph: DirectedBase;
import compression.delta;

import std.traits;


class DirectedGraphCompressed( NodePayload, EdgePayload ) : DirectedBase!( NodePayload, EdgePayload )
{
    alias BaseClassesTuple!DirectedGraphCompressed[0] Super;
    
    struct Edge
    {
        Super.Edge edge;
        alias edge this;
        
        this( Super.Edge e )
        {
            edge = e;
        }
        
        pbf.Edge toPbf() const
        {
            pbf.Edge e;
            e.to_node_idx = to_node.idx;
            //e.payload = payload.toPbf;
            
            return e;
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
        
        pbf.Node toPbf() const
        {
            pbf.Node n;
            //n.payload = payload.toPbf;
            
            foreach( ref e; edges )
                n.edges ~= Edge(e).toPbf;
            
            return n;
        }
        
        size_t decompress( inout ubyte* from )
        {
            return 1;
        }
    }
    
    private pbf.DirectedGraph storage;
    
    this()
    {
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

unittest
{
    //static class Compressed(T) : CompressedArray!( T, 3 ){}
    
    auto t1 = new DirectedGraphCompressed!( float, double );
}
