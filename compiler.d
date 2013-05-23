module compiler;

import protobuf;
import std.array;
import std.regex;
import std.exception;

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


struct Message
{
    Message* parent;
    Message* nested[];
    
    string content;
}


struct Generated
{
}


string searchFirstStatement( string code )
{
    auto brace_counter = 0;
    
    for( auto i = 0; i < code.length; i++ )
    {
        switch( code[i] )
        {
            case '{':
                brace_counter++;
                break;
                
            case '}':
                brace_counter--;
                enforce( brace_counter >= 0, "syntax error" );
                if( brace_counter == 0 ) return code[ 0..i];
                break;
                
            case ';':
                return code[ 0..i];
                break;
                
            default:
                break;
        }
    }
    
    enforce( false, "Unexpected end of file" );
    return code;
}


void main()
{
    // remove comments
    example = replace( example, regex( "//.*", "gm" ), "" );
    
    
    //auto s = splitter( example, regex( "[ ,;=\n\r]" ) );
    
    writeln( example );
    writeln( searchFirstStatement( example ) );
}
