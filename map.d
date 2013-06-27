module map;

import math.geometry;
import math.rtree2d;
import osm: Vector2;


struct Node
{
    long lat;
    long lon;
}

class Region
{
    private Node[] nodes;
    
    alias Box!Vector2 BBox;
    alias RTreePtrs!(BBox, size_t) NRT;
    private NRT nodes_rtree;
    
    this()
    {
        nodes_rtree = new NRT;
    }
    
    void addNode( in Node n )
    {
        
        
        nodes ~= n;
    }
    
    // r-tree of ways links to r-tree
    
    // kd-tree of POI links to points    
}
