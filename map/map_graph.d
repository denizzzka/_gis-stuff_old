module map.map_graph;

import math.geometry;
import math.rtree2d.ptrs;
import math.graph.digraph;
import map.map: MapCoords, BBox;
import cat = config.categories: Line; // FIXME: remove it
static import config.map;
import math.earth: mercator2coords, getSphericalDistance;
import map.adapters: TPolylineDescription;

import std.algorithm: canFind;
import std.random: uniform;
import std.stdio;


struct MapGraphPoint
{
    MapCoords coords;
    
    alias coords this;
    
    this( MapCoords coords )
    {
        this.coords = coords;
    }
    
    float distance( in MapGraphPoint v, in float weight ) const
    {
        return heuristic( v ) * weight;
    }
    
    float heuristic( in MapGraphPoint v ) const
    {
        return getSphericalDistance( getRadiansCoords, v.getRadiansCoords );
    }
}

struct MapPolyline
{
    package MapCoords[] points; /// points between start and end points
    
    cat.Line type = cat.Line.OTHER; // FIXME remove it
    
    this( MapCoords[] points, cat.Line type )
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

class MapGraph( GraphEngine, Point, Polyline )
{
    alias GraphEngine G;
    alias G.NodeDescr NodeDescr;
    alias G.EdgeDescr EdgeDescr;
    
    protected // TODO: need to be a package
    {
        G graph;
    }
    
    struct PolylineDescriptor
    {
        NodeDescr node;
        EdgeDescr edge;
        
        this( NodeDescr node, EdgeDescr edge )
        {
            this.node = node;
            this.edge = edge;
        }
    }
    
    this()()
    {
        graph = new G;
    }
    
    this( PolylineDescription )( scope PolylineDescription[] descriptions )
    {
        this();
        
        auto prepared = cutOnCrossings( descriptions );
        
        NodeDescr[ulong] already_stored;
        
        foreach( line; descriptions )
            addPolyline( line, already_stored );
    }
    
    // TODO: replace this by getPayload()
    ref const (Polyline) getPolyline( in PolylineDescriptor descr ) const
    {
        return graph.getEdge( descr.node, descr.edge ).payload;
    }
    
    MapCoords[] getMapCoords( in PolylineDescriptor descr ) const
    {
        MapCoords[] res;
        
        res ~= graph.getNodePayload( descr.node );
        
        auto edge = graph.getEdge( descr.node, descr.edge );
        
        foreach( c; edge.payload.points )
            res ~= c;
        
        res ~= graph.getNodePayload( edge.to_node );
        
        return res;
    }
    
    BBox getBoundary( in PolylineDescriptor descr ) const
    {
        auto points = getMapCoords( descr );
        assert( points.length > 0 );
        
        auto res = BBox( points[0].map_coords, MapCoords.Coords(0,0) );
        
        for( auto i = 1; i < points.length; i++ )
            res.addCircumscribe( points[i].map_coords );
        
        return res;
    }
    
    PolylineDescriptor addPolyline(
            Description,
            ForeignID = Description.ForeignNode.ForeignID
        )(
            Description line,
            ref NodeDescr[ForeignID] already_stored
        )
    in
    {
        assert( line.nodes_ids.length >= 2 );
    }
    body
    {
        size_t first_node = 0;
        size_t last_node = line.nodes_ids.length - 1;
        
        auto from_node = addPoint( line.getNode( first_node ), already_stored );
        auto to_node = addPoint( line.getNode( last_node ), already_stored );
        
        MapCoords points[];
        
        for( auto i = 1; i < last_node; i++ )
            points ~= line.getNode( i ).getCoords;
        
        auto poly = Polyline( points, line.type );
        
        G.ConnectionInfo conn = { from: from_node, to: to_node };
        
        auto edgeDescr = graph.addEdge( conn, poly );
        
        return PolylineDescriptor( from_node, edgeDescr );
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
            auto point = Point( node.getCoords );
            auto descr = graph.addNode( point );
            already_stored[ node.foreign_id ] = descr;
            
            return descr;
        }
    }
    
    PolylineDescriptor[] getDescriptors() const
    {
        PolylineDescriptor[] res;
        
        void dg( NodeDescr node, EdgeDescr edge )
        {
            res ~= PolylineDescriptor( node, edge );
        }
        
        graph.forAllEdges( &dg );
        
        return res;
    }
    
    struct Polylines
    {
        alias MapGraph MapGraphType_copy_because_compiling_bug; // TODO
        
        struct GraphLines
        {
            MapGraph map_graph;
            PolylineDescriptor[] descriptors;
        };
        
        GraphLines[] lines;
        
        void forAllLines( void delegate( inout MapGraph graph, inout PolylineDescriptor descr ) dg ) const
        {
            foreach( graphLines; lines )
                foreach( descr; graphLines.descriptors )
                    dg( graphLines.map_graph, descr );
        }
    }
    
    G.NodeDescr getRandomNode() const
    {
        return graph.getRandomNode;
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
