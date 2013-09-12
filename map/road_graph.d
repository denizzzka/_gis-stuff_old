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
    EdgeDescr[] findPath( NodeDescr from_node, NodeDescr to_node ) const
    {
        /*
        alias PathFinder!( RoadGraph ) PF;
        
        auto path = PF.findPath( this, from_node, to_node );
        
        debug(path) writeln("path from=", from_node, " to=", to_node);
        */
        RoadGraph.EdgeDescr[] res;
        /*
        if( path != null )
            for( auto i = 1; i < path.length; i++ )
                res ~= path[i-1].came_through_edge;
        */
        return res;
    }
    
    override
    MapCoords[] getMapCoords( in EdgeDescr descr ) const
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
    
    real calcSphericalLength( in EdgeDescr descr ) const
    {
        auto coords = getMapCoords( descr );
        
        assert( coords.length > 0 );
        
        auto prev = coords[0];
        real res = 0;
        
        for( auto i = 1; i < coords.length; i++ )
        {
            res += prev.calcSphericalDistance( coords[i] );
            prev = coords[i];
        }
        
        return res;
    }
}

unittest
{
    auto t = new RoadGraph;
}
