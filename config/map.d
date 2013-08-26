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
    immutable string[] members = [ __traits( allMembers, categories.Line ) ];
    
    private static RoadProperties[ members.length ] roads_properties;
    
    ref RoadProperties getProperty( in categories.Line enum_type ) const
    {
        return roads_properties[ enum_type ];
    }
    
    static this()
    {
        import std.stdio;
        writeln( members );
        writeln( typeid( members ) );
        
        RoadProperties rp;
        
        // OTHER
        rp = RoadProperties(
                Color( 0x00, 0xAA, 0xAA ),
                [ 0 ]
            );
        roads_properties[0] = rp;
        
        // BUILDING
        rp = RoadProperties(
                Color( 0xf7, 0xc3, 0x94 ),
                [ 0 ]
            );
        roads_properties[1] = rp;
        
        // BOUNDARY
        rp = RoadProperties(
                Color( 0xAA, 0xAA, 0x00 ),
                [ 0, 1, 2, 3, 4 ]
            );
        roads_properties[2] = rp;
        
        // PATH
        rp = RoadProperties(
                Color.Yellow,
                [ 0, 1, 2, 3, 4 ]
            );
        roads_properties[3] = rp;
        
        // HIGHWAY
        rp = RoadProperties(
                Color.Green,
                [ 0, 1, 2, 3, 4 ]
            );
        roads_properties[4] = rp;
        
        // PRIMARY
        rp = RoadProperties(
                Color.White,
                [ 0, 1, 2, 3 ]
            );
        roads_properties[5] = rp;
        
        // SECONDARY
        rp = RoadProperties(
                Color.Yellow,
                [ 0, 1, 2 ]
            );
        roads_properties[6] = rp;
        
        // ROAD_OTHER
        rp = RoadProperties(
                Color( 0xAA, 0xAA, 0xAA ),
                [ 0, 1 ]
            );
        roads_properties[7] = rp;
        
        // UNSUPPORTED
        rp = RoadProperties(
                Color.Green,
                [ 0, 1, 2, 3, 4 ]
            );
        roads_properties[8] = rp;
    }
    
    this( string filename )
    {
    }
};

static const Roads roads = new Roads("asd");
