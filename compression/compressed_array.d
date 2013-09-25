module compression.compressed_array;

static import pbf = pbf.compressed_array;


class CompressedArray( T, size_t keyInterval )
{
    pbf.Compressed_Array ca;
    
    private ubyte[] storage;
    private size_t[] keys_indexes;
    private size_t items_num;
    
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
            
        storage ~= v.compress;
        items_num++;
    }
    
    T opIndex( inout size_t idx ) const
    in
    {
        assert( idx < items_num );
    }
    body
    {
        size_t key_idx = findKeyIdx( idx );
        size_t offset = keys_indexes[ key_idx ];
        T res;
        
        for( auto i = key_idx; i <= idx; i++ )
        {
            const ubyte* curr = &storage[ offset ];
            size_t next_offset = res.decompress( curr );
            
            assert( next_offset > 0 );
            
            offset += next_offset;
        }
        
        return res;
    }
    
    size_t length() const
    {
        return items_num;
    }
}

unittest
{
    import std.conv: to;
    
    static struct Val
    {
        float value;
        
        ubyte[] compress() const
        {
            return [ to!ubyte( value ), 66, 77, 88 ];
        }
        
        size_t decompress( inout ubyte* from )
        {
            value = to!float( from[0] );
            
            return 4;
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
