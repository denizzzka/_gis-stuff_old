module map.map;

import math.geometry;
import math.rtree2d;
import cat = config.categories;
import map.map_graph: LineGraph, cutOnCrossings;
import map.roads: RoadGraph;
import map.area: Area;
static import config.map;
static import config.converter;

debug(map) import std.stdio;


//alias Vector2D!(long, "Map coords") MapCoords;
alias Vector2D!(real, "Mercator coords") MercatorCoords;

struct MapCoords
{
    alias Vector2D!(long, "Map coords vector") Coords;
    
    Coords map_coords;
    
    this( MercatorCoords coords )
    {
        map_coords = ( coords * 10 ).lround;
    }
    
    this( Coords coords )
    {
        map_coords = coords;
    }
    
    this( long x, long y )
    {
        map_coords = Coords( x, y );
    }
    
    MercatorCoords getMercatorCoords() const pure
    {
        MercatorCoords res = map_coords;
        res /= 10;
        
        return res;
    }
    
    alias getMercatorCoords this;
}

/*
alias Box!(MapCoords.Coords) CBox;

CBox getBoundary( in MapCoords[] coords )
in
{
    assert( coords.length > 0 );
}
body
{
    auto res = CBox( coords[0].map_coords, MapCoords.Coords(0, 0) );
    
    for( auto i = 1; i < coords.length; i++ )
        res.addCircumscribe( coords[i].map_coords );
    
    return res;
}
*/

// temporary dumb function
/*
MapCoords map_coords( in MapCoords coords )
{
    return coords;
}
*/

MapCoords getMapCoords( in MercatorCoords coords )
{
    return MapCoords( coords );
}

MercatorCoords getMercatorCoords( in MapCoords.Coords map_coords )
{
    MercatorCoords res = map_coords;
    res /= 10;
    
    return res;
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
    
    res.ld = bbox.ld.getMercatorCoords;
    res.ru = bbox.ru.getMercatorCoords;
    
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
    cat.LineClass line_class; // TODO: here is need polymorphism
    
    union
    {
        LineGraph.PolylineDescriptor line;
        RoadGraph.PolylineDescriptor road;
        Area area;
    }    
}

alias RTreePtrs!(BBox, AnyLineDescriptor) LinesRTree;

void addPoint( PointsStorage storage, Point point )
{
    BBox bbox = BBox( point.coords.map_coords, MapCoords.Coords(0,0) );
    
    storage.addObject( bbox, point );
}

struct Layer
{
    PointsStorage POI;
    LinesRTree lines;
    
    RoadGraph road_graph;
    
    void init()
    {
        POI = new PointsStorage;
        lines = new LinesRTree;
    }
    
    MBBox boundary() const
    {
        return POI.getBoundary.getCircumscribed( POI.getBoundary ).toMBBox; // FIXME
    }
}

class Region
{
    Layer[5] layers;
    LineGraph line_graph;
    Area[] areas;
    
    this()
    {
        foreach( ref c; layers )
            c.init;
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
        line_graph = new LineGraph;
        
        size_t[ulong] already_stored;
        
        foreach( i, ref unused; layers )
        {
            auto epsilon = config.converter.layersGeneralization[i];
            auto cutted = cutOnCrossings( prepared.lines_to_store[i] );
            
            foreach( ref descr; cutted )
            {
                if( epsilon )
                    descr.generalize( epsilon );
                
                auto descriptior = line_graph.addPolyline( descr, already_stored );
                
                auto bbox = descriptior.getBoundary( line_graph );
                
                AnyLineDescriptor any = {
                    line_class: cat.LineClass.POLYLINE,
                    line: descriptior
                };
                
                layers[i].lines.addObject( bbox, any );
            }
        }
    }
    
    void fillRoads( Prepare )( Prepare prepared )
    {
        foreach( i, ref layer; layers )
        {
            layer.road_graph = new RoadGraph;
            
            size_t[ulong] already_stored;
            
            auto epsilon = config.converter.layersGeneralization[i];
            auto cutted = cutOnCrossings( prepared.lines_to_store[i] );
            
            foreach( descr; cutted )
            {
                if( epsilon )
                    descr.generalize( epsilon );
                
                auto descriptior = layer.road_graph.addPolyline( descr, already_stored );
                
                auto bbox = descriptior.getBoundary( layer.road_graph );
                
                AnyLineDescriptor any = {
                    line_class: cat.LineClass.ROAD,
                };
                any.road = descriptior;
                
                layer.lines.addObject( bbox, any );
            }
        }
    }
    
    void fillAreas( Area[] areas )
    {
        this.areas = areas;
        
        foreach( ref area; areas )
        {
            auto to_layers = config.map.polylines.getProperty( area.type ).layers;
            
            foreach( n; to_layers )
            {
                AnyLineDescriptor any = {
                    line_class: cat.LineClass.AREA
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
        auto to_layers = config.map.polylines.getProperty( line_descr.type ).layers;
        
        foreach( n; to_layers )
            lines_to_store[n] ~= line_descr;
    }
}

struct MapLinesDescriptor
{
    const Region* region;
    const size_t layer_num;
    
    AnyLineDescriptor*[] lines;
}

class Map
{
    Region[] regions;
    
    MBBox boundary() const
    {
        return regions[0].boundary; // FIXME
    }
    
    MapLinesDescriptor[] getLines( in size_t layer_num, in BBox boundary ) const
    {
        MapLinesDescriptor[] res;
        
        foreach( ref region; regions )
        {
            MapLinesDescriptor curr = { region: &region, layer_num: layer_num };
            
            curr.lines ~= region.layers[ layer_num ].lines.search( boundary );
            
            res ~= curr;
        }
        
        return res;
    }
}
