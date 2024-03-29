module compression.geometry;

import math.geometry;
import std.traits;
import compression.pb_encoding: packVarint, unpackVarint;


ubyte[] compress(T)( inout T vector )
if( isInstanceOf!(Vector2D, T) )
out( arr )
{
    T d;
    size_t size = d.decompress( &arr[0] );
    
    assert( size == arr.length );
    assert( d == vector );
}
body
{
    ubyte[] res = packVarint( vector.x );
    res ~= packVarint( vector.y );
    
    return res;
}

size_t decompress(T)( out T vector, inout ubyte* from )
if( isInstanceOf!(Vector2D, T) )
{
    size_t offset = vector.x.unpackVarint( from );
    offset += vector.y.unpackVarint( from + offset );
    
    return offset;
}

ubyte[] compress(T)( inout T box )
if( isInstanceOf!(Box, T) )
out( arr )
{
    T d;
    size_t size = d.decompress( &arr[0] );
    
    assert( size == arr.length );
    assert( d == box );
}
body
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
    
    auto v1 = Vector2l( -3, 2 );
    auto v2 = Vector2l( 3, 3 );
    BBox b1;
    b1.leftDownCorner = v1;
    b1.rightUpperCorner = v2;
    
    auto b_compressed = b1.compress;
    
    BBox b2;
    size_t offset_b = b2.decompress( &b_compressed[0] );
    
    assert( offset_b == b_compressed.length );
    
    assert( b2 == b1 );
}
