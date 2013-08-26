import osmpbf.osmformat: StringTable, Node;
import osm: DecodedLine, Coords;
import categories;

import std.conv: to;
import std.algorithm: canFind;


enum LineClass
{
    AREA,
    POLYLINE,
    ROAD,
    UNKNOWN
}

string getStringByIndex( in StringTable stringtable, in uint index )
{
    char[] res;
    
    if( !stringtable.s.isNull )
        res = cast( char[] ) stringtable.s[index];
        
    return to!string( res );
}

struct Tag
{
    string key;
    string value;

    string toString() const
    {
        return key~"="~value;
    }
}

Tag getTag( in StringTable stringtable, in uint key, in uint value )
{
    return Tag(
            getStringByIndex( stringtable, key ),
            getStringByIndex( stringtable, value )
        );
}

string toString( in Tag[] from )
{
    string res;
    
    foreach( c; from )
        res ~= c.toString()~"\n";
        
    return res;
}

Tag[] getTagsByArray( in StringTable stringtable, in uint[] keys, in uint[] values )
in
{
    assert( keys.length == values.length );
}
body
{
    Tag[] res;
    
    foreach( i, c; keys )
        res ~= stringtable.getTag( keys[i], values[i] );
            
    return res;
}

Tag[] getTags(T)( in StringTable stringtable, in T obj )
if( is( T == Node ) || is( T == Way ) )
{
    if( !obj.keys.isNull && obj.keys.length > 0 )
        return stringtable.getTagsByArray( obj.keys, obj.vals );
    else
        return null;
}

Tag[] searchTags( in Tag[] tags, in string[] keys )
{
    Tag[] res;
    
    foreach( t; tags )
        if( canFind( keys, t.key ) )
            res ~= t;
            
    return res;
}

Point getPointType( in StringTable stringtable, in Node node )
{
    auto tags = stringtable.getTags( node );
    
    foreach( t; tags )
    {
        auto tag_type = examNodeTag( tags, t );
        
        if( tag_type != Point.UNSUPPORTED )
            return tag_type;
    }
    
    return Point.UNSUPPORTED;
}

Point examNodeTag( Tag[] tags, Tag tag )
{
    auto t = tag;
    
    with( Point )
    {
        switch( t.key )
        {
            case "amenity":
                if( t.value == "shop" )
                    return SHOP;
                break;
                
            case "leisure":
                return LEISURE;
                break;
                
            default:
                return UNSUPPORTED;
        }
        
        return UNSUPPORTED;
    }
}

Line getLineType( in StringTable stringtable, in DecodedLine line )
{
    foreach( t; line.tags )
    {
        auto tag_type = examWayTag( line.tags, t );
        
        if( tag_type != Line.UNSUPPORTED )
            return tag_type;
    }
    
    return Line.UNSUPPORTED;
}

Line examWayTag( in Tag[] tags, in Tag tag )
{
    with( Line )
    {
        switch( tag.key )
        {
            case "highway":
                if( canFind( ["trunk", "motorway"], tag.value ) )
                    return ROAD_HIGHWAY;
                
                if( canFind( ["primary", "tertiary"], tag.value ) )
                    return ROAD_PRIMARY;
                
                if( canFind( ["secondary"], tag.value ) )
                    return ROAD_SECONDARY;
                
                return ROAD_OTHER;
                break;
                
            case "building":
                return BUILDING;
                break;
                
            default:
                return UNSUPPORTED;
        }
        
        return UNSUPPORTED;
    }
}

LineClass classifyLine( in Coords[] coords, in Tag[] tags )
in
{
    assert( coords.length >= 2 );
}
body
{
    with( LineClass )
    {
        foreach( t; tags )
            if( t.key == "highway" )
                return ROAD;
        
        if( coords[0] == coords[$-1] )
            return AREA;
        else
            return POLYLINE;
    }
}

Line getRoadType( in Tag[] tags )
out( res )
{
    assert( canFind( roads, res ) );
}
body
{
    auto s = searchTags( tags, [ "highway" ] );
    auto tag = s[0];
    
    with( Line )
    {
        if( canFind( ["trunk", "motorway"], tag.value ) )
            return HIGHWAY;
        
        if( canFind( ["primary", "tertiary"], tag.value ) )
            return PRIMARY;
        
        if( canFind( ["secondary"], tag.value ) )
            return SECONDARY;
        
        return OTHER;
    }
}
