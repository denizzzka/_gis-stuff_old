module compiler;

import protobuf;
import std.array;
import std.regex;
import std.exception;
import std.string;

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


string searchFirstStatementText( string code )
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


string Operators[] =
[
    "package",
    "message",
    "option"
];


struct Statement
{
    string name;
    string content;
}


Statement parseStatement( string statementText )
{    
    auto s = match( statementText, regex( r"\w+" ) );
    
    Statement ret;
    
    if( !s.empty )
    {
        auto c = s.captures;
        ret.name = toLower( s.front.hit );
        ret.content = c.post;
    }
    
    return ret;
}


string recognizeStatement( string statementText )
{
    alias string function( string ) StatementParser;
    StatementParser[string] Parsers;
    
    Parsers["package"] = &Parser.Package;
    Parsers["message"] = &Parser.Message;
    Parsers["option"] = &Parser.Option;
    
    
    auto s = parseStatement( statementText );
    
    writeln( "Statement found: ", s.name );
    
    enforce( ( s.name in Parsers ) != null, "Parser for \""~s.name~"\" is not found" );
    return Parsers[s.name] ( s.content );
}


struct Parser
{
    static string Package( string statementContent )
    {
        return "adding package \"" ~ removeEndDelimiter( statementContent ) ~ "\"\n";
    }


    static string Option( string statementContent )
    {
        return "option found \"" ~ removeEndDelimiter( statementContent ) ~ "\"\n";
    }


    static string Message( string statementContent )
    {
        string res;
        
        // trick: using this for get message name
        auto m = parseStatement( statementContent );
        res ~= "Message " ~ m.name ~ " {\n";
        
        res ~= parseBlock( m.content );
    //    auto s = parseStatement
    //    res.parent = parent;
    
        res ~= "}\n";
        
        return res;
    }
}


string removeEndDelimiter( string s )
{
    return replace( s, regex( ";$", "m" ), "" );
}


string parseBlock( string block )
{
    // remove comments
    block = replace( block, regex( "//.*", "gm" ), "" );
    
    size_t next; // next statement start position
    string statement; // statement text
    string res;
    
    for( auto i = 0; i < example.length; i++ )
    {
        next += statement.length;
        statement = searchFirstStatementText( block[ next..$ ] );
        
        if( statement != "" )
            res ~= recognizeStatement( statement );
    }
    
    return res;
}


void main()
{
    // remove comments
    example = replace( example, regex( "//.*", "gm" ), "" );
    //writeln( example );
    
    auto res = parseBlock( example );
    
    writeln( "Total: ", res );
}
