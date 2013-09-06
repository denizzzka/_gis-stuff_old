module scene;

import map.map;
import map.map: RGraph; // FIXME: remove duplicate import map.map
import math.geometry;
import math.earth: Conv, WGS84, lon2canonical;
import map.roads: findPath;
import config.viewer;

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
    
    RGraph.PolylineDescriptor[] found_path;
    
    private
    {
        Vector2r center; /// in meters
        real zoom; /// pixels per meter
        Box!Coords boundary_meters;
    }
    
    void updatePath()
    {
        auto g = map.regions[0].layers[0].road_graph;
        
        do
            found_path = g.findPath( g.getRandomNodeIdx, g.getRandomNodeIdx );
        while( found_path.length == 0 );
        
        debug(scene) writeln( "New path: ", found_path );
    }
    
    void setCenter( in Vector2r new_center )
    {
        alias Conv!WGS84 C;
        
        center.lat = new_center.lat;
        
        // passing 180 meridian
        auto radian_lon = C.mercator2lon( new_center.lon );
        radian_lon = lon2canonical( radian_lon );
        
        center.lon = C.lon2mercator( radian_lon );
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
        
        boundary_meters = Box!Coords( leftDownCorner.roundToDouble, b_size.roundToDouble );            
    }
    
    Vector2r metersToScreen( Vector2r from ) const
    {
        auto ld = boundary_meters.leftDownCorner;
        auto ld_relative = from - ld;
        auto window_coords = ld_relative * zoom;
        
        return window_coords;
    }
    
    private
    size_t getCurrentLayerNum() const
    {
        size_t layer_num = layersZoom.length;
        
        foreach( i, curr_zoom; layersZoom )
            if( zoom > curr_zoom )
            {
                layer_num = i;
                break;
            }
        
        return layer_num;
    }
    
    Point*[] getPOIs() const
    {
        Point*[] res;
        
        foreach( region; map.regions )
        {
            auto num = getCurrentLayerNum();
            
            res ~= region.layers[ num ].POI.search( boundary_meters );
        }
        
        debug(scene) writeln("found POI number=", res.length);
        return res;
    }
    
    MapLinesDescriptor[] getLines() const
    {
        return map.getLines( getCurrentLayerNum, boundary_meters );
    }
    
    RGraph.Polylines[] getPathLines()
    {
        debug(scene) writeln("path=", found_path);
        
        RGraph.Polylines[] res;
        
        auto curr = RGraph.Polylines( map.regions[ 0 ].layers[ 0 ].road_graph ); // FIXME
            
        foreach( ref c; found_path )
            curr.descriptors ~= &c;
        
        res ~= curr;
        
        return res;
    }
    
	override string toString()
    {
        return format("center=%s zoom=%g scene mbox=%s size_len=%g", center, zoom, boundary_meters, boundary_meters.getSizeVector.length);	
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
