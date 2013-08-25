module map;

import math.geometry;
import math.rtree2d;
import cat = categories;
import sfml: Color, randomColor; // TODO: temporary, remove it
import roads: TRoadGraph;

debug(map) import std.stdio;


alias Vector2D!double Coords;
alias Box!Coords BBox;
alias TRoadGraph!Coords RGraph;

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

struct Line
{
    Coords[] nodes;
    cat.Line type;
    string tags;
    
    this( Coords[] nodes, in cat.Line type, in string tags )
    {
        this.nodes = nodes;
        this.type = type;
        this.tags = tags;
    }
    
    this(this)
    {
        nodes = nodes.dup;
    }
    
    @disable this();
    
    BBox getBoundary() const
    in
    {
        assert( nodes.length > 0 );
    }
    body
    {
        auto res = BBox( nodes[0], Coords(0,0) );
        
        for( auto i = 1; i < nodes.length; i++ )
            res.addCircumscribe( nodes[i] );
        
        return res;
    }
    
    Color color() const
    {
        with( cat.Line )
        switch( type )
        {
            case BUILDING:
                return Color( 0xf7, 0xc3, 0x94 );
                
            case ROAD_HIGHWAY:
                return Color.Green;
                
            case ROAD_PRIMARY:
                return Color.White;
                
            case ROAD_SECONDARY:
            case PATH:
                return Color.Yellow;
                
            case ROAD_OTHER:
                return Color( 0xAA, 0xAA, 0xAA );
                
            default:
                return Color.Cyan;
        }
    }
    
    Line opSlice( size_t from, size_t to )
    {
        Line res = this;
        
        res.nodes = nodes[ from..to ];
        
        return res;
    }
}

alias RTreePtrs!(BBox, Point) PointsStorage;
alias RTreePtrs!(BBox, Line) LinesStorage;
alias RTreePtrs!(BBox, RGraph.RoadDescriptor) RoadsStorage;

void addPoint( PointsStorage storage, Point point )
{
    BBox bbox = BBox( point.coords, Coords(0,0) );
    
    storage.addObject( bbox, point );
}

void addLineToStorage( LinesStorage storage, Line line )
{
    storage.addObject( line.getBoundary, line );
}

struct Layer
{
    PointsStorage POI;
    LinesStorage lines;
    RoadsStorage roads;
    
    void init()
    {
        POI = new PointsStorage;
        lines = new LinesStorage( 10 );
        roads = new RoadsStorage;
    }
    
    BBox boundary() const
    {
        return POI.getBoundary.getCircumscribed( lines.getBoundary );
    }
}

class Region
{
    Layer[5] layers;
    RGraph road_graph;
    
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
    
    void addLine( Line line )
    {
        size_t layer_num;
        
        with( cat.Line )
        switch( line.type )
        {
            case BOUNDARY:
                layer_num = 4;
                break;
                
            case ROAD_HIGHWAY:
                layer_num = 3;
                break;
                
            case ROAD_PRIMARY:
                layer_num = 2;
                break;
                
            case ROAD_SECONDARY:
                layer_num = 1;
                break;
                
            case ROAD_OTHER:
            case BUILDING:
                layer_num = 0;
                break;
                
            default:
                layer_num = layers.length - 1;
                break;
        }
        
        layers[layer_num].lines.addLineToStorage( line );
    }
    
    private
    void addRoadDescriptor( RGraph.RoadDescriptor descr )
    {
        auto to_layers = descr.getRoad( road_graph ).properties.layers;
        auto bbox = descr.getBoundary( road_graph );
        
        foreach( n; to_layers )
            layers[ n ].roads.addObject( bbox, descr );
    }
    
    void addRoadGraph( RGraph newRoadGraph )
    {
        road_graph = newRoadGraph;
        
        auto descriptors = road_graph.getDescriptors();
        
        foreach( c; descriptors )
            addRoadDescriptor( c );
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
