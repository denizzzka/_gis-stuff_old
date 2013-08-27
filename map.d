module map;

import math.geometry;
import math.rtree2d;
import cat = categories;
import roads: RoadGraph;
static import config.map;

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
    
    auto color() const
    {
        return config.map.polylines.getProperty( type ).color;
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
alias RTreePtrs!(BBox, RGraph.PolylineDescriptor) RoadsStorage;

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
    
    RGraph road_graph;
    
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
        auto to_layers = config.map.polylines.getProperty( line.type ).layers;
        
        foreach( idx; to_layers )
            layers[ idx ].lines.addLineToStorage( line );
    }
    
    void fillRoads( AACoords, PrepareRoads )( in AACoords nodes_coords, PrepareRoads prepared )
    {
        foreach( i, ref c; layers )
        {
            c.road_graph = new RGraph( nodes_coords, prepared.roads_to_store[i] );
            c.fillRoadsRTree();
        }
    }
}

class TPrepareRoads( Descr )
{
    private Descr[][ Region.layers.length ] roads_to_store;
    
    void addRoad( AACoords )( Descr road_descr, in AACoords nodes_coords )
    {
        auto to_layers = config.map.polylines.getProperty( road_descr.type ).layers;
        
        foreach( n; to_layers )
        {
            //if( n != 0 )
            
            roads_to_store[n] ~= road_descr;
        }
    }
    
    /*
    private
    static Descr generalize( in Descr orig )
    {
    }
    */
}

class Map
{
    Region[] regions;
    
    BBox boundary() const
    {
        return regions[0].boundary; // FIXME
    }
}
