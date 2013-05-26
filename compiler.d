module compiler;

import protobuf;
import std.array;
import std.regex;
import std.exception;
import std.string;
import std.typecons;
import std.typetuple;
import std.mmfile;


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


struct Word
{
    string word;
    string remain;
}


Word getFirstWord( string statementText )
{
    auto s = match( statementText, regex( r"\w+" ) );

    Word ret;

    if( !s.empty )
    {
        auto c = s.captures;
        ret.word = toLower( s.front.hit );
        ret.remain = c.post;
    }

    return ret;
}


alias string function( string ) StatementParser;


string recognizeStatement( string statementText, StatementParser[string] parsers = null )
{
    auto s = getFirstWord( statementText );

    //enforce( ( s.word in parsers ) != null, "Unexpected \""~s.word~"\"" );

    if( ( s.word in parsers ) == null )
        return "// Unexpected \""~s.word~"\"\n";

    return parsers[s.word] ( s.remain );
}


struct Parser
{
    static string Package( string statementContent )
    {
        return "//FIXME adding package \"" ~ removeEndDelimiter( statementContent ) ~ "\"\n";
    }


    static string Option( string statementContent )
    {
        return "//FIXME option found \"" ~ removeEndDelimiter( statementContent ) ~ "\"\n";
    }


    static string Required( string statementContent )
    {
        auto w = getFirstWord( statementContent );

        /*
        switch( w.word )
        {
            case "int32":
                Tuple!(
            ( "int32", int ),
            ( "uint32", uint ),
            ( "int64", long ),
            ( "uint64", ulong )
        ) Scalars;
        */

        return "//FIXME required found \"" ~ removeEndDelimiter( statementContent ) ~ "\"\n";
    }


    static string Optional( string statementContent )
    {
        return "//FIXME optional found \"" ~ removeEndDelimiter( statementContent ) ~ "\"\n";
    }


    static string Repeated( string statementContent )
    {
        return "//FIXME repeated found \"" ~ removeEndDelimiter( statementContent ) ~ "\"\n";
    }


    static string Message( string statementContent )
    {
        StatementParser[string] Parsers;

        Parsers["package"] = &Parser.Package;
        Parsers["message"] = &Parser.Message;
        Parsers["option"] = &Parser.Option;
        Parsers["required"] = &Parser.Required;
        Parsers["optional"] = &Parser.Optional;
        Parsers["repeated"] = &Parser.Repeated;
        Parsers["enum"] = &Parser.Enum;

        string res;

        auto m = getFirstWord( statementContent );

        res ~= "Message " ~ m.word ~ " {\n";
        res ~= parseBlock( removeTopLevelBraces( m.remain ), Parsers );
        res ~= "} // message " ~ m.word ~ " end\n";

        return res;
    }


    static string Enum( string statementContent )
    {
        string res;

        auto m = getFirstWord( statementContent );

        res ~= "//FIXME Enum " ~ m.word ~ " {";
        res ~= removeTopLevelBraces( m.remain );
        res ~= "} // enum " ~ m.word ~ " end\n";

        return res;
    }
}


string removeEndDelimiter( string s )
{
    return replace( s, regex( ";$", "m" ), "" );
}


string removeTopLevelBraces( string s )
{
    string res;

    foreach( size_t i, char first; s )
    {
        if( first == '{' )
        {
            for( size_t j = s.length-1; j > i; j-- )
                if( s[j] == '}' )
                {
                    // remove found pair of braces
                    res = s[0 .. i] ~ s[i+1 .. j] ~ s[j+1 .. $];

                    break;
                }

            break;
        }
    }

    return res;
}
unittest
{
    assert( removeTopLevelBraces( "a { s { d } f } g" ) == "a  s { d } f  g" );
}


string parseBlock( string block, StatementParser[string] parsers )
{
    size_t next; // next statement start position
    string statement; // statement text
    string res;

    while( next < block.length )
    {
        next += statement.length;
        statement = searchFirstStatementText( block[ next..$ ] );

        if( statement != "" )
            res ~= recognizeStatement( statement, parsers );
        else
            break;
    }

    return res;
}


void main()
{
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

    // remove comments
    example = replace( example, regex( "//.*", "gm" ), "" );
    writeln( example );

    // load file
    MmFile mmfile = new MmFile( "book.bin" );
    ubyte[] f = cast( ubyte[] ) mmfile[0..mmfile.length];

    // begin parsing
    StatementParser[string] parsers;
    parsers["message"] = &Parser.Message;
    auto res = parseBlock( example, parsers );

    writeln( "Total:\n", res );

    // test reading
    AddressBook msg;
    
    msg.fillStruct( f );
    
    /*
    auto f1 = parseTag( &f[2], field, wire );
    msg.name = unpackDelimited!char( f1, f1 );

    f1 = parseTag( f1, field, wire );
    msg.id = unpackVarint!uint( f1, f1 );

    f1 = parseTag( f1, field, wire );
    msg.email = unpackDelimited!char( f1, f1 );
    */
    
    writeln( msg );
}

struct AddressBook
{
    char[] name;
    uint id;
    char[] email; // optional

    enum PhoneType : uint
    {
        MOBILE = 0,
        HOME = 1,
        WORK = 2
    };

    struct PhoneNumber
    {
        char[] number;
        PhoneType type = PhoneType.HOME; // optional [default = HOME]
    };

    PhoneNumber[] phone; // repeated
    
    
    void fillStruct( const ubyte[] messageData )
    {
        const (ubyte)* next = &messageData[0];
        
        // unpackMessage:
        uint field; WireType wire;
        next = parseTag( next, field, wire );
        enforce( wire.LENGTH_DELIMITED, "Wrong wire type" );
        auto msg = unpackDelimited!ubyte( next, next );
        next -= msg.length;
        
        while( next < &messageData[$-1] )
            next = fillField( next );
    }
    
    private const (ubyte)* fillField( const ubyte* data )
    {
        WireType wire;
        uint field;
        auto next = parseTag( data, field, wire );

        switch( field )
        {
            case 1:
                enforce( wire == WireType.LENGTH_DELIMITED, "Wrong wire type" );
                name = unpackDelimited!char( next, next );
                break;
                
            case 2:
                enforce( wire == WireType.VARINT, "Wrong wire type" );
                id = unpackVarint!uint( next, next );
                break;
                
            case 3:
                enforce( wire == WireType.LENGTH_DELIMITED, "Wrong wire type" );
                email = unpackDelimited!char( next, next );
                break;
                
            case 4:
                enforce( wire == WireType.LENGTH_DELIMITED, "Wrong wire type" );
                unpackDelimited!ubyte( next, next );
                break;
                
            default:
                break;
        }
        
        return next;
    }
}


enum Rule
{
    REQUIRED,
    OPTIONAL,
    REPEATED
}

enum FillType
{
    REPLACE,
    CONCATENATE,
    MERGE
};

struct RuleProperties
{
    Rule rule;
    FillType fill;
    bool necessarilyFill;
}

immutable RuleProperties[] RulesProperties =
[
    { rule: Rule.REQUIRED, fill: FillType.REPLACE, necessarilyFill: true },
    { rule: Rule.OPTIONAL, fill: FillType.REPLACE, necessarilyFill: false },
    { rule: Rule.REPEATED, fill: FillType.CONCATENATE, necessarilyFill: false }
];

