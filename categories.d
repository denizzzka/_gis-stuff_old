
enum Point
{
    OTHER,
    SHOP,
    LEISURE,
    POLICE,
    UNSUPPORTED
}

enum Line
{
    OTHER, // just line
    
    // other
    BUILDING,
    BOUNDARY,
    
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
