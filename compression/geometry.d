module compression.geometry2;

import math.geometry;


struct CompressBox( Box )
{
    Box box;
    alias box this;
    
    ubyte[] compress() const
    {
        ubyte res[] = (cast (ubyte*) &this) [ 0 .. this.sizeof ];
        return res;
    }
    
    size_t decompress( inout ubyte* storage )
    {
        (cast (ubyte*) &this)[ 0 .. this.sizeof] = storage[ 0 .. this.sizeof ].dup;
        
        return this.sizeof;
    }
}

unittest
{
    alias Vector2D!long Vector2l;
    alias Box!Vector2l OBox;
    alias CompressBox!OBox Box;
    
    //static Box box;
}
