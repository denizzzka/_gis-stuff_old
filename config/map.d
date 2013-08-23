module config.map;

import sfml: Color;


struct RoadProperties
{
    Color color;
}

struct Roads
{
    RoadProperties HIGHWAY = {
            color: Color.Green
        };
    
    RoadProperties PRIMARY = {
            color: Color.White
        };
    
    RoadProperties SECONDARY = {
            color: Color.Yellow
        };
    
    RoadProperties OTHER = {
            color: Color( 0xAA, 0xAA, 0xAA )
        };
    
    RoadProperties UNSUPPORTED = {
            color: Color.Magenta
        };
}
