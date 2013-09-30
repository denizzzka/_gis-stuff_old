module scene;

import map.map;
import map.road_graph;
import math.geometry;
import math.earth: Conv, WGS84, lon2canonical;
import config.viewer;
import render.window: WindowCoords;

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
        MercatorCoords center; /// in meters
        real zoom; /// pixels per meter
        Box!MercatorCoords boundary_meters;
    }
    
    // TODO: need class Path
    const (RoadGraphCompressed.Polylines) found_path()
    {
        return map.found_path;
    }
    
    void updatePath() // TODO: remove it
    {
        auto _map = cast(Map) map;
        _map.updatePath();
    }
    
    void setCenter( in MercatorCoords new_center )
    {
        alias Conv!WGS84 C;
        
        center.lat = new_center.lat;
        
        // passing 180 meridian
        auto radian_lon = C.mercator2lon( new_center.lon );
        radian_lon = lon2canonical( radian_lon );
        
        center.lon = C.lon2mercator( radian_lon );
    }
    
    MercatorCoords getCenter() const
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
        Vector2r w_size = window.getSize();
        MercatorCoords size_vector = w_size / zoom;
        
        auto leftDownCorner = center - size_vector/2;
        
        boundary_meters = Box!MercatorCoords( leftDownCorner, size_vector );            
    }
    
    WindowCoords metersToScreen( in MercatorCoords from ) const
    {
        auto ld = boundary_meters.leftDownCorner;
        auto ld_relative = from - ld;
        WindowCoords window_coords = ld_relative * zoom;
        
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
            
            res ~= region.layers[ num ].POI.search( boundary_meters.toBBox );
        }
        
        debug(scene) writeln("found POI number=", res.length);
        return res;
    }
    
    MapLinesDescriptor[] getLines() const
    {
        return map.getLines( getCurrentLayerNum, boundary_meters.toBBox );
    }
    
	override string toString()
    {
        return format("center=%s zoom=%g scene mbox=%s size_len=%g", center, zoom, boundary_meters, boundary_meters.getSizeVector.length);	
	}
    
    private
    void setZoomToSize(T)( in T window_size, in MercatorCoords size )
    {
        zoom = fmin(
                window_size.x / size.x,
                window_size.y / size.y
            );        
    }
    
    void setPOVtoBoundary(T)( in T window_size, in MBBox boundary )
    {
        auto size_vector = boundary.getSizeVector;
        
        setZoomToSize( window_size, size_vector );
        
        center = boundary.ld + size_vector/2;
    }
}
