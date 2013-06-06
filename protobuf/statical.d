module protobuf.statical;

import protobuf.runtime;

import std.exception;
debug(protobuf) import std.stdio;


struct FillArgs
{
    const (ubyte)* curr;
    uint fieldNum;
    WireType wire;
}


alias void delegate( ref FillArgs ) FillOneField;


void fillStruct( const ubyte[] msg, FillOneField fof )
{
    FillArgs a;
    a.curr = &msg[0];
    
    while( a.curr <= &msg[$-1] )
    {
        a.curr += parseTag( a.curr, a.fieldNum, a.wire );
        fof( a );
    }
}


T fillDelimited( T )( ref FillArgs a )
{
    enforce( a.wire == WireType.LENGTH_DELIMITED );
    
    size_t next;
    
    T res;
    alias typeof( res[0] ) I;
    
    res = unpackDelimited!I( a.curr, next );
    a.curr += next;
    
    return res;
}
