module math.graph.new_pathfinder;

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
PathElement[] findPath( Graph, NodeDescr )( in Graph graph, in NodeDescr startNode, in NodeDescr goalNode )
{
    auto r = findPathScore( graph, startNode, goalNode );
    return (r is null) ? null : reconstructPath!( NodeDescr )( r, goalNode );
}

private
{
    /// A* algorithm
    Score[NodeDescr] findPathScore( Graph, NodeDescr )( in Graph graph, in NodeDescr startNode, in NodeDescr goalNode )
    in
    {
        assert( startNode.idx < graph.nodes.length );
        assert( goalNode.idx < graph.nodes.length );
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
            
            const NodeDescr currNode = open[key];
            
            if( currNode == goalNode )
                return score;
            
            const Node* curr = &graph.nodes[currNode.idx];
            debug(graph) writefln("Curr %s %s lowest full=%s", currNode, curr.point, key_score);
            
            open = open[0..key] ~ open[key+1..$];
            closed ~= currNode;
            
            size_t edge_idx = -1;
            foreach( e; curr.edges )
            {
                edge_idx++;
                
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
                        came_from: currNode.idx,
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
    
    PathElement[] reconstructPath(NodeDescr)( Score[NodeDescr] scores, NodeDescr curr )
    {
        PathElement[] res;
        
        Score* p;
        while( p = curr in scores, p )
        {
            PathElement e;
            e.node_idx = curr.idx;
            e.came_through_edge_idx = p.came_through_edge;
            
            res ~= e;
            
            curr.idx = p.came_from;
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
    
    auto g = new G;
    
    immutable size_t width = 5;
    NodeDescr[ width+1 ] row;
    
    NodeDescr from_idx;
    NodeDescr goal_idx;
    
    for( auto y=0; y < 5; y++ )
        for( auto x=0; x < width; x++ )
        {
            NodeDescr from;
            
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
            
            EdgePayload up_edge_payload = { weight: 5 };
            EdgePayload right_edge_payload = { weight: 4.7 };
            
            G.ConnectionInfo conn_up_edge = { from: from, to: row[x] };
            G.ConnectionInfo conn_right_edge = { from: from, to: row[x+1] };
            
            g.addEdge( conn_up_edge, up_edge_payload );
            g.addEdge( conn_right_edge, right_edge_payload );
        }
    
    auto s = g.findPath( from_idx, goal_idx );
    
    assert( s != null );
    assert( s.length == 7 );
    
    DNP g2_p = { Vector2D!float(11,4) };
    NodeDescr goal2_idx = g.addPoint( g2_p );
    
    s = g.findPath( from_idx, goal2_idx );
    assert(!s); // path to unconnected point can not be found
}
