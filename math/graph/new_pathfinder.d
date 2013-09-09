module math.graph.new_pathfinder;

import std.algorithm: canFind;
debug(graph) import std.stdio;


template PathFinder( Graph, NodeDescr, EdgeDescr )
{
    struct PathElement
    {
        NodeDescr node;
        EdgeDescr came_through_edge;
    }
    
    /// A* algorithm
    ///
    /// Returns: elements in the reverse order
    PathElement[] findPath( in Graph graph, in NodeDescr startNode, in NodeDescr goalNode )
    {
        auto r = findPathScore( graph, startNode, goalNode );
        return (r is null) ? null : reconstructPath( r, goalNode );
    }
    
    private
    {
        /// A* algorithm
        Score[NodeDescr] findPathScore( in Graph graph, in NodeDescr startNode, in NodeDescr goalNode )
        in
        {
            assert( graph.isAvailable( startNode ) );
            assert( graph.isAvailable( goalNode ) );
        }
        body
        {
            alias Graph.Node Node;
            
            const (NodeDescr)[] open; /// The set of tentative nodes to be evaluated
            const (NodeDescr)[] closed; /// The set of nodes already evaluated
            Score[NodeDescr] score;
            
            const Node* start = &graph.nodes[startNode.idx];
            const Node* goal = &graph.nodes[goalNode.idx];
            
            Score startScore = {
                    came_from: { idx: typeof(Score.came_from.idx).max }, // magic for correct path reconstruct
                    came_through_edge: { idx: 666 }, // not magic, just for ease of debugging
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
                
                const NodeDescr currNode = open[key];
                
                if( currNode == goalNode )
                    return score;
                
                const Node* curr = &graph.nodes[currNode.idx];
                debug(graph) writefln("Curr %s %s lowest full=%s", currNode, curr.point, key_score);
                
                open = open[0..key] ~ open[key+1..$];
                closed ~= currNode;
                
                EdgeDescr edge = { idx: -1 };
                foreach( e; curr.edges )
                {
                    edge.idx++;
                    
                    NodeDescr neighborNode = e.to_node;
                    const Node* neighbor = &graph.nodes[neighborNode.idx];

                    if( canFind( closed, neighborNode ) )
                        continue;
                    
                    auto tentative = score[currNode].g + curr.point.distance( neighbor.point, e.payload.weight );
                    
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
                            came_through_edge: edge,
                            g: tentative,
                            full: tentative + neighbor.point.heuristic( goal.point )
                        };
                        
                    score[neighborNode] = neighborScore;
                    
                    debug(graph)
                        writefln("Upd neighbor=%s edge=%s %s tentative=%s full=%s",
                            neighborNode, edge.idx, neighbor.point, tentative, score[neighborNode].full);                
                }
            }

            return null;
        }
        
        PathElement[] reconstructPath( Score[NodeDescr] scores, NodeDescr curr )
        {
            PathElement[] res;
            
            Score* p;
            while( p = curr in scores, p )
            {
                PathElement e;
                e.node = curr;
                e.came_through_edge = p.came_through_edge;
                
                res ~= e;
                
                curr = p.came_from;
            }

            return res;
        }
        
        static struct Score
        {
            NodeDescr came_from; /// Navigated node
            EdgeDescr came_through_edge;
            float g; /// Cost from start along best known path
            float full; /// f(x), estimated total cost from start to goal through node
        }
    }
}

unittest
{
    import math.graph.digraph;
    import math.geometry;
    
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
    
    struct EdgePayload { float weight; }
    
    alias DirectedGraph!( DNP, EdgePayload ) G;
    alias PathFinder!( G, NodeDescr, EdgeDescr ) pathFinder;
    
    auto g = new G;
    
    immutable size_t width = 5;
    NodeDescr[ width+1 ] row;
    
    NodeDescr from;
    NodeDescr goal;
    
    for( auto y=0; y < 5; y++ )
        for( auto x=0; x < width; x++ )
        {
            NodeDescr start_from;
            
            if( x == 0 && y == 0 )
            {
                DNP from_point = { coords: Vector2D!float(x, y) };
                start_from = g.addPoint( from_point );
            }
            else
                start_from = row[x];
            
            // saving test points:
            if( x == 2 && y == 0 ) from = start_from;
            if( x == 4 && y == 4 ) goal = start_from;
            
            DNP to_up = { coords: Vector2D!float(x, y+1) };
            DNP to_right = { coords: Vector2D!float(x+1, y) };
            
            row[x] = g.addPoint( to_up );
            
            if( y == 0 )
                row[x+1] = g.addPoint( to_right );
            
            EdgePayload up_edge_payload = { weight: 5 };
            EdgePayload right_edge_payload = { weight: 4.7 };
            
            G.ConnectionInfo conn_up_edge = { from: start_from, to: row[x] };
            G.ConnectionInfo conn_right_edge = { from: start_from, to: row[x+1] };
            
            g.addEdge( conn_up_edge, up_edge_payload );
            g.addEdge( conn_right_edge, right_edge_payload );
        }
    
    auto s = pathFinder.findPath( g, from, goal );
    
    assert( s != null );
    assert( s.length == 7 );
    
    DNP g2_p = { Vector2D!float(11,4) };
    NodeDescr goal2 = g.addPoint( g2_p );
    
    s = pathFinder.findPath( g, from, goal2 );
    assert(!s); // path to unconnected point can not be found
}