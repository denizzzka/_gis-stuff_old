module math.earth;

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

auto radian2degree( T )( T val ) pure
{
    return val * (180 / PI);
}
unittest
{
    assert( degree2radian(500).radian2degree == 500 );
}

void assertLongitude( T )( in T longitude ) pure
{
    assert( longitude >= -PI, "Longitude is too small" );
    assert( longitude <= PI, "Longitude is too big" );
}

void assertLatitude( T )( in T latitude ) pure
{
    assert( latitude >= -PI_2, "Latitude is too small" );
    assert( latitude <= PI_2, "Latitude is too big" );
}

struct Coords2D( Datum, Vector2DT )
{
    Vector2DT coords;
    alias coords this;
    
    this( Vector2DT.T x, Vector2DT.T y )
    {
        coords = Vector2DT( x, y );
    }
    
    static Coords2D degrees2radians(T)(T from) pure
    {
        Coords2D res;
        
        res.lat = degree2radian( from.lat );
        res.lon = degree2radian( from.lon );
        
        return res;
    }
    
    static Coords2D coords2mercator(T)(T from) pure
    {
        Coords2D res;
        
        res.lat = Conv!Datum.lat2mercator( from.lat );
        res.lon = Conv!Datum.lon2mercator( from.lon );
        
        return res;
    }
    
    auto getSphericalDistance( Coords )( in Coords to ) const pure
    in
    {
        assertLatitude( lat );
        assertLatitude( to.lat );
        
        assertLongitude( lon );
        assertLongitude( to.lon );
    }
    out( r )
    {
        assert( r >= 0 );
        assert( r <= Datum.approx_radius * PI );
    }
    body
    {
        auto dLamb = to.lon - lon;
        
        auto cos_phi_f = cos(to.lat);
        auto sin_phi_f = sin(to.lat);
        auto cos_phi_s = cos(lat);
        auto sin_phi_s = sin(lat);
        auto cos_dLamb = cos(dLamb);
        
        auto e1 = cos_phi_f * sin(dLamb);
        auto e2 = cos_phi_s * sin_phi_f - sin_phi_s * cos_phi_f * cos_dLamb;
        
        auto dividend = hypot( e1, e2 );
        auto divider = sin_phi_s * sin_phi_f + cos_phi_s * cos_phi_f * cos_dLamb;
        
        auto angle = atan2( dividend, divider );
        
        return Datum.approx_radius * angle;
    }
    
    auto getSphericalAzimuth( Coords )( in Coords to ) const pure
    in
    {
        assertLatitude( lat );
        assertLatitude( to.lat );
        
        assertLongitude( lon );
        assertLongitude( to.lon );
    }
    body
    {
        auto dLamb = to.lon - lon;
        
        auto cos_phi_f = cos(to.lat);
        auto sin_phi_f = sin(to.lat);
        auto cos_phi_s = cos(lat);
        auto sin_phi_s = sin(lat);
        auto cos_dLamb = cos(dLamb);
        
        // (e1 and e2 is same as in getOrthodromicDistance())
        auto e1 = cos_phi_f * sin( dLamb );
        auto e2 = cos_phi_s * sin_phi_f - sin_phi_s * cos_phi_f * cos_dLamb;
        
        return atan2( e1, e2 );
    }
}

struct Conv( Datum )
{
    static auto lon2mercator( T )( in T longitude ) pure
    in
    {
        assertLongitude( longitude );
    }
    body
    {
        return Datum.a * longitude;
    }

    static auto lat2mercator( T )( in T latitude ) pure
    in
    {
        assertLatitude( latitude );
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
    
     // Approximated radius
    static immutable approx_radius = ( 3 * a + b ) / 4;
}

unittest
{
    alias Vector2D!double Vector;
    alias Coords2D!(WGS84, Vector) Coords;
    alias Conv!WGS84 C;
    
    // Latitude and longitude of Moscow
    assert( abs( C.lat2mercator( degree2radian( 55.751667 ) ) - 7473789.46 ) < 0.01 );
    assert( abs( C.lon2mercator( degree2radian( 37.617778 ) ) - 4187591.89 ) < 0.01 );
    
    // Ditto
    auto m = Coords.coords2mercator( Coords.degrees2radians( Coords( 37.617778, 55.751667 ) ) );
    assert( abs( m.lat ) - 7473789.46 < 0.01 );
    assert( abs( m.lon ) - 4187591.89 < 0.01 );
    
    // Distance between Krasnoyarsk airport and Moscow Domodedovo airport
    auto krsk = Coords.degrees2radians( Coords( 92.493333, 56.171667 ) );
    auto msk = Coords.degrees2radians( Coords( 37.906111, 55.408611 ) );
    auto msk_krsk = msk.getSphericalDistance( krsk );
    assert( msk_krsk > 3324352 );
    assert( msk_krsk < 3324354 );
    
    // Small distance
    auto t1 = Coords.degrees2radians( Coords( 92.8650337, 56.0339152 ) );
    auto t2 = Coords.degrees2radians( Coords( 92.8650338, 56.0339153 ) );
    auto t = t1.getSphericalDistance( t2 );
    assert( t > 0.01 );
    assert( t < 0.015 );
    
    // Through North Pole
    auto from = Coords( 0, PI_2 - 0.00001 );
    auto to = Coords( PI, PI_2 - 0.00001 );
    auto pole_dist = from.getSphericalDistance( to );
    assert( pole_dist > 127 );
    assert( pole_dist < 128 );
    
    // Azimuth
    auto az_from = Coords( 0, 0 );
    auto az_to = Coords( -0.1, 0 );
    assert( az_from.getSphericalAzimuth( az_to ) == -PI_2 );
}
