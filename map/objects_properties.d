module map.objects_properties;

import map.line_graph: LineProperties;
import map.road_graph: RoadProperties;


enum LineClass: ubyte
{
    AREA,
    POLYLINE,
    ROAD
}

struct MapObjectProperties
{
    LineClass line_class;
    
    LineProperties line;
    RoadProperties road;
}
