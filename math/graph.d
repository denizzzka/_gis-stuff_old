module math.graph;

import math.geometry;
import math.rtree2d;


class Graph( Point, Weight, Payload )
{
private:

    Node*[] entry; // entry points
    RTreePtrs!Node rtree; // for fast node search
    
public:
    
    struct Edge
    {
        const Weight weight;
        const Node* node;
        
        invariant()
        {
            assert( weight >= 0 );
        }
    }
    
    struct Node
    {
        const Point point;
        
    private:
        Edge[] edges;
        Payload payload;
    }
    
    this()
    {
        rtree = new RTreePtrs!Node;
    }
    
    void addEdge( in Point from, in Point to, in Weight w )
    {
        
    }
}

unittest
{
    struct Coords
    {
        Vector2D coords;
        byte level;
        
        bool opEquals( Coords a, Coords b )
        {
            return a.coords == b.coords && a.level == b.level;
        }
    }
    
    alias Graph!( Coords, float, string ) G;
    
    auto g = new G;
    G.Node* prev;
    
    for( auto y=0; y<3; y++ )
        for( auto x=0; x<3; x++ )
        {
            /*
            G.Node n = { coords: Vector2D(x, y) };
            
            if( prev )
                
            
            prev = n;
            */
        }
}
