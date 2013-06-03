module math.graph;

import math.geometry;
import math.rtree2d;

import std.algorithm;

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
    
    void searchPath( in Node* start, in Node* goal )
    {
        const (Node)*[] closed; // The set of nodes already evaluated
        const (Node)*[] open; // The set of tentative nodes to be evaluated
        Node*[Node*] came_from; // Navigated nodes
        float[Node*] g_score; // Cost from start along best known path
        float[Node*] f_score; // // Estimated total cost from start to goal through node
        
        Node* res;
        
        open ~= start;
        g_score[start] = 0;
        f_score[start] = g_score[start] + start.point.heuristic( goal.point );
        
        while( open.length > 0 )
        {
            // Search for open node having the lowest heuristic value
            size_t k;
            float k_score;
            foreach( i, n; open )
                if( f_score[n] < k_score )
                {
                    k = i;
                    k_score = f_score[n];
                }
                
            const (Node)* curr = open[k];
            
            if( curr == goal )
                return; // TODO
            
            open.remove(k);
            closed ~= curr;
            
            foreach( i, e; curr.edges )
            {
                auto neighbor = e.node;
                
                auto tentative = g_score[curr] + curr.point.heuristic( neighbor.point );
                
                if( canFind( closed, neighbor ) && tentative >= g_score[neighbor] )
                {
                    
                }
            }
        }
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
    struct DumbPoint
    {
        Vector2D coords;
        
        bool opEquals( in DumbPoint v ) const
        {
            return coords == v.coords;
        }
        
        float heuristic( in DumbPoint v ) const
        {
            return (coords - v.coords).length;
        }
    }
    
    alias Graph!( DumbPoint, float, string ) G;
    
    auto g = new G;
    DumbPoint prev;
    
    for( auto y=0; y<3; y++ )
        for( auto x=0; x<3; x++ )
        {
            DumbPoint curr = { coords: Vector2D(x, y) };
            g.addEdge( prev, curr, 10 );
            prev = curr;
        }
}
