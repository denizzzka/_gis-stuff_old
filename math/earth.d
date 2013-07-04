module math.earth;

import math.geometry;
import std.math;


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
        auto esinl = D.eccentr * sin( latitude );
        auto e2 = pow( (1.0 - esinl) / (1.0 + esinl), D.eccentr/2 );
        auto res = D.a * log( e1 * e2 );
        
        return res;
    }
    
    static auto mercator2lon( T )( in T x ) pure
    out(r)
    {
        assertLongitude( r );
    }
    body
    {
        return x / Datum.a;
    }
    
    static auto mercator2lat( T )( in T y ) pure
    out(r)
    {
        assertLatitude( r );
    }
    body
    {
        alias Datum D;
        
        auto ts = exp( -y / D.a );
        auto phi = PI_2 - 2 * atan(ts);
        real dphi = 1.0;
        auto i = 0;
        while ((abs(dphi) > dphi.min_normal) && (i < 15))
        {
            auto con = D.eccentr * sin(phi);
            dphi = PI_2 - 2 * atan(ts * pow((1.0 - con) / (1.0 + con), D.eccentr/2)) - phi;
            phi += dphi;
            i++;
        }
        
        return phi;
    }
    unittest
    {
        auto rad = degree2radian(56.3);
        auto merc = lat2mercator( rad );
        auto lat = mercator2lat( merc );
        assert( abs(lat-rad) < 0.000_000_000_000_1 );
    }
    
    static auto coords2mercator(T)(T from) pure
    {
        Vector2D!real res;
        
        res.lon = Conv!Datum.lon2mercator( from.lon );
        res.lat = Conv!Datum.lat2mercator( from.lat );
        
        return res;
    }
    
    static auto mercator2coords(T)(T from) pure
    {
        Vector2D!real res;
        
        res.lon = Conv!Datum.mercator2lon( from.lon );
        res.lat = Conv!Datum.mercator2lat( from.lat );
        
        return res;
    }
    
    static auto getSphericalDistance( T1, T2 )( in T1 from, in T2 to ) pure
    in
    {
        assertLatitude( from.lat );
        assertLatitude( to.lat );
        
        assertLongitude( from.lon );
        assertLongitude( to.lon );
    }
    out( r )
    {
        assert( r >= 0 );
        assert( r <= Datum.approx_radius * PI );
    }
    body
    {
        auto dLamb = to.lon - from.lon;
        
        auto cos_phi_f = cos(to.lat);
        auto sin_phi_f = sin(to.lat);
        auto cos_phi_s = cos(from.lat);
        auto sin_phi_s = sin(from.lat);
        auto cos_dLamb = cos(dLamb);
        
        auto e1 = cos_phi_f * sin(dLamb);
        auto e2 = cos_phi_s * sin_phi_f - sin_phi_s * cos_phi_f * cos_dLamb;
        
        auto dividend = hypot( e1, e2 );
        auto divider = sin_phi_s * sin_phi_f + cos_phi_s * cos_phi_f * cos_dLamb;
        
        auto angle = atan2( dividend, divider );
        
        return Datum.approx_radius * angle;
    }
    
    static auto getSphericalAzimuth( T1, T2 )( in T1 from, in T2 to ) pure
    in
    {
        assertLatitude( from.lat );
        assertLatitude( to.lat );
        
        assertLongitude( from.lon );
        assertLongitude( to.lon );
    }
    body
    {
        auto dLamb = to.lon - from.lon;
        
        auto cos_phi_f = cos(to.lat);
        auto sin_phi_f = sin(to.lat);
        auto cos_phi_s = cos(from.lat);
        auto sin_phi_s = sin(from.lat);
        auto cos_dLamb = cos(dLamb);
        
        // (e1 and e2 is same as in getSphericalDistance())
        auto e1 = cos_phi_f * sin( dLamb );
        auto e2 = cos_phi_s * sin_phi_f - sin_phi_s * cos_phi_f * cos_dLamb;
        
        return atan2( e1, e2 );
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
    
    // Eccentricity
    static immutable eccentr = sqrt( 1 - pow(( b/a ), 2) );
}

alias Conv!WGS84 C;
alias C.coords2mercator coords2mercator;
alias C.mercator2coords mercator2coords;
alias C.getSphericalDistance getSphericalDistance;
alias C.getSphericalAzimuth getSphericalAzimuth;

unittest
{
    alias Vector2D!double Vector;
    
    // Latitude and longitude of Moscow
    assert( abs( C.lat2mercator( degree2radian( 55.751667 ) ) - 7473789.46 ) < 0.01 );
    assert( abs( C.lon2mercator( degree2radian( 37.617778 ) ) - 4187591.89 ) < 0.01 );
    
    // Ditto
    auto msk = degrees2radians( Vector( 37.906111, 55.408611 ) );
    auto m = coords2mercator( msk );
    auto diff = mercator2coords( m ) - msk;
    assert( diff.length < 0.000_000_000_000_1 );
    
    // Distance between Krasnoyarsk airport and Moscow Domodedovo airport
    auto krsk = degrees2radians( Vector( 92.493333, 56.171667 ) );
    auto msk_krsk = msk.getSphericalDistance( krsk );
    assert( msk_krsk > 3324352 );
    assert( msk_krsk < 3324354 );
    
    // Small distance
    auto t1 = degrees2radians( Vector( 92.8650337, 56.0339152 ) );
    auto t2 = degrees2radians( Vector( 92.8650338, 56.0339153 ) );
    auto t = t1.getSphericalDistance( t2 );
    assert( t > 0.01 );
    assert( t < 0.015 );
    
    // Through North Pole
    auto from = Vector( 0, PI_2 - 0.00001 );
    auto to = Vector( PI, PI_2 - 0.00001 );
    auto pole_dist = from.getSphericalDistance( to );
    assert( pole_dist > 127 );
    assert( pole_dist < 128 );
    
    // Azimuth
    auto az_from = Vector( 0, 0 );
    auto az_to = Vector( -0.1, 0 );
    assert( az_from.getSphericalAzimuth( az_to ) == -PI_2 );
}
