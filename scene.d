module scene;

import map;
import math.geometry;
import osm: convert2meters;
import std.conv;
import std.string;
debug(scene) import std.stdio;


alias Vector2D!real Vector2r;
alias Vector2D!size_t Vector2s;
alias Vector2D!long Vector2l;

struct Properties
{
    Vector2r center;
    real zoom;
    Vector2s windowPixelSize;
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
            Vector2r b_size;
            auto w_size = windowPixelSize;
            real ratio = to!real(w_size.x) / w_size.y;
            
            b_size.x = zoom * ratio;
            b_size.y = b_size.x / ratio;
            
            auto leftDownCorner = center - b_size/2;
            
            return Box!Vector2r( leftDownCorner, b_size );
        }
    }
    
    private
    void drawNodes( in Node[] nodes, void delegate(Vector2D!(real) coords) drawPoint )
    {
        auto len = nodes.length;
        for(auto i = 0; i < 500000 && i < len; i++)
        {
            debug(scene) writeln("draw point i=", i, " coords=", nodes[i]);
            
            //auto coords = convert2meters( nodes[i] );
            Vector2r node; node = nodes[i];
            auto ld = getBoundary.leftDownCorner;
            auto ld_relative = node - ld;
            auto k = properties.windowPixelSize.x / getBoundary.getSizeVector.x;
            auto window_coords = ld_relative * k;
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
            return format("center=%s zoom=%g scene bbox=%s size_len=%g", center, zoom, getBoundary, getBoundary.getSizeVector.length);	
	}
}
