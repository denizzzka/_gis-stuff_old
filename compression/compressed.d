module compression.compressed;


class CompressedArray( T, size_t keyInterval )
{
    private ubyte[] storage;
    debug private size_t items_num;
    
    private
    static size_t findKeyIdx( in size_t valIdx )
    {
        return valIdx / keyInterval;
    }
    
    void opOpAssign( string op )( T v )
    if( op == "~" )
    {
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
        ubyte* curr = &storage[0];
        T res;
        
        for( auto i = 0; i <= idx; i++ )
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
    
    assert( c[0] == Val( 0.0f ) );
    assert( c[1] == Val( 1.0f ) );
    assert( c[2] == Val( 2.0f ) );
    assert( c[3] == Val( 3.0f ) );
}

/*
class FramedCompressedArray( T, size_t keyInterval )
{
    private ubyte[] compressed_storage;
    private size_t[] keys_indexes;
    
    private
    size_t findKeyIdx( in size_t valIdx )
    {
        return valIdx / keyInterval;
    }
    
    void opOpAssign( string op )( T v )
    if( op == "~" )
    {
        auto keyIdx = findKeyIdx( compressed_storage.length );
        
        if( keyIdx >= keys_indexes.length ) // add new index?
            keys_indexes ~= compressed_storage.length;
        
        compressed_storage ~= v.compressed;
    }
    
    T opIndex( inout size_t idx )
    {
        auto key_idx = findKeyIdx( idx );
        
        size_t from_byte_idx = keys_indexes[ key_idx ];
        
        size_t i = key_idx;
        T res;
        ubyte* curr = compressed_storage[ curr_byte_idx ];
        do
        {
            curr_byte = res.decompress( curr_byte );
        }
        while( i != idx );
        
        for( auto i = start_idx; i < start_idx + keyInterval
        
        ubyte[] to_decompress = compressed[i*4 .. i*4 + 4];
        
        T res;
        res.decompress( to_decompress );
        
        return res;
    }
}
*/
