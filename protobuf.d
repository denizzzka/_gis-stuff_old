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


pure ulong parseVarint( const (ubyte)* data )
{
    size_t i = 0;
    const (ubyte)* old;
    ulong res;
    
    do {
        assert( i < data.sizeof, "Varint is too big for type " ~ data.stringof );
        
        res |= ( *data & 0b_01111111 ) << 7 * i;
        old = data;
        data++;
        i++;
    } while( msbIsSet(old) );
    
    return res;
}
unittest
{
    ubyte d[2] = [ 0b_10101100, 0b_00000010 ];
    assert( parseVarint( &d[0] ) == 300 );
}


pure void parseTagAndWiretype( const (ubyte)* data, out size_t tag, out WireType wireType )
{
    wireType = cast( WireType ) ( *data & 0b_00000111 );
    tag = parseVarint( data );
    
    
    /*
    size_t i = 0;
    const (ubyte)* old;
    ulong res;
    
    do {
        assert( i < data.sizeof, "Varint is too big for type " ~ data.stringof );
        
        res |= ( *data & 0x7f ) << 7 * i;
        old = data;
        data++;
        i++;
    } while( msbIsSet(old) );
    */
}
unittest
{
    ubyte d[2] = [ 0b_10101100, 0b_00000010 ];
    size_t tag;
    WireType wire;
    parseTagAndWiretype( &d[0], tag, wire );
    
    writeln( "tag: ", tag, " wire: ", wire );
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
