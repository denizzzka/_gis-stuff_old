// Protocol Buffer encoding/decoding functions

module protobuf.runtime;

import std.exception;
import std.traits;
debug(protobuf) import std.stdio;

enum WireType : ubyte {
    VARINT           = 0,
    FIXED64          = 1,
    LENGTH_DELIMITED = 2,
    START_GROUP      = 3, /// deprecated
    END_GROUP        = 4, /// deprecated
    FIXED32          = 5
};


pure bool msbIsSet( const ubyte* a )
{
    import core.bitop: bt;
    
    return bt( cast(size_t*) a, 7 ) != 0;
}
unittest
{
    ubyte t_neg = 0b_00000000;
    ubyte t_pos = 0b_10000000;
    assert( msbIsSet( &t_neg ) == false );
    assert( msbIsSet( &t_pos ) == true );
}


void msbSet( ubyte* a )
{
    import core.bitop: bts;
    
    enforce( !bts( cast(size_t*) a, 7 ), "MSB is already set" );
}
unittest
{
    ubyte t_neg = 0b_00000000;
    ubyte t_pos = 0b_10000000;
    msbSet( &t_neg );
    
    assert( t_neg == t_pos );
}


pure size_t getVarintSize( const ubyte* data )
{
    size_t i = 0;
    while( msbIsSet( data + i ) ) i++;
    return i + 1;
}
unittest
{
    ubyte d[3] = [ 0b_10101100, 0b_10101100, 0b_00000010 ];
    
    assert( getVarintSize( &d[0] ) == 3 );
}


pure size_t unpackVarint( T )( in ubyte* data, out T result )
if( isUnsigned!( T ) )
{
    size_t i;
    size_t res; // big sized type used also for overflow checking
    
    do {
        res |= ( data[i] & 0b_0111_1111 ) << 7 * i;
        enforce( res <= T.max, "Varint is too big for type " ~ T.stringof );
    } while( msbIsSet( &data[i++] ) );
    
    result = cast(T) res;
    
    return i;
}
unittest
{
    ubyte d[2] = [ 0b_10101100, 0b_00000010 ];
    size_t result;
    
    assert( unpackVarint( &d[0], result ) == d.length );
    assert( result == 300 );
}


pure ubyte[] packVarint( T )( T value )
if( isUnsigned!( T ) )
{
    ubyte[] res;
    
    while( value >= 0b_1000_0000 )
    {
        res ~= cast( ubyte )( value | 0b_1000_0000 );
        value >>= 7;
    }
    
    res ~= cast( ubyte ) value;
    
    return res;
}
unittest
{
    auto v = packVarint!ulong( 300 );
    assert( v.length == 2 );
    assert( v == [ 0b_10101100, 0b_00000010 ] );
}


pure size_t parseTag( in ubyte* data, out uint fieldNumber, out WireType wireType )
{
    wireType = cast( WireType ) ( *data & 0b_0000_0111 );
    
    uint v;
    auto next = unpackVarint( data, v );
    
    // Parses as Varint, but takes the value of first byte and adds its real value without additional load
    fieldNumber = v - ( *data & 0b_1111_1111 ) + (( *data & 0b_0111_1000 ) >> 3 );
    
    return next;
}
unittest
{
    ubyte d[3] = [ 0b_0000_1000, 0b_1001_0110, 0b_0000_0001 ];
    uint field;
    WireType wire;
    auto res = parseTag( &d[0], field, wire );
    
    assert( field == 1 );
    assert( wire == WireType.VARINT );
    assert( res == 1 );
}


pure auto decodeZigZag( T )( in T v )
if( isUnsigned!( T ) )
{
    Signed!( T ) res = ( v & 1 )
        ?
            -( v >> 1 ) - 1
        :
            v >> 1;

    return res;
}
unittest
{
    assert( decodeZigZag!ulong( 4294967294 ) == 2147483647 );
    assert( decodeZigZag!ulong( 4294967295 ) == -2147483648 );
}


Unsigned!T encodeZigZag( T )( inout T v ) pure
if( isSigned!( T ) )
{
    return cast( Unsigned!T )(
            v > 0 ?
            v * 2 :
            -v * 2 - 1
        );
}
unittest
{
    assert( encodeZigZag!long( 2147483647 ) == 4294967294 );
    assert( encodeZigZag!long( -2147483648 ) == 4294967295 );
    
    assert( encodeZigZag!short( 20 ) == 40 );
    assert( encodeZigZag!short( -20 ) == 39 );
}


T[] unpackDelimited( T )( const ubyte* data, out size_t next )
if( T.sizeof == 1 )
{
    // find start and size of string
    size_t str_len;
    next = unpackVarint( data, str_len );
    auto end = next + str_len;
    auto res = cast( T[] ) data[ next .. end ];
    next = end;
    return res;
}
unittest
{
    ubyte[8] d = [ 0x07, 0x74, 0x65, 0x73, 0x74, 0x69, 0x6e, 0x67 ];
    size_t next;
    
    assert( unpackDelimited!char( &d[0], next ) == "testing" );
    assert( next == 8 );
}


const (ubyte)[] unpackMessage( const ubyte* data, out size_t next )
{
    auto size = unpackVarint!size_t( data, next );
    return unpackDelimited!ubyte( data+next, next );
}
