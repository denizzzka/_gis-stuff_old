module protobuf.statical;

import protobuf.runtime;


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
