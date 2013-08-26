module roads;

// TODO: road -> multiline:
import map_graph: MapCoords, Point, TRoadGraph, Road, TRoadDescription;


struct TEdge( _Weight, _Payload )
{
    alias _Payload Payload;
    alias _Weight Weight;
    
    static TEdge[] edges;
    
    Direction forward;
    Direction backward;
    
    const Payload payload;
    
    struct Direction
    {
        size_t to_node; /// direction
        Weight weight;
        
        invariant()
        {
            assert( weight >= 0 );
        }
    }
    
    struct DirectedEdge
    {
        private size_t global_edge_idx;
        
        bool forward_direction;
        
        this( size_t edge_idx, bool forward_direction )
        {
            this.global_edge_idx = edge_idx;
            this.forward_direction = forward_direction;
        }
        
        ref const (Payload) payload() const
        {
            return getEdge().payload;
        }
        
        size_t to_node() const
        {
            return getDirection.to_node;
        }
        
        float weight() const
        {
            return getDirection.weight;
        }
        
        private
        ref Direction getDirection() const
        {
            if( forward_direction )
                return getEdge().forward;
            else
                return getEdge().backward;
        }
        
        private
        ref const TEdge getEdge() const
        {
            return TEdge.edges[ global_edge_idx ];
        }
    }
    
    static size_t addToEdges( TEdge edge )
    {
        edges ~= edge;
        
        return edges.length - 1;
    }
}

struct TNode( _Edge, _Point )
{
    alias _Point Point;
    alias _Edge Edge;
    
    private size_t[] edges_idxs;
    
    const Point point;
    
    struct EdgesRange
    {
        private
        {
            const TNode* node;
            const size_t from_node_idx;
            size_t edge_idx;
        }
        
        Edge.DirectedEdge front()
        {
            return opIndex( edge_idx );
        }
        
        // TODO: dangerous ability, need to remove
        Edge.DirectedEdge opIndex( size_t idx )
        {
            size_t global_idx = node.edges_idxs[ idx ];
            Edge* edge = &Edge.edges[ global_idx ];
            
            bool forward_direction = edge.forward.to_node != from_node_idx;
            
            auto res = Edge.DirectedEdge( global_idx, forward_direction );
            
            return res;
        }
        
        void popFront() { ++edge_idx; }
        bool empty() const { return edge_idx >= length; }
        size_t length() const { return node.edges_idxs.length; }
    }
    
    EdgesRange edges( size_t from_node_idx ) const
    {
        return EdgesRange( &this, from_node_idx );
    }
    
    void addEdge( size_t edge_idx )
    {
        edges_idxs ~= edge_idx;
    }
}

alias TEdge!( float, Road ) Edge;
alias TNode!( Edge, Point ) Node;

alias TRoadGraph!( MapCoords, Node ) RoadGraph;
