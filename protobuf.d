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

enum WireType {
    WIRETYPE_VARINT           = 0,
    WIRETYPE_FIXED64          = 1,
    WIRETYPE_LENGTH_DELIMITED = 2,
    WIRETYPE_START_GROUP      = 3,
    WIRETYPE_END_GROUP        = 4,
    WIRETYPE_FIXED32          = 5,
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

bool msbIsSet( const ubyte* a )
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


ulong parseVarint( const (ubyte)* data )
{
    size_t i = 0;
    const (ubyte)* old;
    ulong res;
    
    do {
        res |= ( *data & 0x7f ) << 7 * i;
        old = data;
        data++;
        i++;
    } while( msbIsSet(old) );
    
    return res;
}
unittest
{
    ubyte d[2] = [ 0b_10101100, 0b_00000010 ];
    writeln( parseVarint( &d[0] ) );
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
