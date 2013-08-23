module config.map;

import dsfml.graphics: Color;
import categories;


struct RoadProperties
{
    Color color;
    size_t[] layers;
}

class Roads
{
    static RoadProperties[] roads_properties;
    
    immutable string[] members = [ __traits( allMembers, categories.Road ) ];
    
    static this()
    {
        import std.stdio;
        writeln( members );
        writeln( typeid( members ) );
        
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
    
    this( string filename )
    {
    }
};

static const Roads roads = new Roads("asd");
