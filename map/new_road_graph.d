module map.new_road_graph;

import map.new_map_graph;
import math.graph.undirected;

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

alias UndirectedGraph!( RoadPoint, Polyline ) UG;

/*
class RoadGraph : MapGraph!( UG, RoadPoint )
{
}
*/

alias MapGraph!( UG, RoadPoint ) RoadGraph;

static RoadGraph.Polylines ddd;

unittest
{
    auto t = new RoadGraph;
}
