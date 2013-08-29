module map;

import math.geometry;
import math.rtree2d;
import cat = categories;
import map_graph: LineGraph, cutOnCrossings;
import roads: RoadGraph;
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
    
    RGraph road_graph;
    
    void init()
    {
        POI = new PointsStorage;
        lines = new LinesStorage;
        roads = new RoadsStorage;
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
    immutable layers_num = 5;
    Layer[layers_num] layers;
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
    
    void fillLines( IDstruct, AACoords, LinesDescr )( in AACoords nodes_coords, LinesDescr lines_descr )
    {
        auto cutted = cutOnCrossings( lines_descr, nodes_coords );
        
        line_graph = new LineGraph;
        
        size_t[ulong] already_stored;
        
        foreach( descr; cutted )
        {
            auto layers_num = config.map.polylines.getProperty( descr.type ).layers;
            
            foreach( n; layers_num )
            {
                auto epsilon = config.converter.layersGeneralization[n];
                
                if( epsilon )
                    descr.generalize!IDstruct( nodes_coords, epsilon );
                
                auto descriptior = line_graph.addPolyline( descr, already_stored, nodes_coords );
                
                auto bbox = descriptior.getBoundary( line_graph );
                
                layers[n].lines.addObject( bbox, descriptior );
            }
        }
    }
    
    void fillRoads( AACoords, PrepareRoads )( in AACoords nodes_coords, PrepareRoads prepared )
    {
        auto road_layers = prepared.getRoadsLayers( nodes_coords );
        
        foreach( i, ref c; layers )
        {
            c.road_graph = new RGraph( nodes_coords, road_layers[i] );
            c.fillRoadsRTree();
        }
    }
}

class TPrepareRoads( Descr, AACoords, IDstruct )
{
    private Descr[] roads_to_store;
    
    void addRoad( Descr road_descr )
    {
        roads_to_store ~= road_descr;
    }
    
    auto getRoadsLayers( in AACoords nodes_coords )
    {
        auto cutted = cutOnCrossings( roads_to_store, nodes_coords );
        
        Descr[][ Region.layers_num ] res;
        
        foreach( road_descr; cutted )
        {
            auto to_layers = config.map.polylines.getProperty( road_descr.type ).layers;
            
            foreach( n; to_layers )
            {
                auto epsilon = config.converter.layersGeneralization[n];
                
                if( epsilon )
                    road_descr.generalize!IDstruct( nodes_coords, epsilon );
                    
                res[n] ~= road_descr;
            }
        }
        
        return res;
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
