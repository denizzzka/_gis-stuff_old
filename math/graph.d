module math.graph;

import math.geometry;
import math.rtree2d;

import std.algorithm;
version(unittest) import std.string;

class Graph( Point, Weight, Payload )
{
private:
    
    Node*[] entry; // entry points
    Node[const Point] points;
    
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
    
    debug(graph)
    override string toString()
    {
        string res;
        
        foreach( ref c; points )
            res ~= format( "%s %s\n", &c, c );
            
        return res;
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
    
    Node* search( in Point point )
    {
        return ( point in points )? &points[point] : null;
    }
    
    /// A* algorithm
    const (Node*)[] findPath( in Node* start, in Node* goal )
    {
        const (Node)*[] open; // The set of tentative nodes to be evaluated
        const (Node*)[] closed; // The set of nodes already evaluated
        const (Node*)[Node*] came_from; // Navigated nodes
        const (float)[Node*] g_score; // Cost from start along best known path
        const (float)[Node*] full_score; // // Estimated total cost from start to goal through node
        
        open ~= start;
        g_score[start] = 0;
        full_score[start] = start.point.heuristic( goal.point );
        
        while( open.length > 0 )
        {
            // Search for open node having the lowest heuristic value
            size_t key;
            float key_score;
            foreach( i, n; open )
                if( full_score[n] < key_score )
                {
                    key = i;
                    key_score = full_score[n];
                }
                
            const (Node)* curr = open[key];
            
            if( curr == goal )
                return reconstructPath( came_from, goal );
            
            open.remove(key);
            closed ~= curr;
            
            foreach( i, e; curr.edges )
            {
                auto neighbor = e.node;
                
                auto tentative = g_score[curr] + curr.point.heuristic( neighbor.point );
                
                if( canFind( closed, neighbor ) && tentative >= g_score[neighbor] )
                    continue;
                
                if( !canFind( open, neighbor ) || tentative < g_score[neighbor] )
                {
                    came_from[neighbor] = curr;
                    g_score[neighbor] = tentative;
                    full_score[neighbor] = tentative +  neighbor.point.heuristic( goal.point );
                    
                    if( !canFind( open, neighbor ) )
                        open ~= neighbor;
                }
            }
            
            assert( false, "bug detected" );
        }
        
        assert( false, "bug detected" );
    }
    
private:
    Node* addPoint( in Point v )
    {
        if( v !in points )
        {
            Node n = { point: v };
            points[v] = n;
        }
        
        return &points[v];
    }
    
    const (Node*)[] reconstructPath( in Node*[Node*] came_from, const (Node)* curr )
    {
        const (Node*)[] res;
        
        do
            res ~= curr;
        while( curr in came_from, curr = came_from[curr] );
        
        return res;
    }
}

unittest
{
    import std.stdio;
    
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
    DumbPoint prev = { coords: Vector2D(2,2) };
    
    for( auto y=0; y<3; y++ )
        for( auto x=0; x<3; x++ )
        {
            DumbPoint curr = { coords: Vector2D(x, y) };
            g.addEdge( prev, curr, 10 );
            prev = curr;
        }
    
    writeln( g );
    
    DumbPoint f_p = { Vector2D(1,0) };
    DumbPoint g_p = { Vector2D(2,2) };
    
    auto from = g.search( f_p );
    auto goal = g.search( g_p );
    
    auto s = g.findPath( from, goal );
    
    writeln( s );
}
