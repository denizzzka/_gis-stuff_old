module map;

import math.geometry;
import math.rtree2d;
import osm: Coords, encodedToMeters;
debug(map) import std.stdio;


alias Coords Node;
alias Coords POI;
alias Vector2D!real Vector2r;
alias Box!Node BBox;

struct NodesStorage( NodeT )
{
    private
    {
        NodeT[] nodes;
        
        alias Box!NodeT BBox;
        alias RTreePtrs!(BBox, size_t) TRTree;
        TRTree rtree = new TRTree;
    }
    
    void add( in NodeT n )
    {
        NodeT zero_sized;
        BBox box = BBox( n, zero_sized );
        
        rtree.addObject( box, nodes.length );
        nodes ~= n;
        
        debug(map) writeln("Node added=", n, " boundary=", box);
    }
    
    NodeT[] search( in BBox boundary ) const
    {
        NodeT[] res;
        auto leafs = rtree.search( boundary );
        foreach( n; leafs )
            res ~= nodes[ n.payload ];
            
        return res;
    }
    
    BBox getBoundary() const
    {
        return rtree.root.getBoundary;
    }
}

alias NodesStorage!Coords POI_storage;

struct Layer
{
    POI_storage POI;
    
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
