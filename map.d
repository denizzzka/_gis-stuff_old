module map;

import math.geometry;
import math.rtree2d;
import osm: Coords, encodedToMeters;
debug(map) import std.stdio;


alias Coords Node;
alias Vector2D!real Vector2r;

alias Box!Coords BBox;

alias RTreePtrs!(BBox, Coords) CoordsStorage;    

// for zero-sized type Coords
void add( CoordsStorage rtree, Coords n )
{
    Coords zero_sized;
    auto box = BBox( n, zero_sized );
    
    rtree.addObject( box, n );
    
    debug(map) writeln("Added Coords=", n, " boundary=", box);
}

struct Layer
{
    
    CoordsStorage POI = new CoordsStorage;
    
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
