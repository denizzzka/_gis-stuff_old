module map;

import math.geometry;
import math.rtree2d;
import osm: Coords, encodedToMeters;
import cat = categories;
import sfml: Color, randomColor; // TODO: temporary, remove it

debug(map) import std.stdio;


alias Box!Coords BBox;

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

alias RTreePtrs!(BBox, Point) PointsStorage;

struct Way
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
        if( isRoad )
            return randomColor;
        
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
                return Color.Yellow;
                
            case ROAD_OTHER:
                return Color( 0xAA, 0xAA, 0xAA );
                
            default:
                return Color.Cyan;
        }
    }
    
    bool isRoad() const
    {
        with( cat.Line )
        switch( type )
        {
            case ROAD_HIGHWAY:
            case ROAD_PRIMARY:
            case ROAD_SECONDARY:
            case ROAD_OTHER:
                return true;
                break;
                
            default:
                return false;
                break;
        }
    }
    
    Way opSlice( size_t from, size_t to )
    {
        Way res = this;
        
        res.nodes = nodes[ from..to ];
        
        return res;
    }
    
    @disable
    Way cutFirstPart( in size_t nodeNumber )
    in
    {
        assert( nodeNumber > 0 );
        assert( nodeNumber < nodes.length - 1 );
    }
    body
    {
        Way res = this;
        
        res.nodes = nodes[ 0..nodeNumber+1 ];        
        nodes = nodes[ nodeNumber..$ ];
        
        assert( res.nodes.length > 1 );
        
        return res;
    }
}

alias RTreePtrs!(BBox, Way) WaysStorage;

void addPoint( PointsStorage storage, Point point )
{
    BBox bbox = BBox( point.coords, Coords(0,0) );
    
    storage.addObject( bbox, point );
}

void addWayToStorage( WaysStorage storage, Way way )
{
    storage.addObject( way.getBoundary, way );
}

struct Layer
{
    PointsStorage POI;
    WaysStorage ways;
    
    void init()
    {
        POI = new PointsStorage;
        ways = new WaysStorage( 10 );
    }
    
    BBox boundary() const
    {
        return POI.getBoundary.getCircumscribed( ways.getBoundary );
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
    
    void addWay( Way way )
    {
        size_t layer_num;
        
        with( cat.Line )
        switch( way.type )
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
        
        layers[layer_num].ways.addWayToStorage( way );
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
