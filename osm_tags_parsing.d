import osmproto;
import osm: DecodedLine, ReadPrimitiveException;
import config.categories;
import map.objects_properties;

import std.conv: to;
import std.algorithm: canFind;
import std.typecons: Nullable;


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

Tag[] searchTags( in Tag[] tags, in string[] keys, in string[] values = null )
{
    Tag[] res;
    
    foreach( t; tags )
        if( canFind( keys, t.key ) )
        {
            if( values is null )
                res ~= t;
            else
                if( canFind( values, t.value ) )
                    res ~= t;
        }
        
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
                
            default:
                return UNSUPPORTED;
        }
        
        return UNSUPPORTED;
    }
}

Nullable!MapObjectProperties parseTags( in Tag[] tags )
{
    MapObjectProperties res;
    
    with( LineClass )
    with( Line )
    {
        if( !tags.getNoneOrOneStringVal( "highway" ).isNull )
        {
            res.classification = ROAD;
            
            auto val = tags.getOneStringVal( "highway" );
            res.road.type = getRoadType( val );
            
            res.road.layer = tags.getZeroOrVal!byte( "layer" );
        }
        
        else if( searchTags( tags, ["admin_level"], ["1", "2", "3", "4"] ) )
        {
            res.classification = POLYLINE;
            
            res.line.type = BOUNDARY;
        }
        
        else if( !tags.getNoneOrOneStringVal( "building" ).isNull )
        {
            res.classification = AREA;
            
            res.line.type = BUILDING;
        }
        else // Object is not recognised
        {
            Nullable!MapObjectProperties null_ret;
            return null_ret;
        }
    }
    
    Nullable!MapObjectProperties r = res;
    return r;
}

Nullable!string getNoneOrOneStringVal( in Tag[] tags, in string key )
{
    auto arr = tags.searchTags( [ key ] );
    
    if( arr.length > 1 )
        throw new ReadPrimitiveException( "Key "~key~" is found many times" );
    
    Nullable!string res;
    
    if( arr.length > 0 )
        res = arr[0].value;
        
    return res;
}

string getOneStringVal( in Tag[] tags, in string key )
{
    auto res = tags.getNoneOrOneStringVal( key );
    
    if( res.isNull )
        throw new ReadPrimitiveException( "Key "~key~" is not found" );
    
    return res;
}

Nullable!T getNoneOrVal( T )( in Tag[] tags, in string key )
{
    auto str = tags.getNoneOrOneStringVal( key );
    
    Nullable!T res;
    
    if( !str.isNull )
    {
        string s = str;
        res = to!T( s );
    }
    
    return res;
}

T getZeroOrVal( T )( in Tag[] tags, in string key )
if( isNumeric(T) )
{
    auto r = tags.getNoneOrVal!( T )( key );
    
    T res = 0;
    
    if( !r.isNull )
        res = r;
        
    return res;
}

Line getRoadType( in string val )
{
    with( Line )
    {
        if( canFind( ["trunk", "motorway"], val ) )
            return HIGHWAY;
        
        if( canFind( ["primary", "tertiary"], val ) )
            return PRIMARY;
        
        if( canFind( ["secondary"], val ) )
            return SECONDARY;
        
        return ROAD_OTHER;
    }
}
