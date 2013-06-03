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
        Edge[] edges;
        Payload payload;
    }
    
    this()
    {
        rtree = new RTreePtrs!Node;
    }
    
    void addEdge( in Point from, in Point to, in Weight w )
    {
        Node* f = addPoint( from );
        Node* t = addPoint( to );
        
        Edge e = { node: t, weight: w };
        f.edges ~= e;
        
        // тут сделать поиск пути от каждого entry[] до t и если пути нет то entry ~= t;
        if( entry.length == 0 ) entry ~= f; // TODO: заменить на вышенаписанное
    }
    
private:
    Node* addPoint( in Point point )
    {
        auto bbox = Box( point.coords, Vector2D(0,0) );
        auto r = rtree.search( bbox );
        
        foreach( i, c; r )
            if( c.payload.point == point )
                return &c.payload;
                
        Node n = Node( point );
        return rtree.addObject( bbox, n );
    }
}

unittest
{
    struct Coords
    {
        Vector2D coords;
        
        bool opEquals( in Coords c ) const
        {
            return coords == c.coords;
        }
    }
    
    alias Graph!( Coords, float, string ) G;
    
    auto g = new G;
    Coords prev;
    
    for( auto y=0; y<3; y++ )
        for( auto x=0; x<3; x++ )
        {
            Coords curr = { coords: Vector2D(x, y) };
            g.addEdge( prev, curr, 10 );
            prev = curr;
        }
}
