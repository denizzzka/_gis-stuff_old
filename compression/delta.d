module compression.delta;

import std.math: trunc, lround;
import std.conv: to;


class DeltaEncodedArray( alias Array, T, size_t keyInterval )
{
    alias Array encoded;
    
    private
    static size_t findKey( in size_t idx )
    {
        return idx / keyInterval * keyInterval;
    }
    
    void opOpAssign( string op )( T v )
    if( op == "~" )
    {
        // first element of frame
        if( encoded.length % keyInterval == 0 )
            encoded ~= v;
        else
        {
            auto key = findKey( encoded.length - 1 );
            
            for( auto i = key; i < key+keyInterval && i < encoded.length; i++ )
                v -= encoded[i];
            
            encoded ~= v;
        }
    }
    
    T opIndex( inout size_t idx ) const
    in
    {
        assert( idx < encoded.length );
    }
    body
    {
        auto key = findKey( idx );
        
        T res = encoded[key];
        
        for( auto i = key+1; i <= idx; i++ )
            res += encoded[i];
        
        return res;
    }
    
    size_t length() const
    {
        return encoded.length;
    }
}

unittest
{
    float[] arr;
    alias DeltaEncodedArray!( arr, float, 3 ) D;
    
    D d = new D;
    
    assert( d.findKey( 2 ) == 0 );
    assert( d.findKey( 4 ) == 3 );
    
    d ~= 0.0f;
    d ~= 1.0f;
    d ~= 2.0f;
    d ~= 3.0f;
    d ~= 4.0f;
    d ~= 5.0f;
    d ~= 6.0f;
    d ~= 7.0f;
    
    assert( d[0] == 0 );
    assert( d[1] == 1 );
    assert( d[2] == 2 );
    assert( d[3] == 3 );
    assert( d[4] == 4 );
    assert( d[5] == 5 );
    assert( d[6] == 6 );
    assert( d[7] == 7 );
}
