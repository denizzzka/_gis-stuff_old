module compression.compressed;

class CompressedArray( T, size_t keyInterval )
{
    private ubyte[] compressed;
    
    void opOpAssign( string op )( T v )
    if( op == "~" )
    {
        compressed ~= v.compressed;
    }
    
    T opIndex( inout size_t i )
    {
        ubyte[] to_decompress = compressed[i*4 .. i*4 + 4];
        
        T res;
        res.decompress( to_decompress );
        
        return res;
    }
}

unittest
{
    import std.conv: to;
    
    static struct Val
    {
        float value;
        
        ubyte[] compressed()
        {
            return [ to!ubyte( value ), 66, 77, 88 ];
        }
        
        void decompress( inout ubyte[] from )
        {
            value = to!float( from[0] );
        }
    }
    
    alias CompressedArray!( Val, 3 ) C;
    
    auto c = new C;
    
    c ~= Val( 0.0f );
    c ~= Val( 1.0f );
    
    assert( c[0] == 0 );
}
