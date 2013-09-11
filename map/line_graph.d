module map.line_graph;

import map.map_graph;
import math.graph.digraph;
import cat = config.categories: Line;


struct MapGraphLine
{
    MapGraphPolyline polyline;
    alias polyline this;
    
    this( MapCoords[] points, cat.Line type )
    {
        polyline = MapGraphPolyline( points, type );
    }
}

alias DirectedGraph!( MapGraphPoint, MapGraphLine ) DG;
alias MapGraph!( DG, MapGraphPoint, MapGraphLine ) LineGraph;

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
    
    alias TPolylineDescription!( cat.Line, getNodeByID ) PolylineDescription;
    
    auto w1 = PolylineDescription( n1, cat.Line.HIGHWAY );
    auto w2 = PolylineDescription( n2, cat.Line.PRIMARY );
    
    PolylineDescription[] lines = [ w1, w2 ];
    
    auto prepared = cutOnCrossings( lines );
    
    assert( prepared.length == 5 );
    
    auto g = new G( [ w1, w2 ] );
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
