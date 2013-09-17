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

size_t decompress(T)( inout ubyte* from, out T value )
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
    size_t offset = decompress( &c[0], d );
    
    assert( offset == c.length );
    assert( d == -2 );
}

ubyte[] compress(T)( inout T vector )
if( isInstanceOf!(Vector2D, T ) )
{
    ubyte[] res = compress( vector.x );
    res ~= compress( vector.y );
    
    return res;
}

size_t decompress(T)( out T vector, inout ubyte* from )
if( isInstanceOf!(Vector2D, T ) )
{
    size_t offset = decompress( from, vector.x );
    offset += decompress( from + offset, vector.y );
    
    return offset;
}

unittest
{
    alias Vector2D!long Vector2l;
    
    auto v = Vector2l( 1, 2 );
    
    auto c = v.compress;
    
    Vector2l d;
    d.decompress( &c[0] );
    
    assert( d == v );
}

struct CompressBox( Box )
{
    Box box;
    alias box this;
    
    ubyte[] compress() const
    {
        ubyte res[] = (cast (ubyte*) &this) [ 0 .. this.sizeof ];
        return res;
    }
    
    size_t decompress( inout ubyte* storage )
    {
        (cast (ubyte*) &this)[ 0 .. this.sizeof] = storage[ 0 .. this.sizeof ].dup;
        
        return this.sizeof;
    }
}

unittest
{
    alias Vector2D!long Vector2l;
    alias Box!Vector2l OBox;
    alias CompressBox!OBox Box;
    
    static Box box;
}
