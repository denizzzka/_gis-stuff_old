module map;

import math.geometry;
import math.rtree2d;
import osm: Coords, encodedToMeters;
debug(map) import std.stdio;


alias Box!Coords BBox;

alias RTreePtrs!(BBox, Coords) CoordsStorage;    

// temporary bypass function for geometrically zero-sized type Coords
void addCoord( CoordsStorage rtree, in Coords n )
{
    Coords zero_sized;
    auto box = BBox( n, zero_sized );
    
    rtree.addObject( box, n );
    
    debug(map) writeln("Added Coords=", n, " boundary=", box);
}

struct Way
{
    private Coords[] nodes;
    
    void addNode( in Coords n )
    {
        nodes ~= n;
    }
    
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
    
    Coords[] getNodes()
    {
        return nodes;
    }
}

alias RTreePtrs!(BBox, Way) WaysStorage;    

struct Layer
{
    CoordsStorage POI = new CoordsStorage;
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
