module scene;

import map;
import math.geometry;
import osm: convert2meters;
import std.conv;
import std.string;
debug(scene) import std.stdio;
import dsfml.system: Vector2u; // TODO: need to remove it


alias Vector2D!real Vector2r;
alias Vector2D!size_t Vector2s;
alias Vector2D!long Vector2l;

struct Properties
{
    Vector2r center;
    real zoom;
    Vector2u windowPixelSize;
}

class Scene
{
    const Map map;
    Properties properties;
    
    this( in Map m )
    {
        map = m;
    }
    
    Box!Vector2r getBoundary() const
    {
        with(properties)
        {
            auto b_size = Vector2r(zoom, zoom);
            auto w_size = properties.windowPixelSize;
            
            real ratio = to!real(w_size.x) / w_size.y;
            
            if( ratio > 1 )
                b_size.x *= ratio;
            else
                b_size.y /= ratio;
            
            auto leftDownCorner = center - b_size/2;
            
            return Box!Vector2r( leftDownCorner, b_size );
        }
    }
    
    private
    void drawNodes( in Node[] nodes, void delegate(Vector2D!(real) coords) drawPoint )
    {
        auto len = nodes.length;
        for(auto i = 0; i < 1000 && i < len; i++)
        {
            debug(scene) writeln("draw point i=", i, " coords=", nodes[i]);
            
            //auto coords = convert2meters( nodes[i] );
            Vector2r node; node = nodes[i];
            auto ld = getBoundary.leftDownCorner;
            auto center_relative = node - ld;
            auto window_coords = center_relative * properties.zoom;
            drawPoint( window_coords );
        }
    }
    
    void draw( void delegate(Vector2D!(real) coords) drawPoint )
    {
        debug(scene) writeln("Drawing, window size=", properties.window_size);
        
        auto boundary = getBoundary();
        
        foreach( reg; map.regions )
        {
            auto nodes = reg.searchNodes( boundary );
            drawNodes( nodes, drawPoint );
        }
    }
    
	override string toString()
    {
        with(properties)
            return format("center=%s zoom=%g scene boundary=%s", center, zoom, getBoundary);	
	}
}
