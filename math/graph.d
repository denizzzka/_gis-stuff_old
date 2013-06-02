module math.graph;

import math.geometry;


class Graph( Point )
{
private:

    Node*[] entry; // entry points
    
public:
    
    struct Edge
    {
        const float weight;
        const Node* node;
        
        invariant()
        {
            assert( weight >= 0 );
        }
    }
    
    
    struct Node
    {
        const Point point;
        
        void addEdge( in Node* n, in float weight )
        {
            Edge e = { node: n, weight: weight };
            edges ~= e;
        }
        
    private:

        Edge[] edges;
        string payload = "123";
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
    
    alias Graph!Coords G;
    
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
