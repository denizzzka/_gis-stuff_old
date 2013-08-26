module map_graph;

import math.geometry;
import math.rtree2d;
import math.graph: Graph;
import osm: OsmCoords = Coords, encodedToMapCoords;
import map: MapCoords = Coords;
import cat = categories: Road;
static import config.map;

import std.algorithm: canFind;
import std.random: uniform;
import std.exception: enforce;
import std.stdio;


struct TPolylineDescription( _Coords, _ForeignCoords )
{
    alias _Coords Coords;
    alias _ForeignCoords ForeignCoords;
    alias Box!Coords BBox;
    
    ulong nodes_ids[];
    cat.Road type;
    ulong way_id;
    
    this( ulong[] nodes_ids, cat.Road type, ulong way_id )
    in
    {
        assert( nodes_ids.length >= 2 );
    }
    body
    {
        this.nodes_ids = nodes_ids;
        this.type = type;
        this.way_id = way_id;
    }
    
    @disable this();
    
    this(this)
    {
        nodes_ids = nodes_ids.dup;
    }
    
    private
    Coords getNode( in ForeignCoords[long] nodes, in size_t node_idx ) const
    in
    {
        assert( node_idx < nodes_ids.length );
    }
    body
    {
        auto node_id = nodes_ids[ node_idx ];
        
        auto node_ptr = node_id in nodes;
        enforce( node_ptr, "node id="~to!string( node_id )~" is not found" );
        
        return encodedToMapCoords( *node_ptr );
    }
    
    BBox getBoundary( in ForeignCoords[long] nodes ) const
    in
    {
        assert( nodes_ids.length >= 2 );
    }
    body
    {
        auto start_node = getNode( nodes, 0 );
        auto res = BBox( start_node, Coords(0,0) );
        
        for( auto i = 1; i < nodes_ids.length; i++ )
        {
            auto curr_node = getNode( nodes, i );
            res.addCircumscribe( curr_node );
        }
        
        return res;
    }
    
    TPolylineDescription opSlice( size_t from, size_t to )
    {
        auto res = this;
        
        res.nodes_ids = nodes_ids[ from..to ];
        
        return res;
    }
}

struct TPolyline( Coords )
{
    private
    {
        Coords[] points; /// points between start and end points
    }
    
    cat.Road type = cat.Road.OTHER;
    
    this( Coords[] points, cat.Road type )
    {
        this.points = points;
        this.type = type;
    }
    
    @disable this();
    
    ref config.map.RoadProperties properties() const
    {
        return config.map.roads.getProperty( type );
    }
}

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

struct Point
{
    MapCoords coords;
    
    this( MapCoords coords )
    {
        this.coords = coords;
    }
    
    float distance( in Point v, in float weight ) const
    {
        return (coords - v.coords).length * weight;
    }
    
    float heuristic( in Point v ) const
    {
        return (coords - v.coords).length;
    }
}

@disable
auto boundary(T)( ref const T node )
{
    alias Box!osm.Coords BBox;
    
    auto res = BBox( node.point.coords, Coords(0,0) );
    
    for( auto i = 1; i < node.edges.length; i++ )
        res.addCircumscribe( node.edges[i].to_node.point.coords );
    
    return res;
}

class TRoadGraph( Coords, Node )
{
    alias Box!Coords BBox;
    alias TPolyline!Coords Road;
    alias RTreePtrs!( BBox, Road ) RoadsRTree;
    
    alias Node.Edge Edge;
    
    alias Graph!Node G;
    
    private
    {
        G graph;
    }
    
    this( ForeignCoords, RoadDescription )( in ForeignCoords[long] nodes, scope RoadDescription[] descriptions )
    in
    {
        static assert( is( ForeignCoords == RoadDescription.ForeignCoords ) );
    }
    body
    {
        alias RTreePtrs!( BBox, RoadDescription ) DescriptionsTree;
        
        auto descriptions_tree = new DescriptionsTree;
        
        foreach( i, c; descriptions )
        {
            BBox boundary;
            
            try
                boundary = c.getBoundary( nodes );
            catch( Exception e )
            {
                writeln("Way id=", c.way_id, " excluded: ", e.msg );
                continue;
            }
            
            descriptions_tree.addObject( boundary, c );
        }
        
        auto prepared = descriptions_tree.prepareRoads( nodes );
        
        graph = new G;
        
        graph.descriptionsToRoadGraph( prepared, nodes );
    }
    
    RoadDescriptor[] getDescriptors() const
    {
        RoadDescriptor[] res;
        
        foreach( j, ref const node; graph.nodes )
            for( auto i = 0; i < node.edges( j ).length; i++ )
                res ~= RoadDescriptor( j, i );
        
        return res;
    }
    
    static struct RoadDescriptor
    {
        uint node_idx;
        uint edge_idx;
        
        this( uint node_idx, uint edge_idx )
        {
            this.node_idx = node_idx;
            this.edge_idx = edge_idx;
        }
        
        Coords[] getPoints( in TRoadGraph roadGraph ) const
        {
            Coords[] res;
            
            auto start_node = &roadGraph.graph.nodes[ node_idx ];
            
            res ~= start_node.point.coords;
            
            auto edge = start_node.edges( node_idx )[ edge_idx ];
            
            foreach( c; edge.payload.points )
                res ~= c;
            
            auto end_node_idx = edge.to_node;
            res ~= roadGraph.graph.nodes[ end_node_idx ].point.coords;
            
            return res;
        }
        
        BBox getBoundary( in TRoadGraph roadGraph ) const
        {
            auto points = getPoints( roadGraph );
            assert( points.length > 0 );
            
            auto res = BBox( points[0], Coords(0,0) );
            
            for( auto i = 1; i < points.length; i++ )
                res.addCircumscribe( points[i] );
            
            return res;
        }
        
        ref const (Road) getRoad( in TRoadGraph roadGraph ) const
        {
            return getEdge( roadGraph ).payload;
        }
        
        private
        Edge.DirectedEdge getEdge( in TRoadGraph roadGraph ) const
        {
            auto node = roadGraph.graph.nodes[ node_idx ];
            
            return node.edges( node_idx )[ edge_idx ];
        }
    }
    
    static struct Roads
    {
        RoadDescriptor*[] descriptors;
        const TRoadGraph road_graph;
        
        this( in TRoadGraph graph )
        {
            road_graph = graph;
        }
        
        Coords[] getPoints( in size_t descriptor_idx ) const
        {
            auto descriptor = descriptors[ descriptor_idx ];
            return descriptor.getPoints( road_graph );
        }
    }
    
    RoadDescriptor[] findPath( size_t from_node_idx, size_t to_node_idx ) const
    {
        auto path = graph.findPath( from_node_idx, to_node_idx );
        
        debug(path) writeln("path from=", from_node_idx, " to=", to_node_idx);
        
        RoadDescriptor[] res;
        
        if( path != null )
            for( auto i = 1; i < path.length; i++ )
                res ~= RoadDescriptor( path[i].node_idx, path[i-1].came_through_edge_idx );
        
        return res;
    }
    
    size_t getRandomNodeIdx() const
    {
        return uniform( 0, graph.nodes.length );
    }
}

/// Cuts roads on crossroads for creating road graph
private
DescriptionsTree.Payload[] prepareRoads(DescriptionsTree, ForeignCoords)( in DescriptionsTree roads_rtree, in ForeignCoords[long] nodes )
{
    alias DescriptionsTree.Payload RoadDescription;
    alias DescriptionsTree.Box BBox;
    alias BBox.Vector Coords;
    
    RoadDescription[] res;
    auto all_roads = roads_rtree.search( roads_rtree.getBoundary );
    
    foreach( roadptr; all_roads )
    {
        RoadDescription road = *roadptr;
        
        for( auto i = 1; i < road.nodes_ids.length - 1; i++ )
        {
            auto curr_point = road.nodes_ids[i];
            auto point_bbox = BBox(
                    encodedToMapCoords( nodes[ curr_point ] ),
                    Coords(0, 0)
                );
            auto near_roads = roads_rtree.search( point_bbox );
            
            foreach( n; near_roads )
                if( n != roadptr && canFind( n.nodes_ids, curr_point ) )
                {
                    res ~= road[ 0..i+1 ];
                    
                    road = road[ i..road.nodes_ids.length ];
                    i = 0;
                    break;
                }
        }
        
        res ~= road;
    }
    
    return res;
}
unittest
{
    alias MapCoords Coords;
    alias OsmCoords FC; // foreign coords
    alias TPolylineDescription!(Coords, FC) RoadDescription;
    alias Box!Coords BBox;
    alias RTreePtrs!( BBox, RoadDescription ) DescriptionsTree;
    
    alias TPolyline!Coords Road;
    alias TEdge!( float, Road ) Edge;
    alias TNode!( Edge, Point ) Node;
    
    alias TRoadGraph!( Coords, Node ) G;
    
    FC[] points = [
            FC(0,0), FC(1,1), FC(2,2), FC(3,3), FC(4,4), // first road
            FC(4,0), FC(3,1), FC(1,3), FC(2,4) // second road
        ];
    
    FC[long] nodes;
    
    foreach( i, c; points )
        nodes[ i * 10 ] = c;
    
    ulong[] n1 = [ 0, 10, 20, 30, 40 ];
    ulong[] n2 = [ 50, 60, 20, 70, 80, 30 ];
    
    auto w1 = RoadDescription( n1, cat.Road.HIGHWAY, 111 );
    auto w2 = RoadDescription( n2, cat.Road.PRIMARY, 222 );
    
    auto roads = new DescriptionsTree;
    roads.addObject( w1.getBoundary( nodes ), w1 );
    roads.addObject( w2.getBoundary( nodes ), w2 );
    
    auto prepared = prepareRoads( roads, nodes );
    
    assert( prepared.length == 5 );
}

private
void descriptionsToRoadGraph( Graph, RoadDescription, ForeignCoords )( ref Graph graph, in RoadDescription[] descriptions, in ForeignCoords[long] nodes )
in
{
    static assert( is( ForeignCoords == RoadDescription.ForeignCoords ) );
}
body
{
    alias RoadDescription.Coords Coords;
    alias TPolyline!Coords Road;
    
    size_t[ulong] already_stored;
    
    // собственная функция нужна чтобы исключить пересечение между разными точками с одинаковыми координатами
    // TODO: наверное, с переходом на ranges эта функция останется, а в graph.d аналогичная будет удалена
    size_t addPoint( ulong node_id )
    {
        auto p = node_id in already_stored;
        
        if( p !is null )
            return *p;
        else
        {
            auto coord = node_id in nodes;
            
            assert( coord != null );
            
            auto point = Point( encodedToMapCoords( *coord ) );
            auto idx = graph.addPoint( point );
            already_stored[ node_id ] = idx;
            
            return idx;
        }
    }
    
    foreach( road; descriptions )
    {
        assert( road.nodes_ids.length >= 2 );
        
        Coords points[];
        
        for( auto i = 1; i < road.nodes_ids.length - 1; i++ )
            points ~= encodedToMapCoords( nodes[ road.nodes_ids[i] ] );
        
        auto r = Road( points, road.type );
        
        auto from_node_idx = addPoint( road.nodes_ids[0] );
        auto to_node_idx = addPoint( road.nodes_ids[$-1] );
        
        Graph.Edge.Direction forward = { to_node: to_node_idx, weight: 1.0 };
        Graph.Edge.Direction backward = { to_node: from_node_idx, weight: 1.0 };
        
        Graph.Edge edge = { forward: forward, backward: backward, payload: r };
        
        size_t edge_idx = Graph.Edge.addToEdges( edge );
        
        graph.addEdge( from_node_idx, edge_idx );
    }
}
