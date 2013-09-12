// currently this realted only to OSM parser,
// but may be used in other converters

module map.objects_properties;

import map.line_graph: LineProperties;
import map.road_graph: RoadProperties;
import map.area: AreaProperties;


enum LineClass: ubyte
{
    AREA,
    POLYLINE,
    ROAD
}

struct MapObjectProperties
{
    LineClass classification;
    
    union
    {
        LineProperties line;
        RoadProperties road;
        AreaProperties area;
    }
}
