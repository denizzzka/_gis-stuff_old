module scene;

import map;
import math.geometry;
import osm: Coords, metersToEncoded, encodedToMeters;
import math.earth: Conv, WGS84, lon2canonical;
import map: Point, Way;

import std.conv;
import std.string;
import std.math: fmin, fmax;
debug(scene) import std.stdio;


alias Vector2D!real Vector2r;
alias Vector2D!size_t Vector2s;
alias Vector2D!long Vector2l;


class POV
{
    const Map map;
    
    private
    {
        Vector2r center; /// in meters
        real zoom; /// pixels per meter
        Box!Vector2r boundary_meters; /// coords in meters
        //Box!Coords boundary_encoded; /// coords in map encoding
    }
    
    void setCenter( in Vector2r new_center )
    {
        alias Conv!WGS84 C;
        
        auto radian_lon = C.mercator2lon( new_center.x );
        radian_lon = lon2canonical( radian_lon );
        auto mercator_lon = C.lon2mercator( radian_lon );
        
        center.lat = new_center.lat;
        center.lon = mercator_lon;
    }
    
    Vector2r getCenter() const
    {
        return center;
    }
    
    void setZoom( in real new_zoom )
    {
        zoom = new_zoom;
    }
    
    real getZoom() const
    {
        return zoom;
    }
    
    this( in Map m )
    {
        map = m;
    }
    
    private
    auto calcBoundary(T)( T window )
    {
        Vector2r b_size; b_size = window.getWindowSize();
        b_size /= zoom;
        
        auto leftDownCorner = center - b_size/2;
        
        boundary_meters = Box!Vector2r( leftDownCorner, b_size );            
        auto boundary_encoded = getEncodedBox( boundary_meters ).roundCircumscribe;
        
        return boundary_encoded;
    }
    
    private
    Vector2r metersToScreen( Vector2r from )
    {
        auto ld = boundary_meters.leftDownCorner;
        auto ld_relative = from - ld;
        auto window_coords = ld_relative * zoom;
        
        return window_coords;
    }
    
    private
    void drawPOI(T)( T window, in Point[] poi )
    {
        for(auto i = 0; i < poi.length; i++)
        {
            debug(fast) if( i >= 3000 ) break;
            
            Vector2r node = encodedToMeters( poi[i].coords );
            auto window_coords = metersToScreen( node );
            
            debug(scene) writeln("draw point i=", i, " encoded coords=", poi[i], " meters=", node, " window_coords=", window_coords);
            
            window.drawPoint( window_coords );
        }
    }
    
    private
    void drawLines(T)( T window, in Way[] lines )
    {
        foreach( line; lines )
        {
            Vector2r[]  line_points;
            
            foreach( i, node; line.nodes )
            {
                Vector2r point = encodedToMeters( node );
                auto window_coords = metersToScreen( point );
                line_points ~= window_coords;

                debug(scene) writeln("draw way point i=", i, " encoded coords=", point, " meters=", node, " window_coords=", window_coords);
            }
            
            window.drawLine( line_points, line.color );
        }
    }
    
    void draw(T)( T window )
    {
        debug(scene) writeln("Drawing, window size=", window_size);
        
        auto boundary_encoded = calcBoundary( window );
        
        foreach( reg; map.regions )
        {
            auto lines = reg.layer0.ways.search( boundary_encoded );
            debug(scene) writeln("found ways number=", lines.length);
            drawLines( window, lines );
            
            auto poi = reg.layer0.POI.search( boundary_encoded );
            debug(scene) writeln("found POI number=", poi.length);
            drawPOI( window, poi );
        }
    }
    
    Scene getScene(T)( T window ) const
    {
        Scene res;
        
        debug(POV) writeln("Getting Scene");
        
        auto boundary_encoded = calcBoundary( window );
        
        foreach( reg; map.regions )
        {
            res.lines = reg.layer0.ways.search( boundary_encoded );
            debug(POV) writeln("found lines number=", lines.length);
            
            res.pois = reg.layer0.POI.search( boundary_encoded );
            debug(POV) writeln("found POI number=", poi.length);
        }
        
        return res;
    }
    
	override string toString()
    {
        return format("center=%s zoom=%g scene ecenter=%s mbox=%s size_len=%g", center, zoom, center.metersToEncoded, boundary_meters, boundary_meters.getSizeVector.length);	
	}
    
    void zoomToWholeMap(T)( T window_size )
    {
        auto meters_box = getMetersBox( map.boundary );
        auto meters_size = meters_box.getSizeVector;
        
        zoom = fmin(
                window_size.x / meters_size.x,
                window_size.y / meters_size.y
            );
    }
    
    void centerToWholeMap()
    {
        auto map_center = map.boundary.ld + map.boundary.getSizeVector/2;
        center = encodedToMeters( map_center );
    }
}

/// calculates encoded circumscribe box for mercator meters box
Box!Coords getEncodedBox( in Box!Vector2r meters )
{
    Box!Coords res;
    
    res.ld = metersToEncoded( meters.ld );
    res.ru = metersToEncoded( meters.ru );
    auto lu = metersToEncoded( meters.lu );
    auto rd = metersToEncoded( meters.rd );
    
    res.addCircumscribe( lu );
    res.addCircumscribe( rd );
    
    return res;
}

/// calculates mercator meters circumscribe box for encoded box
Box!Vector2r getMetersBox( in Box!Coords encoded )
{
    Box!Vector2r res;
    
    res.ld = encodedToMeters( encoded.ld );
    res.ru = encodedToMeters( encoded.ru );
    auto lu = encodedToMeters( encoded.lu );
    auto rd = encodedToMeters( encoded.rd );
    
    res.addCircumscribe( lu );
    res.addCircumscribe( rd );
    
    return res;
}

struct Scene
{
    Point[] pois;
    Way[] lines;
}
