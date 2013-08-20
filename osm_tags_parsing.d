import osmpbf.osmformat: StringTable, Node, Way;
import categories;

import std.conv: to;
import std.algorithm: canFind;


enum WayType
{
    OTHER,
    BUILDING,
    ROAD
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

@disable
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

Line getLineType( in StringTable stringtable, in Way way )
{
    auto tags = stringtable.getTags( way );
    
    foreach( t; tags )
    {
        auto tag_type = examWayTag( tags, t );
        
        if( tag_type != Line.UNSUPPORTED )
            return tag_type;
    }
    
    return Line.UNSUPPORTED;
}

Line examWayTag( Tag[] tags, Tag tag )
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

WayType getWayType( Tag[] tags )
{
    with( WayType )
    {
        foreach( t; tags )
            switch( t.key )
            {
                case "highway":
                    return ROAD;
                    break;
                    
                case "building":
                    return BUILDING;
                    break;
                    
                default:
                    continue;
            }
        
        return OTHER;
    }
}
