module config.map;

import dsfml.graphics: Color;
static import categories;

import std.json;


struct RoadProperties
{
    Color color;
    size_t[] layers;
}

class Roads
{
    immutable string[] members = [ __traits( allMembers, categories.Road ) ];
    
    private static RoadProperties[ members.length ] roads_properties;
    
    ref RoadProperties getProperty( in categories.Road enum_type ) const
    {
        return roads_properties[ enum_type ];
    }
    
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
        roads_properties[0] = rp;
        
        rp = RoadProperties(
                Color.White,
                [ 2 ]
            );
        roads_properties[1] = rp;
        
        rp = RoadProperties(
                Color.Yellow,
                [ 1 ]
            );
        roads_properties[2] = rp;
        
        rp = RoadProperties(
                Color( 0xAA, 0xAA, 0xAA ),
                [ 0 ]
            );
        roads_properties[3] = rp;
        
        rp = RoadProperties(
                Color.Magenta,
                [ 0, 1, 2, 3, 4 ]
            );
        roads_properties[4] = rp;
    }
    
    this( string filename )
    {
    }
};

static const Roads roads = new Roads("asd");
