module scene;

import map;
import math.geometry;
import osm: Coords, metersToEncoded, encodedToMeters;
import math.earth: Conv, WGS84, lon2canonical;

import std.conv;
import std.string;
import std.math: fmin, fmax;
debug(scene) import std.stdio;


alias Vector2D!real Vector2r;
alias Vector2D!size_t Vector2s;
alias Vector2D!long Vector2l;


class Scene
{
    const Map map;
    
    private
    {
        Vector2s window_size; /// in pixels
        Vector2r center; /// in meters
        real zoom; /// pixels per meter
        Box!Vector2r boundary_meters; /// coords in meters
        Box!Coords boundary_encoded; /// coords in map encoding
    }
    
    void setWindowSize(T)( T new_size )
    {
        window_size = new_size;
    }
    
    Vector2s getWindowSize() const
    {
        return window_size;
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
    
    void calcBoundary()
    {
        Vector2r b_size; b_size = window_size;
        b_size /= zoom;
        
        auto leftDownCorner = center - b_size/2;
        
        boundary_meters = Box!Vector2r( leftDownCorner, b_size );            
        boundary_encoded = getEncodedBox( boundary_meters ).roundCircumscribe;
    }
    
    private Vector2r metersToScreen( Vector2r from )
    {
        auto ld = boundary_meters.leftDownCorner;
        auto ld_relative = from - ld;
        auto window_coords = ld_relative * zoom;
        
        return window_coords;
    }
    
    private
    void drawPOI( in Point[] poi, void delegate(Vector2r coords) drawPoint )
    {
        for(auto i = 0; i < poi.length; i++)
        {
            debug(fast) if( i >= 3000 ) break;
            
            Vector2r node = encodedToMeters( poi[i].coords );
            auto window_coords = metersToScreen( node );
            
            debug(scene) writeln("draw point i=", i, " encoded coords=", poi[i], " meters=", node, " window_coords=", window_coords);
            
            drawPoint( window_coords );
        }
    }
    
    private
    void drawLines( in Way[] lines, void delegate(Vector2r[] coords) drawLine )
    {
        foreach( line; lines )
        {
            Vector2r[]  converted_line;
            
            foreach( i, point; line.nodes )
            {
                Vector2r node = encodedToMeters( point );
                auto window_coords = metersToScreen( node );
                converted_line ~= window_coords;

                debug(scene) writeln("draw way point i=", i, " encoded coords=", point, " meters=", node, " window_coords=", window_coords);
            }
            
            drawLine( converted_line );
        }
    }
    
    void draw(
            void delegate(Vector2r coords) drawPoint,
            void delegate(Vector2r[] coords) drawLine
        )
    {
        debug(scene) writeln("Drawing, window size=", window_size);
        
        calcBoundary();
        
        foreach( reg; map.regions )
        {
            auto lines = reg.layer0.ways.search( boundary_encoded );
            debug(scene) writeln("found ways number=", lines.length);
            drawLines( lines, drawLine );
            
            auto poi = reg.layer0.POI.search( boundary_encoded );
            debug(scene) writeln("found POI number=", poi.length);
            drawPOI( poi, drawPoint );
        }
    }
    
	override string toString()
    {
        return format("center=%s zoom=%g scene ecenter=%s ebox=%s mbox=%s size_len=%g", center, zoom, center.metersToEncoded, boundary_encoded, boundary_meters, boundary_meters.getSizeVector.length);	
	}
    
    void zoomToWholeMap()
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
