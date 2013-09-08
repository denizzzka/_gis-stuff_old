module config.map;

import dsfml.graphics: Color;
static import cat = config.categories;

import std.json;
import std.file: readText;
import std.conv: to;


struct PolylineProperties
{
    Color color = Color.Cyan;
    Color outlineColor = Color.Magenta;
    float thickness = 1.0;
    float outlineThickness = 1.0;
    size_t[] layers = [ 1, 2, 3, 4, 5 ];
}

class Polylines
{
    immutable string[] members = [ __traits( allMembers, cat.Line ) ];
    
    private static PolylineProperties[ members.length ] properties;
    
    ref PolylineProperties getProperty( in cat.Line enum_type ) const
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
            
            auto prop = &properties[ member_idx ];
            
            prop.color = getColor( lineObj["color"] );
            prop.outlineColor = getColor( lineObj["outlineColor"] );
            prop.thickness = lineObj["thickness"].floating;
            prop.outlineThickness = lineObj["outlineThickness"].floating;
            prop.layers = getSize_tArray( lineObj["layers"] );
        }
    }
};

Color getColor( JSONValue color_vals )
{
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
