module map.new_road_graph;

import map.new_map_graph;


struct Point
{
    map.new_map_graph.GraphPoint point;
    
    alias point this;
    
    byte level = 0;
}

class RoadGraph : MapGraph!( Point )
{
}

unittest
{
    auto t = new RoadGraph;
}

