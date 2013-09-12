module math.graph.pathfinder;

import std.algorithm: canFind;
debug(pathfinder) import std.stdio;


class PathFinder( GraphEngine ) : GraphEngine
{    
    abstract
    real heuristicDistance( in NodeDescr fromDescr, in NodeDescr toDescr ) const;
    
    abstract
    real distance( in EdgeDescr edgeDescr ) const;
    
    /// A* algorithm
    ///
    /// Returns: elements in the reverse order
    EdgeDescr[] findPath( in NodeDescr start, in NodeDescr goal )
    {
        auto r = findPathScore( start, goal );
        return (r is null) ? null : reconstructPath( r, goal );
    }
    
    private
    {
        /// A* algorithm
        Score[NodeDescr] findPathScore( in NodeDescr startDescr, in NodeDescr goalDescr )
        in
        {
            assert( isAvailable( startDescr ) );
            assert( isAvailable( goalDescr ) );
        }
        body
        {
            const (NodeDescr)[] open; /// The set of tentative nodes to be evaluated
            const (NodeDescr)[] closed; /// The set of nodes already evaluated
            Score[NodeDescr] score;
            
            Score startScore =
            {
                came_through_edge: EdgeDescr(
                        NodeMagic, // magic for correct path reconstruct
                        666 // not magic, just for ease of debugging
                    ),
                g: 0,
                full: heuristicDistance( startDescr, goalDescr )
            };
            
            score[startDescr] = startScore;
            open ~= startDescr;
            
            while( open.length > 0 )
            {
                debug( pathfinder )
                {
                    writeln("Open: ", open);
                    writeln("open.length=", open.length);
                    writeln("closed.length=", closed.length);
                    writeln("score.length=", score.length);
                }
                
                // Search for open node having the lowest heuristic value
                size_t key;
                float key_score = float.max;
                foreach( i, n; open )
                    if( score[n].full < key_score )
                    {
                        key = i;
                        key_score = score[n].full;
                    }
                
                const NodeDescr currDescr = open[key];
                
                if( currDescr == goalDescr )
                    return score;
                
                const auto curr = getNodePayload( currDescr );
                debug(pathfinder) writefln("Curr %s lowest full=%s", currDescr, key_score);
                
                open = open[0..key] ~ open[key+1..$];
                closed ~= currDescr;
                
                foreach( edge; getEdgesRange( currDescr ) )
                {
                    NodeDescr neighborDescr = getEdge( edge ).to_node;
                    
                    if( canFind( closed, neighborDescr ) )
                        continue;
                    
                    auto tentative = score[currDescr].g + distance( edge );
                    
                    if( !canFind( open, neighborDescr ) )
                    {
                        open ~= neighborDescr;
                        score[neighborDescr] = Score();
                    }
                    else
                        if( tentative >= score[neighborDescr].g )
                            continue;
                    
                    // Updating neighbor score
                    Score neighborScore = {
                            came_through_edge: edge,
                            g: tentative,
                            full: tentative + heuristicDistance( neighborDescr, goalDescr )
                        };
                        
                    score[neighborDescr] = neighborScore;
                    
                    debug(pathfinder)
                        writefln("Upd neighbor=%s edge=%s %s tentative=%s full=%s",
                            neighborDescr, edge, neighborDescr, tentative, score[neighborDescr].full);                
                }
            }

            return null;
        }
        
        EdgeDescr[] reconstructPath( Score[NodeDescr] scores, NodeDescr curr )
        {
            EdgeDescr[] res;
            
            Score* p;
            while( p = curr in scores, p )
            {
                res ~= p.came_through_edge;
                
                curr = p.came_through_edge.node;
            }

            return res;
        }
        
        static struct Score
        {
            EdgeDescr came_through_edge; // edge with navigated node inside
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
    static struct DNP
    {
        Vector2D!float coords;
        
        real direct_distance( in DNP v ) const
        {
            return (coords - v.coords).length;
        }
    }
    
    static struct EdgePayload { float weight; }
    
    alias DirectedGraph!( DNP, EdgePayload ) DG;
    
    class G : PathFinder!DG
    {
        override
        real heuristicDistance( in NodeDescr fromDescr, in NodeDescr toDescr ) const
        {
            auto from = getNodePayload( fromDescr );
            auto to = getNodePayload( toDescr );
            
            return from.direct_distance( to );
        }
        
        override
        real distance( in EdgeDescr edgeDescr ) const
        {
            auto nodeDescr = edgeDescr.node;
            auto node = getNodePayload( nodeDescr );
            auto edge = getEdge( edgeDescr );
            auto to_node = getNodePayload( edge.to_node );
            
            return node.direct_distance( to_node ) * edge.payload.weight;
        }
    }
    
    alias G.NodeDescr NodeDescr;
    
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
                start_from = g.addNode( from_point );
            }
            else
                start_from = row[x];
            
            // saving test points:
            if( x == 2 && y == 0 ) from = start_from;
            if( x == 4 && y == 4 ) goal = start_from;
            
            DNP to_up = { coords: Vector2D!float(x, y+1) };
            DNP to_right = { coords: Vector2D!float(x+1, y) };
            
            row[x] = g.addNode( to_up );
            
            if( y == 0 )
                row[x+1] = g.addNode( to_right );
            
            EdgePayload up_edge_payload = { weight: 5 };
            EdgePayload right_edge_payload = { weight: 4.7 };
            
            G.ConnectionInfo conn_up_edge = { from: start_from, to: row[x] };
            G.ConnectionInfo conn_right_edge = { from: start_from, to: row[x+1] };
            
            g.addEdge( conn_up_edge, up_edge_payload );
            g.addEdge( conn_right_edge, right_edge_payload );
        }
    
    auto s = g.findPath( from, goal );
    
    assert( s != null );
    assert( s.length == 7 );
    
    debug(pathfinder)
    {
        writeln("found path:");
        foreach( c; s )
            writeln("path element: ", c);
    }
    
    DNP g2_p = { Vector2D!float(11,4) };
    NodeDescr goal2 = g.addNode( g2_p );
    
    s = g.findPath( from, goal2 );
    assert(!s); // path to unconnected point can not be found
}
