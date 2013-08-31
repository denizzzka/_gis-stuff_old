module map.map;

import math.geometry;
import math.rtree2d;
import cat = categories;
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
    LinesRTree _lines;
    
    RGraph road_graph;
    
    void init()
    {
        POI = new PointsStorage;
        _lines = new LinesRTree;
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
    
    void fillLines( LinesDescr )( LinesDescr lines_descr )
    {
        auto cutted = cutOnCrossings( lines_descr );
        
        line_graph = new LineGraph;
        
        size_t[ulong] already_stored;
        
        foreach( descr; cutted )
        {
            auto layers_num = config.map.polylines.getProperty( descr.type ).layers;
            
            foreach( n; layers_num )
            {
                auto epsilon = config.converter.layersGeneralization[n];
                
                if( epsilon )
                    descr.generalize( epsilon );
                
                auto descriptior = line_graph.addPolyline( descr, already_stored );
                
                auto bbox = descriptior.getBoundary( line_graph );
                
                AnyLineDescriptor any = {
                    line_class: cat.LineClass.POLYLINE,
                    line: descriptior
                };
                
                layers[n]._lines.addObject( bbox, any );
            }
        }
    }
    
    void fillRoads( RoadsDescr )( RoadsDescr roads_descr )
    {
        auto sorted = sortByLayers( roads_descr );
        
        foreach( i, ref c; layers )
        {
            auto cutted = cutOnCrossings( sorted[i] );
            
            c.road_graph = new RGraph( cutted );
            
            auto descriptors = c.road_graph.getDescriptors();
            
            foreach( descr; descriptors )
            {
                auto bbox = descr.getBoundary( c.road_graph );
                
                AnyLineDescriptor any = { line_class: cat.LineClass.ROAD };
                
                any.road = descr;
                
                layers[i]._lines.addObject( bbox, any );
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
            
            curr.lines ~= region.layers[ layer_num ]._lines.search( boundary );
            
            res ~= curr;
        }
        
        return res;
    }
}
