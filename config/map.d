module config.map;

import dsfml.graphics: Color;
static import categories;

import std.json;
import std.file: readText;


struct PolylineProperties
{
    Color color;
    size_t[] layers;
}

class Polylines
{
    immutable string[] members = [ __traits( allMembers, categories.Line ) ];
    
    private static PolylineProperties[ members.length ] properties;
    
    ref PolylineProperties getProperty( in categories.Line enum_type ) const
    {
        return properties[ enum_type ];
    }
    
    static this()
    {
        import std.stdio;
        writeln( members );
        writeln( typeid( members ) );
        
        PolylineProperties rp;
        
        // OTHER
        rp = PolylineProperties(
                Color( 0x00, 0xAA, 0xAA ),
                [ 0 ]
            );
        properties[0] = rp;
        
        // BUILDING
        rp = PolylineProperties(
                Color( 0xf7, 0xc3, 0x94 ),
                [ 0 ]
            );
        properties[1] = rp;
        
        // BOUNDARY
        rp = PolylineProperties(
                Color( 0xAA, 0xAA, 0x00 ),
                [ 0, 1, 2, 3, 4 ]
            );
        properties[2] = rp;
        
        // PATH
        rp = PolylineProperties(
                Color.Magenta,
                [ 0, 1, 2, 3, 4 ]
            );
        properties[3] = rp;
        
        // HIGHWAY
        rp = PolylineProperties(
                Color.Green,
                [ 0, 1, 2, 3, 4 ]
            );
        properties[4] = rp;
        
        // PRIMARY
        rp = PolylineProperties(
                Color.White,
                [ 0, 1, 2, 3 ]
            );
        properties[5] = rp;
        
        // SECONDARY
        rp = PolylineProperties(
                Color.Yellow,
                [ 0, 1, 2 ]
            );
        properties[6] = rp;
        
        // ROAD_OTHER
        rp = PolylineProperties(
                Color( 0xAA, 0xAA, 0xAA ),
                [ 0, 1 ]
            );
        properties[7] = rp;
        
        // UNSUPPORTED
        rp = PolylineProperties(
                Color.Cyan,
                [ 0, 1 ]
            );
        properties[8] = rp;
    }
    
    this( string filename )
    {
        string file_content = readText( filename );
        JSONValue json = parseJSON( file_content );
        
        auto map = json.object["Map"];
        
        foreach( ref lineName; members )
        {
            auto s = map.object[ lineName ].object["color"];
        }
    }
};

const Polylines polylines;

static this()
{
    polylines = new Polylines("config/map.json");
}
