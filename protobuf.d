module protobuf;

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

enum FieldType {
    TYPE_DOUBLE         = 1,
    TYPE_FLOAT          = 2,
    TYPE_INT64          = 3,
    TYPE_UINT64         = 4,
    TYPE_INT32          = 5,
    TYPE_FIXED64        = 6,
    TYPE_FIXED32        = 7,
    TYPE_BOOL           = 8,
    TYPE_STRING         = 9,
    TYPE_GROUP          = 10,
    TYPE_MESSAGE        = 11,
    TYPE_BYTES          = 12,
    TYPE_UINT32         = 13,
    TYPE_ENUM           = 14,
    TYPE_SFIXED32       = 15,
    TYPE_SFIXED64       = 16,
    TYPE_SINT32         = 17,
    TYPE_SINT64         = 18,
    MAX_FIELD_TYPE      = 18,
};


pure bool msbIsSet( const ubyte* a )
{
    import core.bitop: bt;
    
    return bt( cast(ulong*) a, 7 ) != 0;
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
    
    enforce( !bts( cast(ulong*) a, 7 ), "MSB is already set" );
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


pure T unpackVarint( T )( in ubyte* data, out size_t nextElement )
if( isUnsigned!( T ) )
{
    alias nextElement i;
    const (ubyte)* old;
    T res;
    
    do {
        enforce( i < T.sizeof, "Varint is too big for type " ~ T.stringof );
        
        res |= ( data[i] & 0b_01111111 ) << 7 * i;
    } while( msbIsSet( &data[i++] ) );
    
    return res;
}
unittest
{
    ubyte d[2] = [ 0b_10101100, 0b_00000010 ];
    size_t next;
    
    assert( unpackVarint!ulong( &d[0], next ) == 300 );
    assert( next == 2 );
}


pure ubyte[] packVarint( T )( in T value )
if( isUnsigned!( T ) )
{
    
}


pure size_t parseTag( in ubyte* data, out uint fieldNumber, out WireType wireType )
{
    size_t next;
    
    wireType = cast( WireType ) ( *data & 0b_0000_0111 );
    
    // Parses as Varint, but takes the value of first byte and adds its real value without additional load
    fieldNumber = unpackVarint!uint( data, next ) - ( *data & 0b_1111_1111 ) + (( *data & 0b_0111_1000 ) >> 3 );
    
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


pure auto encodeZigZag( T )( in T v )
if( isSigned!( T ) )
{
    Unsigned!( T ) res = ( v > 0 )
        ?
            v * 2
        :
            -v * 2 - 1;
    
    return res;
}
unittest
{
    assert( encodeZigZag!long( 2147483647 ) == 4294967294 );
    assert( encodeZigZag!long( -2147483648 ) == 4294967295 );
}


T[] unpackDelimited( T )( const ubyte* data, out size_t next )
if( T.sizeof == 1 )
{
    // find start and size of string
    auto str_len = unpackVarint!size_t( data, next );
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

/* // waiting answer from protobuf google group
size_t unpackMessageHeader( const ubyte* data, out const (ubyte)* nextElement )
{
    uint field; WireType wire;
    next = parseTag( next, field, wire );
    enforce( wire.LENGTH_DELIMITED, "Wrong wire type" );
    
    return unpackVarint!size_t( data, nextElement );
}
*/
