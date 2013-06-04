module math.graph;

import std.algorithm;
debug(graph) import std.stdio;


class Graph( Point, Weight, Payload )
{
private:

    Node*[] entry; /// entry points
    Node[const Point] points;
    Node[] nodes; // работать здесь :)

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
    in
    {
        assert( start );
        assert( goal );
    }
    body
    {
        const (Node)*[] open; /// The set of tentative nodes to be evaluated
        const (Node*)[] closed; /// The set of nodes already evaluated
        Score[Node*] score;
        
        score[start] = Score( null, 0, start.point.heuristic( goal.point ) );
        open ~= start;
        
        debug(graph) writefln("Path goal point: %s", goal.point );
        
        while( open.length > 0 )
        {
            debug(graph) writeln("Open: ", open);
            
            // Search for open node having the lowest heuristic value
            size_t key;
            float key_score = float.max;
            foreach( i, n; open )
                if( score[n].full < key_score )
                {
                    key = i;
                    key_score = score[n].full;
                }

            const (Node)* curr = open[key];
            debug(graph) writefln("Curr %s %s lowest full=%s", curr, curr.point, key_score);

            if( curr == goal )
                return reconstructPath( score, goal );
            
            open = open[0..key] ~ open[key+1..$];
            closed ~= curr;
            
            foreach( i, e; curr.edges )
            {
                auto neighbor = e.node;

                if( canFind( closed, neighbor ) )
                    continue;
                
                auto tentative = score[curr].g + curr.point.distance( neighbor.point, e.weight );
                
                if( !canFind( open, neighbor ) )
                {
                    open ~= neighbor;
                    score[neighbor] = Score();
                }
                else
                    if( tentative >= score[neighbor].g )
                        continue;

                // Updating neighbor score
                score[neighbor].came_from = curr;
                score[neighbor].g = tentative;
                score[neighbor].full = tentative +
                    neighbor.point.heuristic( goal.point );
                
                debug(graph)
                    writefln("Upd neighbor %s %s tentative=%s full=%s",
                        neighbor, neighbor.point, tentative, score[neighbor].full);                
            }
        }

        return null;
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

    const (Node*)[] reconstructPath( in Score[Node*] came_from, const (Node)* curr )
    {
        const (Node*)[] res;

        do
            res ~= curr;
        while( curr in came_from, curr = came_from[curr].came_from );

        return res;
    }

    struct Score
    {
        const (Node)* came_from; /// Navigated node
        float g; /// Cost from start along best known path
        float full; /// f(x), estimated total cost from start to goal through node
    }
}

unittest
{
    import math.geometry;
    
    struct DumbPoint( W )
    {
        Vector2D coords;

        bool opEquals( in DumbPoint v ) const
        {
            return coords == v.coords;
        }

        float distance( in DumbPoint v, in W weight ) const
        {
            return (coords - v.coords).length * weight;
        }

        float heuristic( in DumbPoint v ) const
        {
            return (coords - v.coords).length;
        }
    }
    
    alias DumbPoint!float DP;
    alias Graph!( DP, float, string ) G;

    auto g = new G;

    for( auto y=0; y<5; y++ )
        for( auto x=0; x<5; x++ )
        {
            DP from = { coords: Vector2D(x, y) };
            DP to_up = { coords: Vector2D(x, y+1) };
            DP to_right = { coords: Vector2D(x+1, y) };
            
            g.addEdge( from, to_up, 5 );
            g.addEdge( from, to_right, 4 );
        }

    DP f_p = { Vector2D(2,0) };
    DP g_p = { Vector2D(4,4) };

    auto from = g.search( f_p );
    auto goal = g.search( g_p );

    auto s = g.findPath( from, goal );
    
    assert( s !is null );
    assert( s.length == 7 );
    
    debug(graph)
        foreach( i, c; s )
            writeln( c, " ", c.point );
}
