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
                enforce( brace_counter >= 0, "Syntax error" );
                // break is not need here
                
            case ';':
                if( brace_counter == 0 ) return code[0..i+1];
                break;
                
            default:
                break;
        }
    }
    
    // statement is not found
    return "";
}


void main()
{
    // remove comments
    example = replace( example, regex( "//.*", "gm" ), "" );
    
    writeln( example );
    
    //auto s = splitter( example, regex( "[ ,;=\n\r]" ) );
    
    size_t next;
    string s;
    
    for( auto i = 0; i< 10; i++ )
    {
        next += s.length;
        s = searchFirstStatement( example[ next..$ ] );
        writeln( "Found: ", s );
    }
}
