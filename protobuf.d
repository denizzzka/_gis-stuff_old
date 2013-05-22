import std.exception;
import std.stdio;

string example = q"EOS
// See README.txt for information and build instructions.

package tutorial;

option java_package = "com.example.tutorial";
option java_outer_classname = "AddressBookProtos";

message Person {
  required string name = 1;
  required int32 id = 2;        // Unique ID number for this person.
  optional string email = 3;

  enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
  }

  message PhoneNumber {
    required string number = 1;
    optional PhoneType type = 2 [default = HOME];
  }

  repeated PhoneNumber phone = 4;
}

// Our address book file is just one of these.
message AddressBook {
  repeated Person person = 1;
}
EOS";

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


pure size_t getVarintLength( const ubyte* data )
{
    size_t i = 0;
    while( msbIsSet( data + i ) ) i++;
    return i + 1;
}
unittest
{
    ubyte d[3] = [ 0b_10101100, 0b_10101100, 0b_00000010 ];
    
    assert( getVarintLength( &d[0] ) == 3 );
}


pure T parseVarint( T )( const ubyte* data, out const (ubyte)* nextElement )
{
    nextElement = data;
    size_t i = 0;
    const (ubyte)* old;
    T res;
    
    do {
        enforce( i < T.sizeof, "Varint is too big for type " ~ T.stringof );
        
        res |= ( *nextElement & 0b_01111111 ) << 7 * i;
        old = nextElement;
        nextElement++;
        i++;
    } while( msbIsSet( old ) );
    
    return res;
}
unittest
{
    ubyte d[2] = [ 0b_10101100, 0b_00000010 ];
    const (ubyte)* next;
    
    assert( parseVarint!ulong( &d[0], next ) == 300 );
    assert( next == &d[0] + 2 );
}


pure const (ubyte)* parseTagAndWiretype( const ubyte* data, out uint tag, out WireType wireType )
{
    const (ubyte)* nextElement;
    
    wireType = cast( WireType ) ( *data & 0b_0000_0111 );
    
    // Parses as Varint, but takes the value of first byte and adds its real value without additional load
    tag = parseVarint!uint( data, nextElement ) - ( *data & 0b_1111_1111 ) + (( *data & 0b_0111_1000 ) >> 3 );
    
    return nextElement;
}
unittest
{
    ubyte d[3] = [ 0b_0000_1000, 0b_1001_0110, 0b_0000_0001 ];
    uint tag;
    WireType wire;
    auto res = parseTagAndWiretype( &d[0], tag, wire );
    
    assert( tag == 1 );
    assert( wire == WireType.VARINT );
    assert( res == &d[1] );
}


pure long decodeZigZag( ulong v )
{
    if( v & 1 )
        return -( v >> 1 ) - 1;
    else
        return v >> 1;
}
unittest
{
    assert( decodeZigZag( 4294967294 ) == 2147483647 );
    assert( decodeZigZag( 4294967295 ) == -2147483648 );
}


char[] unpackString( const ubyte* data, out const (ubyte)* nextElement )
{
    uint tag;
    WireType wire;
    
    // find string length varint
    nextElement = parseTagAndWiretype( data, tag, wire );
    
    enforce( wire == WireType.LENGTH_DELIMITED, "Wrong wire type for string" );
    
    // find length and start of string bytes
    auto len = parseVarint!ulong( nextElement, nextElement );
    
    return ( cast( char[] ) nextElement[0..len] );
}
unittest
{
    ubyte[9] d = [ 0x12, 0x07, 0x74, 0x65, 0x73, 0x74, 0x69, 0x6e, 0x67 ];
    const (ubyte)* next;
    
    assert( unpackString( &d[0], next ) == "testing" );
}


int Base128Decode( ubyte* a )
{
    
    writeln( *a );
    return a[0];
}
unittest
{
    uint t1 = 0b_00000001;
//    writeln( Base128Decode( &t1 ) );
    
    uint t2[2] = [ 0b_10101100, 0b_00000010 ];
//    writeln( Base128Decode( &t2[0] ) );
}
  
void main()
{
    //writeln( example );
}
