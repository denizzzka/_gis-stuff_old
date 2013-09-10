module map.new_road_graph;

import map.new_map_graph;
import math.graph.undirected;
import math.graph.new_pathfinder: PathFinder;

struct RoadPoint
{
    MapGraphPoint point;
    alias point this;
    
    byte level = 0;
    
    this( MapCoords coords )
    {
        point.coords = coords;
    }
}

struct RoadLine
{
    MapPolyline polyline;
    alias polyline this;
    
    float weight = 0;
    
    this( MapCoords[] points, cat.Line type )
    {
        polyline = MapPolyline( points, type );
    }
}

alias UndirectedGraph!( RoadPoint, RoadLine ) UG;

class RoadGraph : MapGraph!( UG, RoadPoint, RoadLine )
{
    RoadGraph.PolylineDescriptor[] findPath( NodeDescr from_node, NodeDescr to_node ) const
    {
        alias PathFinder!( UG ) PF;
        
        auto path = PF.findPath( graph, from_node, to_node );
        
        debug(path) writeln("path from=", from_node, " to=", to_node);
        
        RoadGraph.PolylineDescriptor[] res;
        
        if( path != null )
            for( auto i = 1; i < path.length; i++ )
                res ~= RoadGraph.PolylineDescriptor( path[i].node, path[i-1].came_through_edge );
        
        return res;
    }
}

unittest
{
    auto t = new RoadGraph;
}
