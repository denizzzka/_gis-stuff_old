module map.map_graph;

import math.geometry;
import math.rtree2d.ptrs;
import map.map: MapCoords, BBox;
import math.earth: mercator2coords, getSphericalDistance;
import map.adapters: TPolylineDescription;
static import pbf;

import std.algorithm: canFind;
import std.random: uniform;
import std.traits;


struct MapGraphPolyline
{
    package pbf.MapPolyline storage;
    alias storage this;
    
    this( MapCoords[] points )
    {
        pbf.MapPolyline l;
        
        pbf.MapCoords[] zero_length;
        l.coords_delta = zero_length; // init nullified PBF array
        
        MapCoords prev = MapCoords.Coords.zero;
        
        foreach( p; points )
        {
            auto delta = MapCoords( p - prev );
            l.coords_delta ~= delta.toPbf;
            prev = p;
        }
        
        storage = l;
    }
    
    this( pbf.MapPolyline storage )
    {
        this.storage = storage;
    }
    
    MapCoords[] points() const
    {
        MapCoords[] res;

        res.length = storage.coords_delta.length;

        MapCoords prev = MapCoords.Coords.zero;

        foreach( i, p; storage.coords_delta )
        {
            prev += MapCoords.fromPbf( p );
            res[i] = prev;
        }

        return res;
    }
    
    @disable this();
}

class MapGraph( alias GraphEngine, Point, Polyline ) : GraphEngine!( Point, Polyline )
{
    this()()
    {
    }
    
    this( PolylineDescription )( scope PolylineDescription[] descriptions )
    {
        this();
        
        auto prepared = cutOnCrossings( descriptions );
        
        NodeDescr[ulong] already_stored;
        
        foreach( line; descriptions )
            addPolyline( line, already_stored );
    }
    
    this(SomeMapGraph)(SomeMapGraph g)
    if( !isArray!SomeMapGraph )
    //if( isInstanceOf!( MapGraph, SomeMapGraph ) )
    {
        super(g);
    }
    
    MapCoords[] getMapCoords( in EdgeDescr descr ) const
    {
        MapCoords[] res;
        
        res ~= getNodePayload( descr.node );
        
        auto edge = getEdge( descr );
        
        foreach( c; edge.payload.points )
            res ~= MapCoords( c + res[0] );
        
        res ~= getNodePayload( edge.to_node );
        
        return res;
    }
    
    BBox getBoundary( in EdgeDescr descr ) const
    {
        auto points = getMapCoords( descr );
        assert( points.length > 0 );
        
        auto res = BBox( points[0], MapCoords.Coords(0,0) );
        
        for( auto i = 1; i < points.length; i++ )
            res.addCircumscribe( points[i] );
        
        return res;
    }
    
    EdgeDescr addPolyline(
            Description,
            ForeignID = Description.ForeignNode.ForeignID
        )(
            Description line_descr,
            ref NodeDescr[ForeignID] already_stored
        )
    in
    {
        assert( line_descr.nodes_ids.length >= 2 );
    }
    body
    {
        size_t first_node = 0;
        size_t last_node = line_descr.nodes_ids.length - 1;
        
        auto from_node = addPoint( line_descr.getNode( first_node ), already_stored );
        auto to_node = addPoint( line_descr.getNode( last_node ), already_stored );
        
        MapCoords[] points;
        
        for( auto i = 1; i < last_node; i++ )
            points ~= MapCoords( line_descr.getNode( i ).getCoords - line_descr.getNode( first_node ).getCoords );
        
        auto poly = Polyline( points, line_descr.properties );
        
        ConnectionInfo conn = { from: from_node, to: to_node };
        
        return addEdge( conn, poly );
    }
    
    private
    NodeDescr addPoint( ForeignNode, ForeignID = ForeignNode.ForeignID )(
            ForeignNode node,
            ref NodeDescr[ ForeignID ] already_stored
        )
    {
        NodeDescr* p = node.foreign_id in already_stored;
        
        if( p !is null )
            return *p;
        else
        {
            auto point = node.getCoords;
            auto descr = addNode( point );
            already_stored[ node.foreign_id ] = descr;
            
            return descr;
        }
    }
    
    EdgeDescr[] getDescriptors() const
    {
        EdgeDescr[] res;
        
        void dg( EdgeDescr edge )
        {
            res ~= edge;
        }
        
        forAllEdges( &dg );
        
        return res;
    }
    
    struct Polylines
    {
        struct GraphLines
        {
            MapGraph map_graph;
            EdgeDescr[] descriptors;
        };
        
        GraphLines[] lines;
    }
}

auto cutOnCrossings( DescriptionsTree )( in DescriptionsTree lines_rtree )
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
            auto point_bbox = BBox( line.getNode( i ).getCoords, Coords(0, 0) );
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
    
    auto tree = new DescriptionsTree( 4, 10 );
    
    foreach( ref c; lines )
    {
        BBox boundary = c.getBoundary;
        
        tree.addObject( boundary, c );
    }
    
    return cutOnCrossings( tree );
}
/*
unittest
{
    alias MapCoords Coords;
    alias Vector2D!long FC; // foreign coords
    alias Box!(MapCoords.Coords) BBox;
    
    alias TPolyline!Coords Polyline;
    alias TEdge!Polyline Edge;
    alias TNode!( Edge, Point ) Node;
    
    alias TMapGraph!( GE, Point, Polyline ) G;
    
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
}
*/
