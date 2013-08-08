module map;

import math.geometry;
import math.rtree2d;
import osm: Coords, encodedToMeters;
debug(map) import std.stdio;


alias Box!Coords BBox;

struct Point
{
    private
    {
        Coords _coords;
        string _tags;
    }
    
    this( in Coords coords, in string tags )
    {
        _coords = coords;
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
}

alias RTreePtrs!(BBox, Point) PointsStorage;

struct Way
{
    Coords[] nodes;
    string tags;
    
    this( Coords[] nodes, in string tags )
    {
        this.nodes = nodes;
        this.tags = tags;
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
}

alias RTreePtrs!(BBox, Way) WaysStorage;

void addPoint( PointsStorage storage, Point point )
{
    BBox bbox = BBox( point.coords, Coords(0,0) );
    
    storage.addObject( bbox, point );
}

void addWay( WaysStorage storage, Way way )
{
    storage.addObject( way.getBoundary, way );
}

struct Layer
{
    PointsStorage POI = new PointsStorage;
    WaysStorage ways = new WaysStorage;
    
    BBox boundary() const
    {
        return POI.getBoundary;
    }
}

class Region
{
    Layer layer0;
    
    BBox boundary() const
    {
        return layer0.boundary;
    }
}

class Map
{
    Region[] regions;
    
    Region getScene( in BBox box )
    {
        return regions[0];
    }
    
    BBox boundary() const // FIXME
    {
        return regions[0].boundary;
    }
}
