module map.map;

import math.geometry;
import math.rtree2d;
import cat = config.categories;
import map.map_graph: LineGraph, cutOnCrossings;
import map.roads: RoadGraph;
static import config.map;
static import config.converter;

debug(map) import std.stdio;


alias Vector2D!double Coords;
alias Box!Coords BBox;
alias RoadGraph RGraph;

struct Point
{
    private
    {
        Coords _coords;
        cat.Point _type;
        string _tags;
    }
    
    this( in Coords coords, in cat.Point type, in string tags )
    {
        _coords = coords;
        _type = type;
        _tags = tags;
    }
    
    @disable this();
    
    Coords coords() const
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
    cat.LineClass line_class;
    
    union
    {
        LineGraph.PolylineDescriptor line;
        RGraph.PolylineDescriptor road;
    }    
}

alias RTreePtrs!(BBox, AnyLineDescriptor) LinesRTree;

void addPoint( PointsStorage storage, Point point )
{
    BBox bbox = BBox( point.coords, Coords(0,0) );
    
    storage.addObject( bbox, point );
}

struct Layer
{
    PointsStorage POI;
    LinesRTree lines;
    
    RGraph road_graph;
    
    void init()
    {
        POI = new PointsStorage;
        lines = new LinesRTree;
    }
    
    BBox boundary() const
    {
        return POI.getBoundary.getCircumscribed( POI.getBoundary ); // FIXME
    }
}

class Region
{
    Layer[5] layers;
    LineGraph line_graph;
    
    this()
    {
        foreach( ref c; layers )
            c.init;
    }
    
    BBox boundary() const
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
}

Descr[][5] sortByLayers( Descr )( Descr[] lines )
{
    Descr[][5] res;
    
    foreach( ref line; lines )
    {
        auto to_layers = config.map.polylines.getProperty( line.type ).layers;
        
        foreach( layer_num; to_layers )
            res[][ layer_num ] ~= line;
    }
    
    return res;
}

class TPrepareLines( Descr )
{
    private Descr[][ Region.layers.length ] lines_to_store;
    
    void addRoad( Descr line_descr )
    {
        auto to_layers = config.map.polylines.getProperty( line_descr.type ).layers;
        
        foreach( n; to_layers )
        {
            auto epsilon = config.converter.layersGeneralization[n];
            
            if( epsilon )
                line_descr.generalize( epsilon );
                
            lines_to_store[n] ~= line_descr;
        }
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
    
    BBox boundary() const
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
