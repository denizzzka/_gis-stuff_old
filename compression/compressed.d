module compression.compressed;

class CompressedArray( T, size_t keyInterval )
{
    private ubyte[] compressed;
    
    void opOpAssign( string op )( T v )
    if( op == "~" )
    {
        compressed ~= v.compressed;
    }
}

unittest
{
    import std.conv: to;
    
    alias CompressedArray!( float, 3 ) C;
    
    struct Val
    {
        float value;
        
        ubyte[] compressed()
        {
            return [ to!ubyte( value ), 66, 77, 88 ];
        }
    }
}
