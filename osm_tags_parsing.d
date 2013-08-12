import osmpbf.osmformat: StringTable, Node;
import categories;

import std.conv: to;
import std.algorithm: canFind;


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

Tag[] getTags( in StringTable stringtable, in uint[] keys, in uint[] values )
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

Tag[] getTags( in StringTable stringtable, in Node node )
{
    if( !node.keys.isNull && node.keys.length > 0 )
        return stringtable.getTags( node.keys, node.vals );
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

categories.Point getPointType( in StringTable stringtable, in Node node )
{
    auto tags = stringtable.getTags( node );
    
    categories.Point[] types;
    
    foreach( t; tags )
    {
        auto tag_type = tags.examPointTag( t );
        
        if( tag_type != Point.UNSUPPORTED )
            return tag_type;
    }
    
    return Point.UNSUPPORTED;
}

categories.Point examPointTag( Tag[] tags, Tag tag )
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
        
        return Point.UNSUPPORTED;
    }
}
