import osmpbf.osmformat: StringTable, Node;
import categories;

import std.conv: to;


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

categories.Point getPointType( in StringTable stringtable, in Node node )
{
    categories.Point[ string ] types;
    
    types["building"] = Point.MARKET;
    types["highway"] = Point.MARKET;
    types["boundary"] = Point.MARKET;
    
    auto tags = stringtable.getTags( node );
    /*
    foreach( c; tags )
    {
        auto p = ( "highway" in types );
        
        if( p !is null )
            return *p;
        else
            return Point.UNSUPPORTED;
    }
    */
    
    return Point.UNSUPPORTED;
}
