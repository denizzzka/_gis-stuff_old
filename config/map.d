module config.map;

import dsfml.graphics: Color;
static import categories;

import std.json;
import std.file: readText;
import std.conv: to;


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
        
        foreach( member_idx, ref lineName; members )
        {
            auto lineObj = map.object[ lineName ];
            
            auto property = &properties[ member_idx ];
            
            property.color = getColor( lineObj );
            property.layers = getSize_tArray( lineObj["layers"] );
        }
    }
};

Color getColor( JSONValue v )
{
    auto color_vals = v.object["color"];
    
    ubyte colorChan( string name )
    {
        return to!ubyte( color_vals["R"].uinteger );
    }
    
    return Color( colorChan("R"), colorChan("G"), colorChan("B") );
}

size_t[] getSize_tArray( JSONValue v )
{
    size_t[] res;
    
    foreach( ref c; v.array )
        res ~= to!uint( c.integer );
        
    return res;
}

const Polylines polylines;

static this()
{
    polylines = new Polylines("config/map.json");
}
