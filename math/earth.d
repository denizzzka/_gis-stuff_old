import std.math;


auto degree2radian( T )( T val )
{
    return val * (PI / 180);
}
unittest
{
    assert( degree2radian(0) == 0 );
    assert( degree2radian(45) == PI_4 );
    assert( degree2radian(360) == PI * 2 );
}

struct Conv ( Datum )
{
    static auto lon2mercator( T )( T longitude )
    {
        return Datum.a * degree2radian( longitude );
    }

    static auto lat2mercator( T )( T latitude )
    {
        alias Datum D;
        
        auto  lat = degree2radian( latitude );
        auto e1 = tan( PI_4 + lat/2 );
        auto eccentr = sqrt( 1 - pow((D.b/D.a), 2) );
        auto esinl = eccentr * sin( lat );
        auto e2 = pow( (1.0 - esinl) / (1.0 + esinl), eccentr/2 );
        
        return D.a * log( e1 * e2 );
    }
}

struct WGS84
{
    // Major (transverse) radius at the equator in meters
    static immutable real a = 6378137;
    
    // Inverse flattening
    static immutable inv_flattening = 298.257_223_563;
    
    // Polar semi-minor (conjugate) radius b in meters
    static immutable real b = a * (1.0 - 1.0/inv_flattening);
    unittest
    {
        // Comparison with the value from WGS84 spec
        assert( abs(b - 6356752.314245) < 0.000_001 );
    }
}

unittest
{
    alias Conv!WGS84 C;
    
    // Latitude and longitude of Moscow 
    assert( abs( C.lat2mercator( 55.751667 ) - 7473789.46 ) < 0.01 );
    assert( abs( C.lon2mercator( 37.617778 ) - 4187591.89 ) < 0.01 );
}
