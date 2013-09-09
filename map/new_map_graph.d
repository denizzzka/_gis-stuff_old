module map.new_map_graph;

import math.geometry;
import math.rtree2d;
import math.graph.graph: Graph, TEdge, TNode;
import map.map: MapCoords;
import cat = config.categories: Line;
static import config.map;
import math.earth: mercator2coords, getSphericalDistance;
import map.adapters: TPolylineDescription;

import std.algorithm: canFind;
import std.random: uniform;
import std.stdio;


struct TPolyline( Coords )
{
    public // need package here
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
        return mercator2coords( coords.getMercatorCoords );
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
    
    Coords[] getPoints()( in MapGraph mapGraph ) const
    {
        Coords[] res;
        
        auto start_node = &mapGraph.graph.nodes[ node_idx ];
        
        res ~= start_node.point.coords;
        
        auto edge = mapGraph.graph.getEdge( node_idx, edge_idx );
        
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
        
        auto res = BBox( points[0].map_coords, MapCoords.Coords(0,0) );
        
        for( auto i = 1; i < points.length; i++ )
            res.addCircumscribe( points[i].map_coords );
        
        return res;
    }
    
    ref const (Polyline) getPolyline()( in MapGraph mapGraph ) const
    {
        return getEdge( mapGraph ).payload;
    }
    
    private
    auto getEdge()( in MapGraph mapGraph ) const
    {
        return mapGraph.graph.getEdge( node_idx, edge_idx );
    }
}

class TMapGraph( _Node, alias CREATE_EDGE )
{
    alias _Node Node;
    alias Node.Point Point;
    alias Point.Coords Coords;
    alias Node.Edge Edge;
    alias Box!(Coords.Coords) BBox;
    alias TPolylineDescriptor!TMapGraph PolylineDescriptor;
    
    alias Graph!Node G;
    
    public // TODO: need to be a package
    {
        G graph;
    }
    
    this()()
    {
        graph = new G;
    }
    
    this( PolylineDescription )( scope PolylineDescription[] descriptions )
    {
        this();
        
        auto prepared = cutOnCrossings( descriptions );
        
        size_t[ulong] already_stored;
        
        foreach( line; descriptions )
            addPolyline( line, already_stored );
    }
    
    PolylineDescriptor addPolyline(
            Description,
            ForeignID = Description.ForeignNode.ForeignID
        )(
            Description line,
            ref size_t[ForeignID] already_stored
        )
    in
    {
        assert( line.nodes_ids.length >= 2 );
    }
    body
    {
        size_t last_node = line.nodes_ids.length - 1;
        
        auto from_node_idx = addPoint( line.getNode( 0 ), already_stored );
        auto to_node_idx = addPoint( line.getNode( last_node ), already_stored );
        
        Coords points[];
        
        for( auto i = 1; i < last_node; i++ )
            points ~= line.getNode( i ).getCoords;
        
        auto poly = Polyline( points, line.type );
                
        size_t edge_idx = CREATE_EDGE( graph, from_node_idx, to_node_idx, poly );
        
        return PolylineDescriptor( from_node_idx, edge_idx );
    }
    
    private
    size_t addPoint( ForeignNode, ForeignID = ForeignNode.ForeignID )(
            ForeignNode node,
            ref size_t[ ForeignID ] already_stored
        )
    {
        size_t* p = node.foreign_id in already_stored;
        
        if( p !is null )
            return *p;
        else
        {
            auto point = Point( node.getCoords );
            auto idx = graph.addPoint( point );
            already_stored[ node.foreign_id ] = idx;
            
            return idx;
        }
    }
    
    PolylineDescriptor[] getDescriptors() const
    {
        PolylineDescriptor[] res;
        
        foreach( node_idx, ref const node; graph.nodes )
            for( auto i = 0; i < node.edgesFromNode( node_idx ).length; i++ )
                res ~= PolylineDescriptor( node_idx, i );
        
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
        
        @disable
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

auto cutOnCrossings(DescriptionsTree)( in DescriptionsTree lines_rtree )
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
            auto curr_point_id = line.nodes_ids[i];
            auto point_bbox = BBox( line.getNode( i ).getCoords.map_coords, Coords(0, 0) );
            auto near_lines = lines_rtree.search( point_bbox );
            
            foreach( n; near_lines )
                if( n != lineptr && canFind( n.nodes_ids, curr_point_id ) )
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

Description[] cutOnCrossings( Description )( Description[] lines )
{
    alias Description.BBox BBox;
    alias RTreePtrs!( BBox, Description ) DescriptionsTree;
    
    auto tree = new DescriptionsTree;
    
    foreach( ref c; lines )
    {
        BBox boundary = c.getBoundary;
        
        tree.addObject( boundary, c );
    }
    
    return cutOnCrossings( tree );
}

unittest
{
    alias MapCoords Coords;
    alias Vector2D!long FC; // foreign coords
    alias Box!(MapCoords.Coords) BBox;
    
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
    
    Coords getNodeByID( in ulong id )
    {
        Coords res;
        res.map_coords = nodes[ id ];
        
        return res;
    }
    
    alias TPolylineDescription!( getNodeByID ) PolylineDescription;
    
    auto w1 = PolylineDescription( n1, cat.Line.HIGHWAY );
    auto w2 = PolylineDescription( n2, cat.Line.PRIMARY );
    
    PolylineDescription[] lines = [ w1, w2 ];
    
    auto prepared = cutOnCrossings( lines );
    
    assert( prepared.length == 5 );
    
    auto g = new G( [ w1, w2 ] );
}

size_t createEdge( Graph, Payload )(
        Graph graph,
        in size_t from_node_idx,
        in size_t to_node_idx,
        Payload payload )
{
    Graph.Edge edge = { to_node: to_node_idx, payload: payload };
    
    return graph.addEdge( from_node_idx, edge );
}

alias TPolyline!MapCoords Polyline;
alias TEdge!Polyline Edge;
alias TNode!( Edge, Point ) Node;

alias TMapGraph!( Node, createEdge ) LineGraph;
