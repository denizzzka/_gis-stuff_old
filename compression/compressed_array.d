module compression.compressed_array;

static import pbf = pbf.compressed_array;


class CompressedArray( T, size_t keyInterval )
{
    private pbf.Compressed_Array ca;
    alias ca this;
    
    this()
    {
        items_num = 0;
        
        ubyte[] zero_length;
        storage = zero_length;
        
        uint[] zero_length_size_t;
        keys_indexes = zero_length_size_t;
    }
    
    static CompressedArray Deserialize( inout ref ubyte[] from )
    {
        auto f = cast(ubyte[]) from;
        
        auto res = new CompressedArray;
        res.ca = pbf.Compressed_Array.Deserialize(f);
        
        return res;
    }
    
    private static size_t findKeyIdx( inout size_t valIdx )
    {
        return valIdx / keyInterval;
    }
    
    void opOpAssign( string op )( T v )
    if( op == "~" )
    {
        auto keyIdx = findKeyIdx( items_num );
        
        if( keyIdx >= keys_indexes.length ) // need new key?
            keys_indexes ~= storage.length;
            
        storage ~= v.compress;
        items_num++;
    }
    
    T opIndex( inout size_t idx ) const
    in
    {
        assert( idx < ca.items_num );
    }
    body
    {
        const size_t key_idx = findKeyIdx( idx );
        size_t offset = keys_indexes[ key_idx ];
        T res;
        
        for( auto i = key_idx * keyInterval; i <= idx; i++ )
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
    c ~= Val( 8.0f );
    c ~= Val( 9.0f );
    c ~= Val( 10.0f );
    c ~= Val( 11.0f );
    c ~= Val( 12.0f );
    c ~= Val( 13.0f );
    
    auto bytes = c.Serialize;
    
    auto d = C.Deserialize( bytes );
    
    assert( d[0] == Val( 0.0f ) );
    assert( d[1] == Val( 1.0f ) );
    assert( d[2] == Val( 2.0f ) );
    assert( d[3] == Val( 3.0f ) );
    assert( d[4] == Val( 4.0f ) );
    assert( d[5] == Val( 5.0f ) );
    assert( d[6] == Val( 6.0f ) );
    assert( d[7] == Val( 7.0f ) );
    assert( d[8] == Val( 8.0f ) );
    assert( d[9] == Val( 9.0f ) );
    assert( d[10] == Val( 10.0f ) );
    assert( d[11] == Val( 11.0f ) );
    assert( d[12] == Val( 12.0f ) );
    assert( d[13] == Val( 13.0f ) );
}
