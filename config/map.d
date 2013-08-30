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
    
    ubyte chan( string name )
    {
        return to!ubyte( color_vals[ name ].uinteger );
    }
    
    return Color( chan("R"), chan("G"), chan("B") );
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
