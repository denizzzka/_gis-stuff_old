module config.map;

import sfml: Color;


struct RoadProperties
{
    Color color;
    size_t[] layers;
}

struct Roads
{
    RoadProperties HIGHWAY = {
            color: Color.Green,
            layers: [ 4 ]
        };
    
    RoadProperties PRIMARY = {
            color: Color.White,
            layers: [ 2 ]
        };
    
    RoadProperties SECONDARY = {
            color: Color.Yellow,
            layers: [ 1 ]
        };
    
    RoadProperties OTHER = {
            color: Color( 0xAA, 0xAA, 0xAA ),
            layers: [ 0 ]
        };
    
    RoadProperties UNSUPPORTED = {
            color: Color.Magenta,
            layers: [ 0, 1, 2, 3, 4 ]
        };
}
