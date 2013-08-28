module math.graph.pathfinder;

import math.graph.graph;

import std.algorithm: canFind;
debug(graph) import std.stdio;


struct PathElement
{
    size_t node_idx;
    size_t came_through_edge_idx;
}

/// A* algorithm
///
/// Returns: elements in the reverse order
PathElement[] findPath( Graph )( in Graph graph, in size_t startNode, in size_t goalNode )
{
    auto r = findPathScore( graph, startNode, goalNode );
    return (r is null) ? null : reconstructPath( r, goalNode );
}

private
{
    /// A* algorithm
    Score[size_t] findPathScore( Graph )( in Graph graph, in size_t startNode, in size_t goalNode )
    in
    {
        assert( startNode < graph.nodes.length );
        assert( goalNode < graph.nodes.length );
    }
    body
    {
        alias Graph.Node Node;
        
        const (size_t)[] open; /// The set of tentative nodes to be evaluated
        const (size_t)[] closed; /// The set of nodes already evaluated
        Score[size_t] score;
        
        const Node* start = &graph.nodes[startNode];
        const Node* goal = &graph.nodes[goalNode];
        
        Score startScore = {
                came_from: typeof(Score.came_from).max, // magic for correct path reconstruct
                came_through_edge: 666, // not magic, just for ease of debugging
                g: 0,
                full: start.point.heuristic( goal.point )
            };
        
        score[startNode] = startScore;
        open ~= startNode;
        
        debug(graph) writefln("Path goal point: %s", goal.point );
        
        while( open.length > 0 )
        {
            debug(graph) writeln("Open: ", open);
            debug(graph) writeln("open.length=", open.length);
            debug(graph) writeln("closed.length=", closed.length);
            debug(graph) writeln("score.length=", score.length);
            
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
            
            const Node* curr = &graph.nodes[currNode];
            debug(graph) writefln("Curr %s %s lowest full=%s", currNode, curr.point, key_score);
            
            open = open[0..key] ~ open[key+1..$];
            closed ~= currNode;
            
            size_t edge_idx = -1;
            foreach( e; curr.edges( currNode ) )
            {
                edge_idx++;
                
                size_t neighborNode = e.to_node;
                const Node* neighbor = &graph.nodes[neighborNode];

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
                Score neighborScore = {
                        came_from: currNode,
                        came_through_edge: edge_idx,
                        g: tentative,
                        full: tentative + neighbor.point.heuristic( goal.point )
                    };
                    
                score[neighborNode] = neighborScore;
                
                debug(graph)
                    writefln("Upd neighbor=%s edge=%s %s tentative=%s full=%s",
                        neighborNode, edge_idx, neighbor.point, tentative, score[neighborNode].full);                
            }
        }

        return null;
    }
    
    PathElement[] reconstructPath( Score[size_t] scores, size_t curr )
    {
        PathElement[] res;
        
        Score* p;
        while( p = curr in scores, p )
        {
            PathElement e;
            e.node_idx = curr;
            e.came_through_edge_idx = p.came_through_edge;
            
            res ~= e;
            
            curr = p.came_from;
        }

        return res;
    }
    
    static struct Score
    {
        size_t came_from; /// Navigated node
        size_t came_through_edge;
        float g; /// Cost from start along best known path
        float full; /// f(x), estimated total cost from start to goal through node
    }
}

unittest
{
    import math.geometry;
    
    struct TEdge( _Weight, _Payload )
    {
        alias _Payload Payload;
        alias _Weight Weight;
        
        const size_t to_node; /// direction
        Weight weight;
        Payload payload;
        
        invariant()
        {
            assert( weight >= 0 );
        }
    }
    
    // Dumb Node Point
    struct DNP
    {
        Vector2D!float coords;
        
        float distance( in DNP v, in float weight ) const
        {
            return (coords - v.coords).length * weight;
        }

        float heuristic( in DNP v ) const
        {
            return (coords - v.coords).length;
        }
    }
    
    alias TEdge!( float, string ) Edge;
    alias TNode!( Edge, DNP ) Node;
    alias Graph!( Node ) G;
    
    auto g = new G;
    
    immutable size_t width = 5;
    size_t[ width+1 ] row;
    
    size_t from_idx;
    size_t goal_idx;
    
    for( auto y=0; y < 5; y++ )
        for( auto x=0; x < width; x++ )
        {
            size_t from;
            
            if( x == 0 && y == 0 )
            {
                DNP from_point = { coords: Vector2D!float(x, y) };
                from = g.addPoint( from_point );
            }
            else
                from = row[x];
            
            // saving test points:
            if( x == 2 && y == 0 ) from_idx = from;
            if( x == 4 && y == 4 ) goal_idx = from;
            
            DNP to_up = { coords: Vector2D!float(x, y+1) };
            DNP to_right = { coords: Vector2D!float(x+1, y) };
            
            row[x] = g.addPoint( to_up );
            
            if( y == 0 )
                row[x+1] = g.addPoint( to_right );
            
            auto payload = "payload_string";
            
            Edge up_edge = { weight: 5, to_node: row[x], payload: payload };
            Edge right_edge = { weight: 4.7, to_node: row[x+1], payload: payload };
            
            g.addEdge( from, up_edge );
            g.addEdge( from, right_edge );
        }
    
    auto s = g.findPath( from_idx, goal_idx );
    
    assert( s != null );
    assert( s.length == 7 );
    
    /*
    DNP g2_p = { Vector2D!float(11,4) };
    size_t goal2;
    assert( g.search( g2_p, goal2 ) );
    
    s = g.findPath( from, goal2 );
    assert(!s); // path in unconnected graph can not be found
    */
}
