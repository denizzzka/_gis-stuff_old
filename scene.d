module scene;

import map;
import math.geometry;
import osm: Coords, metersToEncoded, encodedToMeters;
import std.conv;
import std.string;
import std.math: fmin, fmax;
debug(scene) import std.stdio;


alias Vector2D!real Vector2r;
alias Vector2D!size_t Vector2s;
alias Vector2D!long Vector2l;

struct Properties
{
    Vector2r center; /// in meters
    real zoom; /// pixels per meter
    Vector2s windowPixelSize;
}

class Scene
{
    const Map map;
    Properties properties;
    Box!Vector2r boundary_meters; /// coords in meters
    Box!Coords boundary_encoded; /// coords in map encoding
    
    this( in Map m )
    {
        map = m;
    }
    
    void calcBoundary()
    {
        with(properties)
        {
            Vector2r b_size; b_size = windowPixelSize;
            b_size /= zoom;
            
            auto leftDownCorner = center - b_size/2;
            
            boundary_meters = Box!Vector2r( leftDownCorner, b_size );            
            boundary_encoded = getEncodedBox( boundary_meters ).roundCircumscribe;
        }
    }
    
    private
    void drawNodes( in Node[] nodes, void delegate(Vector2D!(real) coords) drawPoint )
    {
        auto len = nodes.length;
        
        for(auto i = 0; i < len; i++)
        {
            debug(fast) if( i >= 3000 ) break;
            
            Vector2r node = encodedToMeters( nodes[i] );
            
            auto ld = boundary_meters.leftDownCorner;
            auto ld_relative = node - ld;
            auto window_coords = ld_relative * properties.zoom;
            
            debug(scene) writeln("draw point i=", i, " encoded coords=", nodes[i], " meters=", node, " window_coords=", window_coords);
            
            drawPoint( window_coords );
        }
    }
    
    void draw( void delegate(Vector2D!(real) coords) drawPoint )
    {
        debug(scene) writeln("Drawing, window size=", properties.windowPixelSize);
        
        calcBoundary();
        
        foreach( reg; map.regions )
        {
            auto nodes = reg.searchNodes( boundary_encoded );
            debug(scene) writeln("found nodes=", nodes.length);
            drawNodes( nodes, drawPoint );
        }
    }
    
	override string toString()
    {
        with(properties)
            return format("center=%s zoom=%g scene bbox=%s size_len=%g", center, zoom, boundary_meters, boundary_meters.getSizeVector.length);	
	}
    
    void zoomToWholeMap()
    {
        auto meters_box = getMetersBox( map.boundary );
        auto meters_size = meters_box.getSizeVector;
        
        properties.zoom = fmin(
                properties.windowPixelSize.x / meters_size.x,
                properties.windowPixelSize.y / meters_size.y
            );
    }
    
    void centerToWholeMap()
    {
        auto map_center = map.boundary.ld + map.boundary.getSizeVector/2;
        properties.center = encodedToMeters( map_center );
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
