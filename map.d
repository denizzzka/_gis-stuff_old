module map;

import math.geometry;
import math.rtree2d;
import osm: Coords, encodedCoordsToRadians;


alias Coords Node;
alias Vector2D!real Vector2r;
alias Box!Vector2r BBox;

class Region
{
    private
    {
        Node[] nodes;
        
        alias RTreePtrs!(BBox, size_t) NRT;
        
        NRT nodes_rtree;
    }
    
    this()
    {
        nodes_rtree = new NRT;
    }
    
    BBox boundary() const
    {
        return nodes_rtree.root.getBoundary;
    }
    
    void addNode( in Node n )
    {
        Vector2r zero_sized;
        
        Vector2r _n = encodedCoordsToRadians( n );
        BBox box = BBox( _n, zero_sized );
        
        nodes_rtree.addObject( box, nodes.length );
        nodes ~= n;
    }
    
    Node[] searchNodes( in BBox boundary ) const
    {
        Node[] res;
        auto leafs = nodes_rtree.search( boundary );
        foreach( n; leafs )
            res ~= nodes[ n.payload ];
            
        return res;
    }
    
    // r-tree of ways links to r-tree
    
    // kd-tree of POI links to points    
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
