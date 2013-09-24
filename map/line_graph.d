module map.line_graph;

import map.map_graph;
import math.graph.digraph;
import math.graph.digraph_compressed;
import cat = config.categories: Line;
static import pbf = pbf.line_graph;


struct LineProperties
{
    cat.Line type;
}

struct MapGraphLine
{
    public const pbf.Line storage;
    alias storage this;
    
    this( MapCoords[] points, LineProperties properties )
    {
        pbf.Line s;
        
        s.polyline = MapGraphPolyline( points );
        s.type = properties.type;
        
        storage = s;
    }
    
    MapCoords[] points() const
    {
        auto s = cast(pbf.Line) storage;
        
        return MapGraphPolyline(s.polyline).points();
    }
    
    cat.Line type() const
    {
        return cast(cat.Line) storage.type;
    }
    
    ubyte[] Serialize() const
    {
        auto s = cast(pbf.Line) storage;
        return s.Serialize;
    }
    
    static MapGraphLine Deserialize( inout ubyte[] from )
    {
        assert(false);
    }
}

alias MapGraph!( DirectedGraph, MapCoords, MapGraphLine ) LineGraph;
alias MapGraph!( DirectedGraphCompressed, MapCoords, MapGraphLine ) LineGraphCompressed;

unittest
{
    import math.geometry;
    
    alias Vector2D!long FC; // foreign coords
    
    alias LineGraph G;
    
    FC[] points = [
            FC(0,0), FC(1,1), FC(2,2), FC(3,3), FC(4,4), // first line
            FC(4,0), FC(3,1), FC(1,3), FC(2,4) // second line
        ];
    
    FC[ulong] nodes;
    
    foreach( i, c; points )
        nodes[ i * 10 ] = c;
    
    ulong[] n1 = [ 0, 10, 20, 30, 40 ];
    ulong[] n2 = [ 50, 60, 20, 70, 80, 30 ];
    
    MapCoords getNodeByID( in ulong id )
    {
        MapCoords res;
        res.map_coords = nodes[ id ];
        
        return res;
    }
    
    alias TPolylineDescription!( LineProperties, getNodeByID ) PolylineDescription;
    
    LineProperties highway = { type: cat.Line.HIGHWAY };
    LineProperties primary = { type: cat.Line.PRIMARY };
    
    auto w1 = PolylineDescription( n1, highway );
    auto w2 = PolylineDescription( n2, primary );
    
    PolylineDescription[] lines = [ w1, w2 ];
    
    auto prepared = cutOnCrossings( lines );
    
    assert( prepared.length == 5 );
    
    auto g = new G( [ w1, w2 ] );
    
    auto compressed = new LineGraphCompressed( g );
}

size_t createEdge( Graph, Payload )(
        Graph graph,
        in size_t from_node_idx,
        in size_t to_node_idx,
        Payload payload )
{
    Graph.Edge edge = { to_node: to_node_idx, payload: payload };
    
    return graph.addEdge( from_node_idx, edge );
}
