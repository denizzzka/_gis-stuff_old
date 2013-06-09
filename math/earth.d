import math.geometry;
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
    
    static T coords2mercator( T )( T coords )
    {
        T r;
        
        r.lon = lon2mercator( coords.lon );
        r.lat = lat2mercator( coords.lat );
        
        return r;
    }
    
    static auto orthodromicDistance( Coords )( Coords from, Coords to )
    {
        auto immutable radius = ( 2 * Datum.a + Datum.b ) / 3; // approximation
        
        alias from s; // standpoint
        alias to f; // forepoint
        
        auto dLamb = degree2radian( f.lon - s.lon );
        
        auto cos_phi_f = cos(f.lat);
        auto sin_phi_f = sin(f.lat);
        auto cos_phi_s = cos(s.lat);
        auto sin_phi_s = sin(s.lat);
        auto cos_dLamb = cos(dLamb);
        
        auto e1 = cos_phi_f * sin(dLamb);
        auto e2 = cos_phi_s * sin_phi_f - sin_phi_s * cos_phi_f * cos_dLamb;
        auto dividend =  hypot( e1, e2 );
        auto divider = sin_phi_s * sin_phi_f + cos_phi_s * cos_phi_f * cos_dLamb;
        
        auto angle = atan2( dividend, divider );
        
        return radius * angle;
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
    
    // distance between Krasnoyarsk airport and Moscow Domodedovo airport
    auto krsk = Vector2D!double( 56.171667, 92.493333 );
    auto msk = Vector2D!double( 55.408611, 37.906111 );
    
    auto t1 = Vector2D!double( 92.8618363, 56.0339152 );
    auto t2 = Vector2D!double( 92.8618363, 56.0322406 );
    
    //auto t1 = Vector2D!double( 92.8650337, 56.0322406 );
    //auto t2 = Vector2D!double( 92.8617626, 56.0322406 );
    
    import std.stdio;
    writefln( "orthodromic=%f", C.orthodromicDistance( t1, t2 ) );
    
    auto f = C.coords2mercator( t1 );
    auto t = C.coords2mercator( t2 );
    writeln( t1, t2 );
    writeln( f, t );
    f -= t;
    
    writefln( "mercator=%f", f.length() );
}
