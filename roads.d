module roads;

import map_graph: MapCoords, Point, TMapGraph, TPolyline;
private import math.graph.pathfinder: findMathGraphPath = findPath;


struct TEdge( _Weight, _Payload )
{
    alias _Payload Payload;
    alias _Weight Weight;
    
    static TEdge[] edges;
    
    Direction forward;
    Direction backward;
    
    Payload payload;
    
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
        private const size_t global_edge_idx;
        private bool forward;
        
        bool forward_direction() const
        {
            return forward;
        }
        
        this( size_t edge_idx, bool forward_direction )
        {
            this.global_edge_idx = edge_idx;
            this.forward = forward_direction;
        }
        
        ref const (Payload) payload() const
        {
            return getEdge().payload;
        }
        
        size_t to_node() const
        {
            return getStraightDirection.to_node;
        }
        
        float weight() const
        {
            return getStraightDirection.weight;
        }
        
        private
        ref Direction getStraightDirection() const
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

void createEdge( Graph, Payload )(
        Graph graph,
        in size_t from_node_idx,
        in size_t to_node_idx,
        Payload payload )
{
    Graph.Edge.Direction forward = { to_node: to_node_idx, weight: 1.0 };
    Graph.Edge.Direction backward = { to_node: from_node_idx, weight: 1.0 };
    
    Graph.Edge edge = { forward: forward, backward: backward, payload: payload };
    
    graph.addBidirectionalEdge( edge );
}

struct TNode( _Edge, _Point )
{
    alias _Point Point;
    alias _Edge Edge;
    
    private size_t[] edges_idxs;
    
    const Point point;
    
    struct LogicalEdgesRange
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
    
    LogicalEdgesRange logicalEdges( size_t from_node_idx ) const
    {
        return LogicalEdgesRange( &this, from_node_idx );
    }
    
    struct EdgesRange
    {
        private
        {
            const TNode* node;
            size_t node_idx;
            size_t edge_idx;
        }
        
        Edge.DirectedEdge front()
        {
            return opIndex( edge_idx );
        }
        
        /// BUGS: returns all edges
        Edge.DirectedEdge opIndex( size_t idx )
        {
            size_t global_idx = node.edges_idxs[ idx ];
            Edge* edge = &Edge.edges[ global_idx ];
            
            bool forward_direction = node_idx == edge.forward.to_node;
            
            auto res = Edge.DirectedEdge( global_idx, forward_direction );
            
            return res;
        }
        
        void popFront() { ++edge_idx; }
        bool empty() const { return edge_idx >= length; }
        size_t length() const { return node.edges_idxs.length; }
    }    
    
    EdgesRange edges() const
    {
        return EdgesRange( &this );
    }
    
    EdgesRange edgesFromNode( size_t curr_node_idx ) const
    {
        return EdgesRange( &this, curr_node_idx );
    }
    
    size_t addEdge( Edge edge )
    {
        size_t global_idx = Edge.addToEdges( edge );
        
        addEdge( global_idx );
        
        return global_idx;
    }
    
    void addEdge( size_t global_idx )
    {
        edges_idxs ~= global_idx;
    }
}

alias TPolyline!MapCoords Road;
alias TEdge!( float, Road ) Edge;
alias TNode!( Edge, Point ) Node;

alias TMapGraph!( Node, createEdge ) RoadGraph;

RoadGraph.PolylineDescriptor[] findPath( in RoadGraph road_graph, size_t from_node_idx, size_t to_node_idx )
{
    auto path = findMathGraphPath( road_graph.graph, from_node_idx, to_node_idx );
    
    debug(path) writeln("path from=", from_node_idx, " to=", to_node_idx);
    
    RoadGraph.PolylineDescriptor[] res;
    
    if( path != null )
        for( auto i = 1; i < path.length; i++ )
            res ~= RoadGraph.PolylineDescriptor( path[i].node_idx, path[i-1].came_through_edge_idx );
    
    return res;
}

MapCoords[] getRoadPoints( in RoadGraph.PolylineDescriptor* descr, in RoadGraph roadGraph )
{
    MapCoords[] res;
    
    auto start_node = &roadGraph.graph.nodes[ descr.node_idx ];
    
    res ~= start_node.point.coords;
    
    auto edge = start_node.edgesFromNode( descr.node_idx )[ descr.edge_idx ];
    
    if( edge.forward_direction )
        foreach( c; edge.payload.points )
            res ~= c;
    else
        foreach_reverse( c; edge.payload.points )
            res ~= c;
    
    auto end_node_idx = edge.to_node;
    res ~= roadGraph.graph.nodes[ end_node_idx ].point.coords;
    
    return res;
}

Road getRoad( in RoadGraph.PolylineDescriptor* descr, in RoadGraph roadGraph )
{
    auto points = getRoadPoints( descr, roadGraph );
    auto type = descr.getEdge( roadGraph ).payload.type;
    
    return Road( points, type );
}
