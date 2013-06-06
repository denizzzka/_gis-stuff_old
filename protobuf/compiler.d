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
        ret.word = s.front.hit;
        ret.remain = c.post;
    }

    return ret;
}
unittest
{
    assert( getFirstWord( " abc = def " ).word == "abc" );
}


string addIndents( string v )
{
    string insert( string v, size_t place )
    {
        return v[0..place]~"    "~v[place..$];
    }
    
    v = chomp( v );
    v = insert( v, 0 );
    
    foreach_reverse( i, c; v )
        if( c == '\n' )
            v = insert( v, i+1 );
    
    return v;
}
unittest
{
    auto s = addIndents("abc\ndef\n");
    assert( s == "    abc\n    def" );
}


struct Dcode
{
    string structure; /// will be added to D's struct {...}
    string flags; /// boolean flags for fields fill checking
    string methods; /// text of functions for access to the struct fields
    
    void opOpAssign( string op )( in Dcode v )
    if( op == "~" )
    {
        structure ~= v.structure;
        flags ~= v.flags;
        methods ~= v.methods;
    }
}

alias Dcode function( string ) StatementParser;

Dcode recognizeStatement( string statementText, StatementParser[string] parsers )
{
    auto s = getFirstWord( statementText );
    Dcode res;
    
    if( toLower( s.word ) !in parsers )
        res.structure = "// Unexpected word \""~s.word~"\"\n";
    else
        res = parsers[s.word] ( s.remain );
        
    return res;
}


struct Parser
{
    static immutable string[string] DType; /// conversion of protobuf types to D
    static this()
    {
        DType["string"] = "string";
        DType["int32"] = "int";
        DType["sint32"] = "int";
        DType["uint32"] = "uint";
    }
    
    static Dcode Field( string rule )( string statementContent )
    {
        Dcode res;
        
        // type of variable
        auto w = getFirstWord( statementContent );
        auto type = DType[w.word];
        
        // variable name
        w = getFirstWord( w.remain );
        auto name = w.word;
        
        // here is should be a '='
        // TODO: disabled, need to fix getFirstWord()
        //w = getFirstWord( w.remain );
        //enforce( w.word == "=" );
        
        // field number
        w = getFirstWord( w.remain );
        auto field_num = w.word;
        
        static if( rule == "required" )
            res.flags ~= "// \""~name~"\" field is required";
        else static if( rule == "optional" )
            res.flags ~= "// \""~name~"\" this field is optional";
        else static if( rule == "repeated" )
            res.flags ~= "// \""~name~"\" this field is repeated";
        else
            static assert( false );
        
        res.structure = format( "%s %s;\n", type, name );
        
        return res;
    }
    
    
    static Dcode Message( string statementContent )
    {
        StatementParser[string] Parsers;
        Parsers["required"] = &Parser.Field!"required";
        Parsers["optional"] = &Parser.Field!"optional";
        Parsers["repeated"] = &Parser.Field!"repeated";
        
        Dcode res;

        auto m = getFirstWord( statementContent );

        res.structure ~= "struct " ~ m.word ~ "\n{\n";
        auto inner = parseBlock( removeTopLevelBraces( m.remain ), Parsers );
        inner.structure = addIndents( inner.structure );
        res ~= inner;
        res.structure ~= "\n}\n";
        
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


Dcode parseBlock( string block, StatementParser[string] parsers )
{
    size_t next; // next statement start position
    string statement; // statement text
    Dcode res;

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
    parsers["message"] = &Parser.Message;
    auto res = parseBlock( example, parsers );

    debug(protobuf)
        writefln( "Total:\n\n%s\n%s\n%s\n", res.structure, res.flags, res.methods );

    // test reading
    Simple msg;
    
    fillStruct( f, &msg.fillField );
    
    debug(protobuf) writeln( msg );
}


struct Simple
{
    string name;

    void fillField( ref FillArgs a )
    {
        size_t next;
        
        switch( a.fieldNum )
        {
            case 1:
                writeln( a.wire );
                name = unpackDelimited!char( a.curr, next );
                break;
                
            default:
                break;
        }

        a.curr += next;
    }
}
