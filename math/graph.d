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

        open ~= start;
        score[start] = Score( null, 0, start.point.heuristic( goal.point ) );

        while( open.length > 0 )
        {
            // Search for open node having the lowest heuristic value
            size_t key;
            float key_score;
            foreach( i, n; open )
                if( score[n].full < key_score )
                {
                    key = i;
                    key_score = score[n].full;
                }

            const (Node)* curr = open[key];

            if( curr == goal )
                return reconstructPath( score, goal );

            open.remove(key);
            closed ~= curr;

            foreach( i, e; curr.edges )
            {
                auto neighbor = e.node;

                if( canFind( closed, neighbor ) )
                    continue;

                auto tentative = score[curr].g + curr.point.distance( neighbor.point );

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
                score[neighbor].full = tentative + neighbor.point.heuristic( goal.point );
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
        float full; /// Estimated total cost from start to goal through node
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

        float distance( in DumbPoint v ) const
        {
            return heuristic( v );
        }

        float heuristic( in DumbPoint v ) const
        {
            return (coords - v.coords).length;
        }
    }

    alias Graph!( DumbPoint, float, string ) G;

    auto g = new G;

    for( auto y=0; y<5; y++ )
        for( auto x=0; x<5; x++ )
        {
            DumbPoint from = { coords: Vector2D(x, y) };
            DumbPoint to = { coords: Vector2D(x, y+1) };
            
            g.addEdge( from, to, 10 );
        }

    writeln( g );

    DumbPoint f_p = { Vector2D(2,0) };
    DumbPoint g_p = { Vector2D(4,4) };

    auto from = g.search( f_p );
    auto goal = g.search( g_p );

    auto s = g.findPath( from, goal );
    
    assert( s !is null );
    foreach( i, c; s )
        writeln( c );
}
