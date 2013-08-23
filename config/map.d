module config.map;

import dsfml.graphics: Color;
import cat = categories;


struct RoadProperties
{
    Color color;
    size_t[] layers;
}

struct Roads
{
    static RoadProperties[] roads_properties;
    
    static string[] members = [ __traits( allMembers, typeof( this ) ) ];
    
    static this()
    {
        import std.stdio;
        writeln( members );
        
        RoadProperties rp;
        
        rp = RoadProperties(
                Color.Green,
                [ 4 ]
            );
        roads_properties ~= rp;
        
        rp = RoadProperties(
                Color.White,
                [ 2 ]
            );
        roads_properties ~= rp;
        
        rp = RoadProperties(
                Color.Yellow,
                [ 1 ]
            );
        roads_properties ~= rp;
        
        rp = RoadProperties(
                Color( 0xAA, 0xAA, 0xAA ),
                [ 0 ]
            );
        roads_properties ~= rp;
        
        rp = RoadProperties(
                Color.Magenta,
                [ 0, 1, 2, 3, 4 ]
            );
        roads_properties ~= rp;
    }
};

