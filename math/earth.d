import std.math;
import std.conv;


real degree2radian( T )( T val )
{
    return val * (PI / 180);
}
unittest
{
    assert( degree2radian(0) == 0 );
    assert( degree2radian(45) == PI_4 );
    assert( degree2radian(360) == PI * 2 );
}

struct WGS84
{
    // major (transverse) radius at the equator in meters
    static immutable real a = 6378137;
    
    //Inverse flattening
    static immutable inv_flattening = 298.257_223_563;
    
    // polar semi-minor (conjugate) radius b in meters
    static immutable real b = a * (1.0 - 1.0/inv_flattening);
    unittest
    {
        // comparison with the value from WGS84 spec
        assert( abs(b - 6356752.314245) < 0.000_001 );
    }
}

real lon2mercatorX( Datum, T )( T longitude )
{
    return Datum.a * longitude;
}

auto lat2mercatorY( Datum, T )( T latitude )
{
    alias Datum D;
    
    auto  lat = degree2radian( latitude );
    auto e1 = tan( PI_4 + lat/2 );
    auto eccentr = sqrt( 1 - pow((D.b/D.a), 2) );
    auto esinl = eccentr * sin( lat );
    auto e2 = pow( (1.0 - esinl) / (1.0 + esinl), eccentr/2 );
    
    return D.a * log( e1 * e2 );
}

unittest
{
    import std.stdio;
    writeln( typeid( WGS84.b ) );
    writeln( WGS84.b );
    
    writeln( lat2mercatorY!WGS84( 55.751667 ) );
}
