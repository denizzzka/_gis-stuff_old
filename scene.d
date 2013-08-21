module scene;

import map;
import math.geometry;
import osm: Coords, metersToEncoded, encodedToMeters;
import math.earth: Conv, WGS84, lon2canonical;
import map: Point, Line, RGraph;

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
    
    Coords[] found_path;
    
    private
    {
        Vector2r center; /// in meters
        real zoom; /// pixels per meter
        Box!Vector2r boundary_meters; /// coords in meters
        Box!Coords boundary_encoded; /// coords in map encoding
    }
    
    void updatePath()
    {
        auto g = &map.regions[0].road_graph;
        
        auto found_path = g.findPath( g.getRandomNodeIdx, g.getRandomNodeIdx );
        
        debug(scene) writeln( "New path: ", found_path );
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
    void calcBoundary(T)( T window )
    {
        Vector2r b_size; b_size = window.getWindowSize();
        b_size /= zoom;
        
        auto leftDownCorner = center - b_size/2;
        
        boundary_meters = Box!Vector2r( leftDownCorner, b_size );            
        boundary_encoded = getEncodedBox( boundary_meters ).roundCircumscribe;
    }
    
    Vector2r metersToScreen( Vector2r from ) const
    {
        auto ld = boundary_meters.leftDownCorner;
        auto ld_relative = from - ld;
        auto window_coords = ld_relative * zoom;
        
        return window_coords;
    }
    
    Point*[] getPOIs() const
    {
        Point*[] res;
        
        foreach( region; map.regions )
        {
            void addLayer( size_t num )
            {
                res ~= region.layers[ num ].POI.search( boundary_encoded );
            }
            
            addLayer( 4 );
            
            if( zoom > 0.015 ) addLayer( 3 );
            if( zoom > 0.03 ) addLayer( 2 );
            if( zoom > 0.15 )  addLayer( 1 );
            if( zoom > 0.3 )  addLayer( 0 );
        }
        
        debug(scene) writeln("found POI number=", res.length);
        return res;
    }
    
    Line*[] getLines() const
    {
        Line*[] res;
        
        foreach( region; map.regions )
        {
            void addLayer( size_t num )
            {
                res ~= region.layers[ num ].lines.search( boundary_encoded );
            }
            
            addLayer( 4 );
            
            if( zoom > 0.015 ) addLayer( 3 );
            if( zoom > 0.03 ) addLayer( 2 );
            if( zoom > 0.15 )  addLayer( 1 );
            if( zoom > 0.3 )  addLayer( 0 );
        }
        
        debug(scene) writeln("found ways number=", res.length);
        return res;
    }
    
    RGraph.Roads[] getRoads() const
    {
        RGraph.Roads[] res;
        
        foreach( ref region; map.regions )
        {
            auto curr = RGraph.Roads( region.road_graph );
            
            void addLayer( size_t num )
            {
                curr.descriptors ~= region.layers[ num ].roads.search( boundary_encoded );
            }
            
            addLayer( 4 );
            
            if( zoom > 0.015 ) addLayer( 3 );
            if( zoom > 0.03 ) addLayer( 2 );
            if( zoom > 0.15 )  addLayer( 1 );
            if( zoom > 0.3 )  addLayer( 0 );
            
            res ~= curr;
        }
        
        debug(scene) writeln("found roads number=", res.length);
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
