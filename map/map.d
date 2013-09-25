module map.map;

import math.geometry;
import math.rtree2d.ptrs;
import math.rtree2d.array;
static import math.earth;
import cat = config.categories;
import map.line_graph;
import map.road_graph;
import map.map_graph: cutOnCrossings;
import map.area: Area;
import map.objects_properties: LineClass;
static import config.map;
static import config.converter;
static import pbf = pbf.map_objects;

debug(map) import std.stdio;


alias Vector2D!(real, "Mercator coords") MercatorCoords;

struct MapCoords
{
    alias Vector2D!(long, "Map coords vector") Coords;
    
    package Coords map_coords;
    
    this( Coords coords )
    {
        map_coords = coords;
    }
    
    this( MercatorCoords coords )
    {
        map_coords = ( coords * 10 ).lround;
    }
    
    MercatorCoords getMercatorCoords() const pure
    {
        MercatorCoords res = map_coords;
        res /= 10;
        
        return res;
    }
    
    alias getMercatorCoords this;
    
    real calcSphericalDistance( in MapCoords v ) const
    {
        return math.earth.getSphericalDistance( getRadiansCoords, v.getRadiansCoords );
    }
    
    auto getRadiansCoords() const
    {
        return math.earth.mercator2coords( getMercatorCoords );
    }
    
    pbf.MapCoords toPbf() const
    {
        pbf.MapCoords res;
        
        res.lon = map_coords.lon;
        res.lat = map_coords.lat;
        
        return res;
    }
    
    static MapCoords fromPbf( inout pbf.MapCoords from )
    {
        MapCoords res;
        
        res.map_coords.lon = from.lon;
        res.map_coords.lat = from.lat;
        
        return res;
    }
    
    ubyte[] Serialize() const
    {
        return toPbf.Serialize;
    }
    
    static MapCoords Deserialize( inout ubyte[] from )
    {
        auto f = cast(ubyte[]) from.dup;
        auto c = pbf.MapCoords.Deserialize( f );
        
        MapCoords res;
        
        res.lon = c.lon;
        res.lat = c.lat;
        
        return res;
    }
}

alias Box!(MapCoords.Coords) BBox;
alias Box!MercatorCoords MBBox;

BBox toBBox( in MBBox mbox )
{
    BBox res;
    
    res.ld = (mbox.ld * 10).roundToLeftDown!long;
    res.ru = (mbox.ru * 10).roundToRightUpper!long;
    
    return res;
}

MBBox toMBBox( in BBox bbox )
{
    MBBox res;
    
    res.ld = MapCoords( bbox.ld );
    res.ru = MapCoords( bbox.ru );
    
    return res;
}

struct Point
{
    private
    {
        MapCoords _coords;
        cat.Point _type;
        string _tags;
    }
    
    this( in MapCoords coords, in cat.Point type, in string tags )
    {
        _coords = coords;
        _type = type;
        _tags = tags;
    }
    
    @disable this();
    
    MapCoords coords() const
    {
        return _coords;
    }
    
    string tags() const
    {
        return _tags;
    }
    
    cat.Point type() const
    {
        return _type;
    }
}

alias RTreePtrs!(BBox, Point) PointsStorage; // TODO: 2D-Tree points storage

struct AnyLineDescriptor
{
    LineClass line_class; // TODO: here is need polymorphism
    
    union
    {
        LineGraph.EdgeDescr line;
        RoadGraph.EdgeDescr road;
        Area area;
    }
    
    // TODO: need to implement real compression
    ubyte[] compress() const
    {
        ubyte res[] = (cast (ubyte*) &this) [ 0 .. this.sizeof ];
        return res;
    }
    
    // TODO: need to implement real compression
    size_t decompress( inout ubyte* storage )
    {
        (cast (ubyte*) &this)[ 0 .. this.sizeof] = storage[ 0 .. this.sizeof ].dup;
        
        return this.sizeof;
    }
}

alias RTreePtrs!(BBox, AnyLineDescriptor) LinesRTree;
alias RTreeArray!( LinesRTree ) LinesRTree_array;

void addPoint( PointsStorage storage, Point point )
{
    BBox bbox = BBox( point.coords.map_coords, MapCoords.Coords(0,0) );
    
    storage.addObject( bbox, point );
}

struct Layer
{
    PointsStorage POI;
    LinesRTree lines;
    LinesRTree_array _lines;
    
    RoadGraph road_graph;
    
    void init()
    {
        POI = new PointsStorage( 4, 1 );
        lines = new LinesRTree( 4, 1 );
    }
    
    MBBox boundary() const
    {
        return POI.getBoundary.getCircumscribed( POI.getBoundary ).toMBBox; // FIXME
    }
}

class Region
{
    Layer[5] layers;
    //LineGraph line_graph;
    LineGraphCompressed _line_graph;
    Area[] areas;
    
    this()
    {
        foreach( ref c; layers )
            c.init;
    }
    
    void moveInfoIntoRTreeArray()
    {
        foreach( ref l; layers )
        {
            l._lines = new LinesRTree_array( l.lines );
            delete l.lines;
        }
    }
    
    MBBox boundary() const
    {
        return layers[0].boundary; // FIXME
    }
    
    void addPoint( Point point )
    {
        size_t layer_num;
        
        with( cat.Point )
        switch( point.type )
        {
            case POLICE:
            case SHOP:
            case LEISURE:
                layer_num = 0;
                break;
                
            default:
                layer_num = layers.length - 1;
                break;
        }
        
        layers[layer_num].POI.addPoint( point );
    }
    
    void fillLines( Prepare )( Prepare prepared )
    {
        auto line_graph = new LineGraph;
        
        LineGraph.NodeDescr[ulong] already_stored;
        
        foreach( i, ref unused; layers )
        {
            auto epsilon = config.converter.layersGeneralization[i];
            auto cutted = cutOnCrossings( prepared.lines_to_store[i] );
            
            foreach( descr; cutted )
            {
                if( epsilon )
                    descr.generalize( epsilon );
                
                auto descriptor = line_graph.addPolyline( descr, already_stored );
                
                auto bbox = line_graph.getBoundary( descriptor );
                
                AnyLineDescriptor any = {
                    line_class: LineClass.POLYLINE,
                    line: descriptor
                };
                
                layers[i].lines.addObject( bbox, any );
            }
        }
        
        this._line_graph = new LineGraphCompressed( line_graph );
    }
    
    void fillRoads( Prepare )( Prepare prepared )
    {
        foreach( i, ref layer; layers )
        {
            layer.road_graph = new RoadGraph;
            
            RoadGraph.NodeDescr[ulong] already_stored;
            
            auto epsilon = config.converter.layersGeneralization[i];
            auto cutted = cutOnCrossings( prepared.lines_to_store[i] );
            
            foreach( descr; cutted )
            {
                if( epsilon )
                    descr.generalize( epsilon );
                
                layer.road_graph.addPolyline( descr, already_stored );
            }
            
            layer.road_graph.sortEdgesByReducingRank;
            
            void addEdgeToRtree( RoadGraph.EdgeDescr descr )
            {
                auto bbox = layer.road_graph.getBoundary( descr );
                
                AnyLineDescriptor any = {
                    line_class: LineClass.ROAD,
                };
                any.road = descr;
                
                layer.lines.addObject( bbox, any );
            }
            
            layer.road_graph.forAllEdges( &addEdgeToRtree );
        }
    }
    
    void fillAreas( Area[] areas )
    {
        this.areas = areas;
        
        foreach( area; areas )
        {
            auto to_layers = config.map.polylines.getProperty( area._properties.type ).layers;
            
            foreach( n; to_layers )
            {
                auto epsilon = config.converter.layersGeneralization[n];
                
                if( epsilon )
                    area.generalize( epsilon );
                
                AnyLineDescriptor any = {
                    line_class: LineClass.AREA
                };
                any.area = area;
                
                layers[n].lines.addObject( area.getBoundary, any );
            }
        }
    }
}

class TPrepareLines( Descr )
{
    private Descr[][ Region.layers.length ] lines_to_store;
    
    void addLine( Descr line_descr )
    {
        auto to_layers = config.map.polylines.getProperty( line_descr.properties.type ).layers;
        
        foreach( n; to_layers )
            lines_to_store[n] ~= line_descr;
    }
}

struct MapLinesDescriptor
{
    const Region* region;
    const size_t layer_num;
    
    LinesRTree_array.Found lines;
}

class Map
{
    Region[] regions;
    
    RoadGraph.Polylines found_path;
    
    MBBox boundary() const
    {
        return regions[0].boundary; // FIXME
    }
    
    MapLinesDescriptor[] getLines( in size_t layer_num, in BBox boundary ) const
    {
        MapLinesDescriptor[] res;
        
        foreach( ref region; regions )
        {
            MapLinesDescriptor curr = {
                    region: &region,
                    layer_num: layer_num,
                    lines: region.layers[ layer_num ]._lines.search( boundary )
                };
            
            res ~= curr;
        }
        
        debug(map)
        {
            size_t num;
            
            foreach( ref c; res )
                num += c.lines.length;
                
            writeln( __FUNCTION__~": found ", num, " lines" );
        }
        
        return res;
    }
    
    void updatePath()
    {
        RoadGraph g = regions[0].layers[0].road_graph;
        
        RoadGraph.EdgeDescr[] path;
        
        do
        {
            path = g.findPath( g.getRandomNode, g.getRandomNode );
        }
        while( path.length == 0 );
        
        RoadGraph.Polylines.GraphLines gl = { map_graph: g, descriptors: path };
        
        found_path.lines.destroy;
        found_path.lines ~= gl;
    }
}
