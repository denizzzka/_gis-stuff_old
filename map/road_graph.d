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

private alias MapGraph!( UndirectedGraph, MapGraphPoint, RoadLine ) MG;

class RoadGraph : PathFinder!MG
{
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
    
    override
    real heuristicDistance( in NodeDescr fromDescr, in NodeDescr toDescr ) const
    {
        auto from = getNodePayload( fromDescr );
        auto to = getNodePayload( toDescr );
        
        return from.calcSphericalDistance( to );
    }
    
    override
    real distance( in EdgeDescr descr ) const
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
    
    void sortEdgesByReducingRank()
    {
        cat.Line getRank( in EdgeDescr edge )
        {
            return getEdge( edge ).payload.type;
        }
        
        sortEdges( &getRank );
    }
}

unittest
{
    auto t = new RoadGraph;
}
