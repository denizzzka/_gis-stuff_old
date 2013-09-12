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

class RoadGraph : MapGraph!( UndirectedGraph, MapGraphPoint, RoadLine )
{
    RoadGraph.PolylineDescriptor[] findPath( NodeDescr from_node, NodeDescr to_node ) const
    {
        alias PathFinder!( RoadGraph ) PF;
        
        auto path = PF.findPath( this, from_node, to_node );
        
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
        
        res ~= getNodePayload( descr.node );
        
        auto edge = getEdge( descr );
        
        if( edge.forward_direction )
            foreach( c; edge.payload.polyline.points )
                res ~= c;
        else
            foreach_reverse( c; edge.payload.polyline.points )
                res ~= c;
        
        res ~= getNodePayload( edge.to_node );
        
        return res;
    }
}

unittest
{
    auto t = new RoadGraph;
}
