module compression.delta;


class DeltaEncoded( T )
{
    T[] encoded;
    
    void opOpAssign( string op )( T v )
    if( op == "~" )
    {
        if( !encoded )
            encoded ~= v;
        else
        {
            for( auto i = 0; i < encoded.length; i++ )
                v -= encoded[i];
            
            encoded ~= v;
        }
    }
    
    T opIndex( inout size_t idx )
    in
    {
        assert( idx >= 0 );
        assert( idx < encoded.length );
    }
    body
    {
        T res = encoded[0];
        
        for( auto i = 1; i <= idx; i++ )
            res += encoded[i];
        
        return res;
    }
}

unittest
{
    alias DeltaEncoded!float D;
    
    D d = new D;
    
    d ~= 1.0f;
    d ~= 2.0f;
    d ~= 3.0f;
    
    assert( d[0] == 1 );
    assert( d[1] == 2 );
    assert( d[2] == 3 );
}
