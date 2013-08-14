module math.graph;

import std.algorithm;
debug(graph) import std.stdio;


class Graph( NodePayload, Weight )
{
private:
    
    Node[] nodes; /// contains nodes with all payload
    size_t[const NodePayload] points; /// AA used for fast search of stored points
    
public:
    
    struct Edge
    {
        const Weight weight;
        const size_t node;

        invariant()
        {
            assert( weight >= 0 );
        }
    }

    struct Node
    {
        Edge[] edges;
        
        const NodePayload point;
    }
    
    void addEdge( in NodePayload from, in NodePayload to, in Weight w )
    {
        size_t f = addPoint( from );
        size_t t = addPoint( to );

        Edge e = { node: t, weight: w };
        nodes[f].edges ~= e;
    }
    
    bool search( in NodePayload point, out size_t index )
    {
        if( point in points )
        {
            index = points[point];
            return true;
        }
        else
            return false;
    }
    
    /// A* algorithm
    size_t[] findPath( in size_t startNode, in size_t goalNode )
    {
        auto r = findPathScore( startNode, goalNode );
        return (r is null) ? null : reconstructPath( r, goalNode );
    }
    
private:
    
    /// A* algorithm
    Score[size_t] findPathScore( in size_t startNode, in size_t goalNode )
    in
    {
        assert( startNode < nodes.length );
        assert( goalNode < nodes.length );
    }
    body
    {
        const (size_t)[] open; /// The set of tentative nodes to be evaluated
        const (size_t)[] closed; /// The set of nodes already evaluated
        Score[size_t] score;
        
        const Node* start = &nodes[startNode];
        const Node* goal = &nodes[goalNode];
        
        score[startNode] = Score( 0, 0, start.point.heuristic( goal.point ) );
        open ~= startNode;
        
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

            const size_t currNode = open[key];
            
            if( currNode == goalNode )
                return score;
            
            const Node* curr = &nodes[currNode];
            debug(graph) writefln("Curr %s %s lowest full=%s", currNode, curr.point, key_score);
            
            open = open[0..key] ~ open[key+1..$];
            closed ~= currNode;
            
            foreach( i, e; curr.edges )
            {
                size_t neighborNode = e.node;
                Node* neighbor = &nodes[neighborNode];

                if( canFind( closed, neighborNode ) )
                    continue;
                
                auto tentative = score[currNode].g + curr.point.distance( neighbor.point, e.weight );
                
                if( !canFind( open, neighborNode ) )
                {
                    open ~= neighborNode;
                    score[neighborNode] = Score();
                }
                else
                    if( tentative >= score[neighborNode].g )
                        continue;

                // Updating neighbor score
                score[neighborNode].came_from = currNode;
                score[neighborNode].g = tentative;
                score[neighborNode].full = tentative +
                    neighbor.point.heuristic( goal.point );
                
                debug(graph)
                    writefln("Upd neighbor %s %s tentative=%s full=%s",
                        neighborNode, neighbor.point, tentative, score[neighborNode].full);                
            }
        }

        return null;
    }
    
    size_t addPoint( in NodePayload v )
    {
        if( v !in points )
        {
            points[v] = nodes.length;
            
            Node n = { point: v };
            nodes ~= n;
            
            return nodes.length-1;
        }

        return points[v];
    }

    auto reconstructPath( in Score[size_t] came_from, size_t curr )
    {
        size_t[] res;

        do
            res ~= curr;
        while( curr in came_from, curr = came_from[curr].came_from );

        return res;
    }

    struct Score
    {
        size_t came_from; /// Navigated node
        float g; /// Cost from start along best known path
        float full; /// f(x), estimated total cost from start to goal through node
    }
}

unittest
{
    import math.geometry;
    
    struct DumbNodePayload
    {
        Vector2D!float coords;

        bool opEquals( in DumbNodePayload v ) const
        {
            return coords == v.coords;
        }

        float distance( in DumbNodePayload v, in float weight ) const
        {
            return (coords - v.coords).length * weight;
        }

        float heuristic( in DumbNodePayload v ) const
        {
            return (coords - v.coords).length;
        }
    }
    
    alias DumbNodePayload DP;
    alias Graph!( DP, float ) G;

    auto g = new G;
    
    for( auto s = 0; s <= 10; s+=10 )
        for( auto y=0; y<5; y++ )
            for( auto x=0; x<5; x++ )
            {
                DP from = { coords: Vector2D!float(x+s, y) };
                DP to_up = { coords: Vector2D!float(x+s, y+1) };
                DP to_right = { coords: Vector2D!float(x+1+s, y) };
                
                g.addEdge( from, to_up, 5 );
                g.addEdge( from, to_right, 4.7 );
            }

    DP f_p = { Vector2D!float(2,0) };
    DP g_p = { Vector2D!float(4,4) };
    
    size_t from, goal;
    assert( g.search( f_p, from ) );
    assert( g.search( g_p, goal ) );
    
    auto s = g.findPath( from, goal );
    
    assert( s !is null );
    assert( s.length == 7 );
    
    debug(graph)
        foreach( i, c; s )
            writeln( c, " ", g.nodes[c].point );
            
    DP g2_p = { Vector2D!float(11,4) };
    size_t goal2;
    assert( g.search( g2_p, goal2 ) );
    s = g.findPath( from, goal2 );
    assert(!s); // path in unconnected graph can not be found
}
