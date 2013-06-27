module map;

import math.geometry;
import math.rtree2d;
import osm: Coords;


alias Coords Node;

class Region
{
    private
    {
        Node[] nodes;
        
        alias Box!Coords BBox;
        alias RTreePtrs!(BBox, size_t) NRT;
        
        NRT nodes_rtree;
    }
    
    this()
    {
        nodes_rtree = new NRT;
    }
    
    void addNode( in Node n )
    {
        Coords zero_sized;
        BBox box = BBox( n, zero_sized );
        
        nodes_rtree.addObject( box, nodes.length );
        nodes ~= n;
    }
    
    // r-tree of ways links to r-tree
    
    // kd-tree of POI links to points    
}

class Map
{
    Region[] regions;
}
