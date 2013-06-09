import math.geometry;
import std.math;


auto degree2radian( T )( T val ) pure
{
    return val * (PI / 180);
}
unittest
{
    assert( degree2radian(0) == 0 );
    assert( degree2radian(45) == PI_4 );
    assert( degree2radian(360) == PI * 2 );
}

struct Coords2D( Vector2DT )
{
    Vector2DT coords;
    alias coords this;
    
    this( X, Y )( X x, Y y )
    {
        this.x = x;
        this.y = y;
    }
    
    Coords2D getRadiansFromDegrees()
    {
        Coords2D res;
        
        res.lat = degree2radian( lat );
        res.lon = degree2radian( lon );
        
        return res;
    }
}

struct Conv( Datum )
{
    static auto lon2mercator( T )( T longitude ) pure
    in
    {
        assert( longitude >= -PI );
        assert( longitude <= PI );
    }
    body
    {
        return Datum.a * longitude;
    }

    static auto lat2mercator( T )( T latitude ) pure
    in
    {
        assert( latitude >= -PI_2 );
        assert( latitude <= PI_2 );
    }
    body
    {
        alias Datum D;
        
        auto e1 = tan( PI_4 + latitude / 2 );
        auto eccentr = sqrt( 1 - pow((D.b/D.a), 2) );
        auto esinl = eccentr * sin( latitude );
        auto e2 = pow( (1.0 - esinl) / (1.0 + esinl), eccentr/2 );
        auto res = D.a * log( e1 * e2 );
        
        return res;
    }
    
    static T coords2mercator( T )( T coords ) pure
    {
        T r;
        
        r.lon = lon2mercator( coords.lon );
        r.lat = lat2mercator( coords.lat );
        
        return r;
    }
    
    static auto orthodromicDistance( Coords )( Coords from, Coords to )
    out( r )
    {
        assert( r >= 0 );
    }
    body
    {
        auto immutable radius = ( 3 * Datum.a + Datum.b ) / 4; // approximation
        
        alias from s; // standpoint
        alias to f; // forepoint
        
        auto dLamb = f.lon - s.lon;
        
        auto cos_phi_f = cos(f.lat);
        auto sin_phi_f = sin(f.lat);
        auto cos_phi_s = cos(s.lat);
        auto sin_phi_s = sin(s.lat);
        auto cos_dLamb = cos(dLamb);
        
        auto e1 = cos_phi_f * sin(dLamb);
        auto e2 = cos_phi_s * sin_phi_f - sin_phi_s * cos_phi_f * cos_dLamb;
        
        auto dividend = hypot( e1, e2 );
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
    alias Vector2D!double Vector;
    alias Coords2D!Vector Coords;
    alias Conv!WGS84 C;
    
    // Latitude and longitude of Moscow
    assert( abs( C.lat2mercator( degree2radian( 55.751667 ) ) - 7473789.46 ) < 0.01 );
    assert( abs( C.lon2mercator( degree2radian( 37.617778 ) ) - 4187591.89 ) < 0.01 );
    
    // Distance between Krasnoyarsk airport and Moscow Domodedovo airport
    auto krsk = Coords( 92.493333, 56.171667 ).getRadiansFromDegrees;
    auto msk = Coords( 37.906111, 55.408611 ).getRadiansFromDegrees;
    auto msk_krsk = C.orthodromicDistance( msk, krsk );
    assert( msk_krsk > 3324352 );
    assert( msk_krsk < 3324354 );
    
    // Small distance
    auto t1 = Coords( 92.8650337, 56.0339152 ).getRadiansFromDegrees;
    auto t2 = Coords( 92.8650338, 56.0339153 ).getRadiansFromDegrees;
    auto t = C.orthodromicDistance( t1, t2 );
    assert( t > 0.01 );
    assert( t < 0.015 );
}
