module map;

import math.rtree2d;


struct Node
{
    long lat;
    long lon;
}

class Region
{
    private Node[] nodes;
    
    void addNode( in Node n )
    {
        
        
        nodes ~= n;
    }
    
    // r-tree of ways links to r-tree
    
    // kd-tree of POI links to points    
}
