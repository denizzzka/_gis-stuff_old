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
}
