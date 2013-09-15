module map.map;

import math.geometry;
import math.rtree2d.ptrs;
static import math.earth;
import cat = config.categories;
import map.line_graph;
import map.road_graph;
import map.map_graph: cutOnCrossings;
import map.area: Area;
import map.objects_properties: LineClass;
static import config.map;
static import config.converter;

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
            
            // adding edges to rtree
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
    
    AnyLineDescriptor*[] lines;
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
            MapLinesDescriptor curr = { region: &region, layer_num: layer_num };
            
            curr.lines ~= region.layers[ layer_num ].lines.search( boundary );
            
            res ~= curr;
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
