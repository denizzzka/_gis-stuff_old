module config.categories;


enum LineClass: ubyte
{
    AREA,
    POLYLINE,
    ROAD
}

enum Point : ubyte
{
    OTHER,
    SHOP,
    LEISURE,
    POLICE,
    UNSUPPORTED
}

enum Line : ubyte
{
    OTHER, // just line
    
    // other
    BUILDING,
    BOUNDARY,
    WOOD,
    
    PATH, // path found
    
    // roads
    HIGHWAY,
    PRIMARY,
    SECONDARY,
    ROAD_OTHER,
    
    UNSUPPORTED // unsupported type of line
}

/// lines known as roads
immutable Line[] roads = [
        Line.HIGHWAY,
        Line.PRIMARY,
        Line.SECONDARY,
        Line.ROAD_OTHER
    ];
