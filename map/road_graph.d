module map.road_graph;

import map.map_graph;
import math.graph.undirected;
import math.graph.pathfinder: PathFinder;
import cat = config.categories: Line;


struct RoadProperties
{
    cat.Line type;
    float weight = 1;
}

struct RoadLine
{
    package MapGraphPolyline polyline;
    
    RoadProperties properties;
    alias properties this;
    
    this( MapCoords[] points, RoadProperties properties )
    {
        polyline = MapGraphPolyline( points );
        this.properties = properties;
    }
}

alias UndirectedGraph!( MapGraphPoint, RoadLine ) UG;

class RoadGraph : MapGraph!( UG, MapGraphPoint, RoadLine )
{
    RoadGraph.PolylineDescriptor[] findPath( NodeDescr from_node, NodeDescr to_node ) const
    {
        alias PathFinder!( UG ) PF;
        
        auto path = PF.findPath( graph, from_node, to_node );
        
        debug(path) writeln("path from=", from_node, " to=", to_node);
        
        RoadGraph.PolylineDescriptor[] res;
        
        if( path != null )
            for( auto i = 1; i < path.length; i++ )
                res ~= path[i-1].came_through_edge;
        
        return res;
    }
    
    override
    MapCoords[] getMapCoords( in PolylineDescriptor descr ) const
    {
        MapCoords[] res;
        
        res ~= graph.getNodePayload( descr.node );
        
        auto edge = graph.getEdge( descr );
        
        if( edge.forward_direction )
            foreach( c; edge.payload.polyline.points )
                res ~= c;
        else
            foreach_reverse( c; edge.payload.polyline.points )
                res ~= c;
        
        res ~= graph.getNodePayload( edge.to_node );
        
        return res;
    }
}

unittest
{
    auto t = new RoadGraph;
}
