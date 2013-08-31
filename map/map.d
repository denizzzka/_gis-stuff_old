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
alias RTreePtrs!(BBox, LineGraph.PolylineDescriptor) LinesStorage;
alias RTreePtrs!(BBox, RGraph.PolylineDescriptor) RoadsStorage;

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
    LinesStorage lines;
    RoadsStorage roads;
    LinesRTree _lines;
    
    RGraph road_graph;
    
    void init()
    {
        POI = new PointsStorage;
        lines = new LinesStorage;
        roads = new RoadsStorage;
        _lines = new LinesRTree;
    }
    
    BBox boundary() const
    {
        return POI.getBoundary.getCircumscribed( POI.getBoundary ); // FIXME
    }
    
    private
    void fillRoadsRTree()
    {
        auto descriptors = road_graph.getDescriptors();
        
        foreach( descr; descriptors )
        {
            auto bbox = descr.getBoundary( road_graph );
            
            roads.addObject( bbox, descr );
        }
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
    
    void fillRoads( PrepareRoads )( PrepareRoads prepared )
    {
        foreach( i, ref c; layers )
        {
            c.road_graph = new RGraph( prepared.roads_to_store[i] );
            c.fillRoadsRTree();
        }
    }
}

class TPrepareRoads( Descr )
{
    private Descr[][ Region.layers.length ] roads_to_store;
    
    void addRoad( Descr road_descr )
    {
        auto to_layers = config.map.polylines.getProperty( road_descr.type ).layers;
        
        foreach( n; to_layers )
        {
            auto epsilon = config.converter.layersGeneralization[n];
            
            if( epsilon )
                road_descr.generalize( epsilon );
                
            roads_to_store[n] ~= road_descr;
        }
    }
}

class Map
{
    Region[] regions;
    
    BBox boundary() const
    {
        return regions[0].boundary; // FIXME
    }
}
