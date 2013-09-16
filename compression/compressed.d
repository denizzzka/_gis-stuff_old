module compression.compressed;


class CompressedArray( T, size_t keyInterval )
{
    private ubyte[] storage;
    private size_t[] keys_indexes;
    debug private size_t items_num;
    
    private
    static size_t findKeyIdx( in size_t valIdx )
    {
        return valIdx / keyInterval;
    }
    
    void opOpAssign( string op )( T v )
    if( op == "~" )
    {
        auto keyIdx = findKeyIdx( storage.length );
        
        if( keyIdx >= keys_indexes.length ) // need new key?
            keys_indexes ~= storage.length;
            
        storage ~= v.compressed;
        debug items_num++;
    }
    
    T opIndex( inout size_t idx )
    in
    {
        debug assert( idx < items_num );
    }
    body
    {
        size_t key_idx = findKeyIdx( idx );
        size_t from_byte_idx = keys_indexes[ key_idx ];
        
        ubyte* curr = &storage[ from_byte_idx ];
        T res;
        
        for( auto i = key_idx; i <= idx; i++ )
        {
            debug auto prev_curr = curr;
            
            curr = res.decompress( curr );
            
            debug assert( curr > prev_curr );
        }
        
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
        
        ubyte* decompress( ubyte* from )
        {
            value = to!float( from[0] );
            
            return from + 4;
        }
    }
    
    alias CompressedArray!( Val, 3 ) C;
    
    auto c = new C;
    
    c ~= Val( 0.0f );
    c ~= Val( 1.0f );
    c ~= Val( 2.0f );
    c ~= Val( 3.0f );
    c ~= Val( 4.0f );
    c ~= Val( 5.0f );
    c ~= Val( 6.0f );
    c ~= Val( 7.0f );
    
    assert( c[0] == Val( 0.0f ) );
    assert( c[1] == Val( 1.0f ) );
    assert( c[2] == Val( 2.0f ) );
    assert( c[3] == Val( 3.0f ) );
    assert( c[4] == Val( 4.0f ) );
    assert( c[5] == Val( 5.0f ) );
    assert( c[6] == Val( 6.0f ) );
    assert( c[7] == Val( 7.0f ) );
}
