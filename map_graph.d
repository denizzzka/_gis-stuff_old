module map_graph;

import math.geometry;
import math.rtree2d;
import math.graph.graph: Graph, TEdge, TNode;
import osm: OsmCoords = Coords, encodedToMapCoords, ReadPrimitiveException;
import map: MapCoords = Coords;
import cat = categories: Line;
static import config.map;
import math.earth: mercator2coords, getSphericalDistance;

import std.algorithm: canFind;
import std.random: uniform;
import std.stdio;


struct TPolylineDescription( _Coords, _ForeignCoords )
{
    alias _Coords Coords;
    alias _ForeignCoords ForeignCoords;
    alias Box!Coords BBox;
    
    ulong nodes_ids[];
    cat.Line type;
    ulong way_id;
    
    this( ulong[] nodes_ids, cat.Line type, in ForeignCoords[ulong] nodes = null )
    in
    {
        assert( nodes_ids.length >= 2 );
    }
    body
    {
        this.nodes_ids = nodes_ids;
        this.type = type;
        
        // checking
        if( nodes )
            for( size_t i = 0; i < nodes_ids.length; i++ )
                getNodeForeignCoords( nodes, i );
    }
    
    @disable this();
    
    this(this)
    {
        nodes_ids = nodes_ids.dup;
    }
    
    private
    const (ForeignCoords*) getNodeForeignCoords(
            in ForeignCoords[ulong] nodes,
            in size_t node_idx
        ) const
    in
    {
        assert( node_idx < nodes_ids.length );
    }
    body
    {
        auto node_id = nodes_ids[ node_idx ];
        
        auto node_ptr = node_id in nodes;
        
        if( !node_ptr )
            throw new ReadPrimitiveException( "polyline node "~to!string( node_id )~" is not found" );
        
        return node_ptr;
    }        
    
    private
    Coords getNode( in ForeignCoords[ulong] nodes, in size_t node_idx ) const
    {
        return encodedToMapCoords( *getNodeForeignCoords( nodes, node_idx ) );
    }
    
    BBox getBoundary( in ForeignCoords[ulong] nodes ) const
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
    
    cat.Line type = cat.Line.OTHER;
    
    this( Coords[] points, cat.Line type )
    {
        this.points = points;
        this.type = type;
    }
    
    @disable this();
    
    ref config.map.PolylineProperties properties() const
    {
        return config.map.polylines.getProperty( type );
    }
}

struct Point
{
    alias MapCoords Coords; // for template
    
    MapCoords coords;
    
    this( MapCoords coords )
    {
        this.coords = coords;
    }
    
    float distance( in Point v, in float weight ) const
    {
        return heuristic( v ) * weight;
    }
    
    float heuristic( in Point v ) const
    {
        return getSphericalDistance( getRadiansCoords, v.getRadiansCoords );
    }
    
    auto getRadiansCoords() const
    {
        return mercator2coords( coords );
    }
}

struct TPolylineDescriptor( MapGraph )
{
    alias MapGraph.Coords Coords;
    alias MapGraph.BBox BBox;
    alias TPolyline!Coords Polyline;
    
    uint node_idx;
    uint edge_idx;
    
    this( uint node_idx, uint edge_idx )
    {
        this.node_idx = node_idx;
        this.edge_idx = edge_idx;
    }
    
    Coords[] getPoints( in MapGraph mapGraph ) const
    {
        Coords[] res;
        
        auto start_node = &mapGraph.graph.nodes[ node_idx ];
        
        res ~= start_node.point.coords;
        
        auto edge = start_node.edges[ edge_idx ];
        
        foreach( c; edge.payload.points )
            res ~= c;
        
        auto end_node_idx = edge.to_node;
        res ~= mapGraph.graph.nodes[ end_node_idx ].point.coords;
        
        return res;
    }
    
    BBox getBoundary( in MapGraph mapGraph ) const
    {
        auto points = getPoints( mapGraph );
        assert( points.length > 0 );
        
        auto res = BBox( points[0], Coords(0,0) );
        
        for( auto i = 1; i < points.length; i++ )
            res.addCircumscribe( points[i] );
        
        return res;
    }
    
    ref const (Polyline) getPolyline( in MapGraph mapGraph ) const
    {
        return getEdge( mapGraph ).payload;
    }
    
    private
    auto getEdge( in MapGraph mapGraph ) const
    {
        auto node = mapGraph.graph.nodes[ node_idx ];
        
        return node.edges[ edge_idx ];
    }
}

class TMapGraph( _Node, alias CREATE_EDGE )
{
    alias _Node Node;
    alias Node.Point.Coords Coords;
    alias Node.Edge Edge;
    alias Box!Coords BBox;
    alias TPolylineDescriptor!TMapGraph PolylineDescriptor;
    
    alias Graph!Node G;
    
    public // TODO: need to be a package
    {
        G graph;
    }
    
    this( ForeignCoords, PolylineDescription )(
            in ForeignCoords[ulong] nodes,
            scope PolylineDescription[] descriptions
        )
    in
    {
        static assert( is( ForeignCoords == PolylineDescription.ForeignCoords ) );
    }
    body
    {
        alias RTreePtrs!( BBox, PolylineDescription ) DescriptionsTree;
        
        auto descriptions_tree = new DescriptionsTree;
        
        foreach( i, c; descriptions )
        {
            BBox boundary = c.getBoundary( nodes );
            
            descriptions_tree.addObject( boundary, c );
        }
        
        auto prepared = descriptions_tree.preparePolylines( nodes );
        
        graph = new G;
        
        graph.descriptionsToPolylineGraph!CREATE_EDGE( prepared, nodes );
    }
    
    PolylineDescriptor[] getDescriptors() const
    {
        PolylineDescriptor[] res;
        
        foreach( j, ref const node; graph.nodes )
            for( auto i = 0; i < node.edges.length; i++ )
                res ~= PolylineDescriptor( j, i );
        
        return res;
    }
        
    static struct Polylines
    {
        PolylineDescriptor*[] descriptors;
        const TMapGraph map_graph;
        
        this( in TMapGraph graph )
        {
            map_graph = graph;
        }
        
        Coords[] getPoints( in size_t descriptor_idx ) const
        {
            auto descriptor = descriptors[ descriptor_idx ];
            return descriptor.getPoints( map_graph );
        }
    }
    
    size_t getRandomNodeIdx() const
    {
        return uniform( 0, graph.nodes.length );
    }
}

/// Cuts lines on crossings
private
DescriptionsTree.Payload[] preparePolylines(DescriptionsTree, ForeignCoords)(
        in DescriptionsTree lines_rtree,
        in ForeignCoords[ulong] nodes
    )
{
    alias DescriptionsTree.Payload PolylineDescription;
    alias DescriptionsTree.Box BBox;
    alias BBox.Vector Coords;
    
    PolylineDescription[] res;
    auto all_lines = lines_rtree.search( lines_rtree.getBoundary );
    
    foreach( lineptr; all_lines )
    {
        PolylineDescription line = *lineptr;
        
        for( auto i = 1; i < line.nodes_ids.length - 1; i++ )
        {
            auto curr_point = line.nodes_ids[i];
            auto point_bbox = BBox(
                    encodedToMapCoords( nodes[ curr_point ] ),
                    Coords(0, 0)
                );
            auto near_lines = lines_rtree.search( point_bbox );
            
            foreach( n; near_lines )
                if( n != lineptr && canFind( n.nodes_ids, curr_point ) )
                {
                    res ~= line[ 0..i+1 ];
                    
                    line = line[ i..line.nodes_ids.length ];
                    i = 0;
                    break;
                }
        }
        
        res ~= line;
    }
    
    return res;
}
unittest
{
    alias MapCoords Coords;
    alias OsmCoords FC; // foreign coords
    alias TPolylineDescription!(Coords, FC) PolylineDescription;
    alias Box!Coords BBox;
    alias RTreePtrs!( BBox, PolylineDescription ) DescriptionsTree;
    
    alias TPolyline!Coords Polyline;
    alias TEdge!Polyline Edge;
    alias TNode!( Edge, Point ) Node;
    
    alias TMapGraph!( Node, createEdge ) G;
    
    FC[] points = [
            FC(0,0), FC(1,1), FC(2,2), FC(3,3), FC(4,4), // first line
            FC(4,0), FC(3,1), FC(1,3), FC(2,4) // second line
        ];
    
    FC[ulong] nodes;
    
    foreach( i, c; points )
        nodes[ i * 10 ] = c;
    
    ulong[] n1 = [ 0, 10, 20, 30, 40 ];
    ulong[] n2 = [ 50, 60, 20, 70, 80, 30 ];
    
    auto w1 = PolylineDescription( n1, cat.Line.HIGHWAY );
    auto w2 = PolylineDescription( n2, cat.Line.PRIMARY );
    
    auto lines = new DescriptionsTree;
    lines.addObject( w1.getBoundary( nodes ), w1 );
    lines.addObject( w2.getBoundary( nodes ), w2 );
    
    auto prepared = preparePolylines( lines, nodes );
    
    assert( prepared.length == 5 );
    
    auto g = new G( nodes, [ w1, w2 ] );
}

private
void descriptionsToPolylineGraph( alias CREATE_EDGE, Graph, PolylineDescription, ForeignCoords )(
        ref Graph graph,
        in PolylineDescription[] descriptions,
        in ForeignCoords[ulong] nodes
    )
in
{
    static assert( is( ForeignCoords == PolylineDescription.ForeignCoords ) );
}
body
{
    alias PolylineDescription.Coords Coords;
    alias TPolyline!Coords Polyline;
    
    size_t[ulong] already_stored;
    
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
    
    foreach( line; descriptions )
    {
        assert( line.nodes_ids.length >= 2 );
        
        Coords points[];
        
        for( auto i = 1; i < line.nodes_ids.length - 1; i++ )
            points ~= encodedToMapCoords( nodes[ line.nodes_ids[i] ] );
        
        auto poly = Polyline( points, line.type );
        
        auto from_node_idx = addPoint( line.nodes_ids[0] );
        auto to_node_idx = addPoint( line.nodes_ids[$-1] );
                
        CREATE_EDGE( graph, from_node_idx, to_node_idx, line, poly );
    }
}

void createEdge( Graph, PolylineDescriptor, Payload )(
        Graph graph,
        in size_t from_node_idx,
        in size_t to_node_idx,
        PolylineDescriptor descr,
        Payload payload )
{
    Graph.Edge edge = { to_node: to_node_idx, payload: payload };
    
    graph.addEdge( from_node_idx, edge );
}

alias TPolyline!MapCoords Polyline;
alias TEdge!Polyline Edge;
alias TNode!( Edge, Point ) Node;

alias TMapGraph!( Node, createEdge ) LineGraph;
