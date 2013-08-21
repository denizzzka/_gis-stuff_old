module math.graph;

debug import math.geometry;
debug(graph) import std.stdio;

import std.algorithm;
import std.range: isInputRange;


struct TEdge( _Weight, _Payload )
{
    alias _Payload Payload;
    alias _Weight Weight;
    
    const Weight weight;
    const size_t to_node; /// direction
    const Payload payload;
    
    invariant()
    {
        assert( weight >= 0 );
    }
}

struct TNode( _Edge, _Payload )
{
    alias _Payload Payload;
    alias _Edge Edge;
    
    Edge[] edges_storage;
    
    const Payload point;
    
    struct EdgesRange
    {
        private
        {
            const TNode* node;
            size_t edge_idx;
        }
        
        Edge* front() { return cast(Edge*) &node.edges_storage[ edge_idx ]; }
        void popFront() { ++edge_idx; }
        bool empty() const { return edge_idx >= length; }
        size_t length() const { return node.edges_storage.length; }
    }
    
    EdgesRange edges() const
    {
        return EdgesRange( &this, 0 );
    }
    
    void addEdge( Edge edge )
    {
        edges_storage ~= edge;
    }
}

class Graph( Node )
{
    alias Node.Edge Edge;
    alias Edge.Weight Weight;
    
private:
    
    // TODO: remove it
    size_t[const Node.Payload] points; /// AA used for fast search of stored points
    
    invariant()
    {
        //assert( isInputRange( typeof( Node.edges ) ) );
    }
    
public:
    
    Node[] nodes; /// contains nodes with all payload    
    
    size_t addPoint( in Node.Payload v )
    {
        auto p = ( v in points );
        
        if( p !is null )
            return *p;
        else
        {
            points[v] = nodes.length;
            
            Node n = { point: v };
            nodes ~= n;
            
            return nodes.length-1;
        }
    }
    
    void addEdge(T)( in size_t from_idx, T edge )
    {
        nodes[ from_idx ].addEdge( edge );
    }
    
    // TODO: remove it?
    void addEdgeToPayload(T)( in Node.Payload from, T edge )
    {
        size_t from_idx = addPoint( from );
        
        addEdge( from_idx, edge );
    }
    
    bool search( in Node.Payload point, out size_t index )
    {
        auto p = point in points;
        
        if( p is null )
            return false;
        else
        {
            index = *p;
            return true;
        }
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
            
            Node* curr = &nodes[currNode];
            debug(graph) writefln("Curr %s %s lowest full=%s", currNode, curr.point, key_score);
            
            open = open[0..key] ~ open[key+1..$];
            closed ~= currNode;
            
            foreach( e; curr.edges )
            {
                size_t neighborNode = e.to_node;
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
    
    auto reconstructPath( in Score[size_t] came_from, size_t curr )
    {
        size_t[] res;

        do
            res ~= curr;
        while( curr in came_from, curr = came_from[curr].came_from );

        return res;
    }

    static struct Score
    {
        size_t came_from; /// Navigated node
        float g; /// Cost from start along best known path
        float full; /// f(x), estimated total cost from start to goal through node
    }
}
    
// Dumb Node Payload
debug
struct DNP
{
    Vector2D!float coords;
    
    @disable
    bool opEquals( in DNP v ) const
    {
        return coords == v.coords;
    }

    float distance( in DNP v, in float weight ) const
    {
        return (coords - v.coords).length * weight;
    }

    float heuristic( in DNP v ) const
    {
        return (coords - v.coords).length;
    }
}

unittest
{
    import math.geometry;
    
    alias TEdge!( float, string ) Edge;
    alias TNode!( Edge, DNP ) Node;
    alias Graph!( Node ) G;
    
    auto g = new G;
    
    for( auto s = 0; s <= 10; s+=10 )
        for( auto y=0; y<5; y++ )
            for( auto x=0; x<5; x++ )
            {
                DNP from = { coords: Vector2D!float(x+s, y) };
                DNP to_up = { coords: Vector2D!float(x+s, y+1) };
                DNP to_right = { coords: Vector2D!float(x+1+s, y) };
                
                size_t to_up_idx = g.addPoint( to_up );
                size_t to_right_idx = g.addPoint( to_right );
                
                auto payload = "666";
                
                Edge edge1 = { weight: 5, to_node: to_up_idx, payload: payload };
                Edge edge2 = { weight: 4.7, to_node: to_right_idx, payload: payload };
                
                g.addEdgeToPayload( from, edge1 );
                g.addEdgeToPayload( from, edge2 );
            }

    DNP f_p = { Vector2D!float(2,0) };
    DNP g_p = { Vector2D!float(4,4) };
    
    size_t from, goal;
    assert( g.search( f_p, from ) );
    assert( g.search( g_p, goal ) );
    
    auto s = g.findPath( from, goal );
    
    assert( s !is null );
    assert( s.length == 7 );
    
    debug(graph)
        foreach( i, c; s )
            writeln( c, " ", g.nodes[c].point );
            
    DNP g2_p = { Vector2D!float(11,4) };
    size_t goal2;
    assert( g.search( g2_p, goal2 ) );
    s = g.findPath( from, goal2 );
    assert(!s); // path in unconnected graph can not be found
}
