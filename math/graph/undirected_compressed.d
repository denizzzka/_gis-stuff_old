module math.graph.undirected_compressed;

static import pbf = pbf.undirected_graph_compressed;
import math.graph.undirected;
import compression.compressed_array;
import compression.compressible_pbf_struct;


class UndirectedGraphCompressed( NodePayload, EdgePayload ): UndirectedBase!( NodePayload, EdgePayload )
{    
    alias CompressiblePbfStruct!(pbf.Node) Node;
    alias CompressiblePbfStruct!(pbf.Edge) Edge;
    
    alias CompressedArray!( Node, 3 ) CompressedNodesArr;
    alias CompressedArray!( Edge, 3 ) CompressedEdgesArr;
    
    private const CompressedNodesArr nodes;
    private const CompressedEdgesArr edges;
    
    this( UndirectedGraph!( NodePayload, EdgePayload ) g )
    {
        {
            CompressedNodesArr nodes;
            
            foreach( ref n; g.getNodesRange )
            {
                Node node;
                
                node.payload = g.getNodePayload(n).Serialize;
                
                /*
                foreach( ref e; g.getEdgesRange( n ) )
                {
                    pbf.Edge edge;
                    
                    auto orig_edge = g.getEdge( e );
                    
                    edge.to_node_idx = orig_edge.to_node.idx;
                    edge.payload = orig_edge.payload.Serialize;
                    
                    if(node.edges.isNull)
                    {
                        pbf.Edge[] zero_length;
                        node.edges = zero_length; // init nullified PBF array
                    }
                    
                    node.edges ~= edge;
                }
                */
                nodes ~= node;
            }
            
            this.nodes = nodes;
        }
        {
            CompressedEdgesArr edges;
            
            foreach( ref e; g.edges )
            {
                Edge edge;
                
                edge.from_node_idx = e.connection.from.idx;
                edge.to_node_idx = e.connection.to.idx;
                edge.payload = e.payload.Serialize;
                
                edges ~= edge;
            }
            
            this.edges = edges;
        }
    }
    
    override size_t getNodesNum() const
    {
        return nodes.length;
    }
}

unittest
{
    import compression.pb_encoding;
    
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
    
    auto t1 = new UndirectedGraph!( Val, Val );
    
    alias UndirectedGraphCompressed!( Val, Val ) UGC;
    
    auto t2 = new UGC( t1 );
}
