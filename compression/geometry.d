module compression.geometry2;

import math.geometry;
import std.traits;
import protobuf.runtime: packVarint, unpackVarint, encodeZigZag, decodeZigZag;


ubyte[] compress(T)( inout T value )
if( isIntegral!T )
{
    static if( isUnsigned!T )
        return packVarint( value );
    else
        return packVarint( encodeZigZag( value ) );
}

size_t decompress(T)( out T value, inout ubyte* from )
if( isIntegral!T )
{
    static if( isUnsigned!T )
        return unpackVarint( from, value );
    else
    {
        Unsigned!T uval;
        size_t res = unpackVarint( from, uval );
        value = decodeZigZag( uval );
        
        return res;
    }
}

unittest
{
    auto c = compress!long( -2 );
    
    long d;
    size_t offset = d.decompress( &c[0] );
    
    assert( offset == c.length );
    assert( d == -2 );
}

ubyte[] compress(T)( inout T vector )
if( isInstanceOf!(Vector2D, T) )
{
    ubyte[] res = compress( vector.x );
    res ~= compress( vector.y );
    
    return res;
}

size_t decompress(T)( out T vector, inout ubyte* from )
if( isInstanceOf!(Vector2D, T) )
{
    size_t offset = vector.x.decompress( from );
    offset += vector.y.decompress( from + offset );
    
    return offset;
}

ubyte[] compress(T)( inout T box )
if( isInstanceOf!(Box, T) )
{
    ubyte[] res = box.leftDownCorner.compress;
    res ~= box.rightUpperCorner.compress;
    
    return res;
}

size_t decompress(T)( out T box, inout ubyte* from )
if( isInstanceOf!(Box, T) )
{
    size_t offset = box.leftDownCorner.decompress( from );
    offset += box.rightUpperCorner.decompress( from + offset );
    
    return offset;
}

unittest
{
    alias Vector2D!long Vector2l;
    
    auto v = Vector2l( -1, 2 );
    auto v_compressed = v.compress;
    
    Vector2l d;
    size_t offset_v = d.decompress( &v_compressed[0] );
    
    assert( offset_v == v_compressed.length );
    assert( d == v );
    
    alias Box!Vector2l BBox;
    
    auto v1 = Vector2l( -3, -3 );
    auto v2 = Vector2l( 3, 3 );
    BBox b1;
    b1.leftDownCorner = v1;
    b1.rightUpperCorner = v2;
    
    auto b_compressed = b1.compress;
    
    BBox b2;
    size_t offset_b = b2.decompress( &b_compressed[0] );
    
    assert( offset_b == b_compressed.length );
    
    import std.stdio;
    writeln( b1, b2 );
    
    assert( b2 == b1 );
}
