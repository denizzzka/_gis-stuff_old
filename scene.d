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
alias Vector2D!double Vector2d;
alias Vector2D!size_t Vector2s;
alias Vector2D!long Vector2l;


class POV
{
    const Map map;
    
    RGraph.RoadDescriptor[] found_path;
    
    private
    {
        Vector2r center; /// in meters
        real zoom; /// pixels per meter
        Box!(Vector2d) boundary_meters; /// coords in meters
    }
    
    void updatePath()
    {
        auto g = &map.regions[0].road_graph;
        
        do
            found_path = g.findPath( g.getRandomNodeIdx, g.getRandomNodeIdx );
        while( found_path.length == 0 );
        
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
        
        boundary_meters = Box!Vector2d( leftDownCorner.roundToDouble, b_size.roundToDouble );            
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
                res ~= region.layers[ num ].POI.search( boundary_meters );
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
            immutable double layers_zoom[] = [ 0.3, 0.17, 0.06, 0.02 ];
            assert( region.layers.length == layers_zoom.length +1 );
            
            size_t layer_num = layers_zoom.length;
            
            foreach( i, curr_zoom; layers_zoom )
                if( zoom > curr_zoom )
                {
                    layer_num = i;
                    break;
                }
                
            res ~= region.layers[ layer_num ].lines.search( boundary_meters );
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
                curr.descriptors ~= region.layers[ num ].roads.search( boundary_meters );
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
    
    Line[] getPathLines()
    {
        Line[] res;
        
        debug(scene) writeln("path=", found_path);
        
        foreach( descriptor; found_path )
            res ~= Line(
                    descriptor.getPoints( map.regions[0].road_graph ),
                    cat.Line.PATH, ""
                );
            
        return res;
    }
    
	override string toString()
    {
        return format("center=%s zoom=%g scene ecenter=%s mbox=%s size_len=%g", center, zoom, center.metersToEncoded, boundary_meters, boundary_meters.getSizeVector.length);	
	}
    
    void zoomToWholeMap(T)( T window_size )
    {
        auto meters_size = map.boundary.getSizeVector;
        
        zoom = fmin(
                window_size.x / meters_size.x,
                window_size.y / meters_size.y
            );
    }
    
    void centerToWholeMap()
    {
        center = map.boundary.ld + map.boundary.getSizeVector/2;
    }
}
