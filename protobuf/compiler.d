module protobuf.compiler;

import protobuf.runtime;

import std.array;
import std.regex;
import std.exception;
import std.string;
import std.typecons;
import std.typetuple;
import std.mmfile;
debug(protobuf) import std.stdio;


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

string recognizeStatement( string statementText, StatementParser[string] parsers )
{
    auto s = getFirstWord( statementText );
    
    if( s.word !in parsers )
        return "// Unexpected \""~s.word~"\"\n";
    
    return parsers[s.word] ( s.remain );
}


struct Parser
{
    static immutable string[string] DType; /// conversion of types
    static this()
    {
        DType["string"] = "string";
        DType["int32"] = "int";
        DType["sint32"] = "int";
        DType["uint32"] = "uint";
    }
    
    struct Dcode
    {
        string structure; /// will be added to D's struct {...}
        string flags; /// boolean flags for fields fill checking
        string methods; /// text of functions for access to the struct fields
    }
    
    static Dcode Field( string rule )( string statementContent )
    {
        Dcode res;
        
        // adding type to struct
        auto w = getFirstWord( statementContent );
        res.structure ~= DType[w.word];
        
        // adding field name
        w = getFirstWord( w.remain );
        res.structure ~= DType[w.word];
        
        // here is should be a '='
        w = getFirstWord( w.remain );
        assert( w.word == "=" );
        
        // get a field number
        w = getFirstWord( w.remain );
        res.methods ~= "field number is "~w.word;
        
        // TODO: here can be a [] options why also need parser
        
        // fill flags (actually it will be a additional checking methods)
        res.flags ~= rule;
        
        return res;
    }
    
    
    static string Message( string statementContent )
    {
        StatementParser[string] Parsers;
        /*
        Parsers["required"] = &Parser.Field!"required";
        Parsers["optional"] = &Parser.Field!"optional";
        Parsers["repeated"] = &Parser.Field!"repeated";
        */
        
        string res;

        auto m = getFirstWord( statementContent );

        res ~= "struct " ~ m.word ~ " {\n";
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


alias removeTopLevelBrackets!('{','}') removeTopLevelBraces;


string removeTopLevelBrackets(char LEFT, char RIGHT)( string s )
{
    string res;

    foreach( size_t i, char first; s )
    {
        if( first == LEFT )
        {
            for( size_t j = s.length-1; j > i; j-- )
                if( s[j] == RIGHT )
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
    assert( removeTopLevelBrackets!('{', '}')( "a { s { d } f } g" ) == "a  s { d } f  g" );
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


unittest
{
    string example = import( "example.proto" );
    
    // remove comments
    example = replace( example, regex( "//.*", "gm" ), "" );
    debug(protobuf) writeln( example );

    // load file
    MmFile mmfile = new MmFile( "book.bin" );
    ubyte[] f = cast( ubyte[] ) mmfile[0..mmfile.length];

    // begin parsing
    StatementParser[string] parsers;
    //parsers["message"] = &Parser.Message;
    auto res = parseBlock( example, parsers );

    debug(protobuf) writeln( "Total:\n", res );

    // test reading
    AddressBook msg;
    
    //msg.fillStruct( &msg.fillField );
    
    debug(protobuf) writeln( msg );
}



struct AddressBook
{
    Person[] person;
}

struct Person
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
    
    struct Internal
    {
        struct IsSet
        {
            bool name;
        }
    }
    
    Internal.IsSet is_set;
            
private:
    
    size_t fillDelimited( T, string fieldName )( const (ubyte)* curr, uint fieldNum, WireType wire )
    {
        enforce( wire == WireType.LENGTH_DELIMITED );
        size_t next;
        mixin( fieldName~" = unpackDelimited!T( curr, next );" );
        mixin( "is_set."~fieldName~" = true;" );
        return next;
    }
    
    const (ubyte)* fillField( const (ubyte)* curr, uint fieldNum, WireType wire )
    {
        size_t next;
        
        switch( fieldNum )
        {
            case 1:
                writeln( wire );
                next = fillDelimited!(char, "name")( curr, fieldNum, wire );
                break;
                
            default:
                break;
        }

        return curr + next;
    }
}
