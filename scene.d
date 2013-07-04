module scene;

import map;
import math.geometry;
import math.earth: mercator2coords;
import std.conv;
import std.string;
import std.math: fmin, fmax;
debug(scene) import std.stdio;


alias Vector2D!real Vector2r;
alias Vector2D!size_t Vector2s;
alias Vector2D!long Vector2l;

struct Properties
{
    Vector2r center;
    real zoom; /// pixels per meter
    Vector2s windowPixelSize;
}

class Scene
{
    const Map map;
    Properties properties;
    Box!Vector2r boundary; /// coords in radians
    
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
            auto meters_boundary = Box!Vector2r( leftDownCorner, b_size );
            
            boundary = getRadiansCoordsBox( meters_boundary );
        }
    }
    
    private
    void drawNodes( in Node[] nodes, void delegate(Vector2D!(real) coords) drawPoint )
    {
        auto len = nodes.length;
        for(auto i = 0; i < 5000 && i < len; i++)
        {
            debug(scene) writeln("draw point i=", i, " coords=", nodes[i]);
            
            Vector2r node = encodedCoordsToRadians( nodes[i] );
            auto ld = boundary.leftDownCorner;
            auto ld_relative = node - ld;
            auto window_coords = ld_relative * properties.zoom;
            drawPoint( window_coords );
        }
    }
    
    void draw( void delegate(Vector2D!(real) coords) drawPoint )
    {
        debug(scene) writeln("Drawing, window size=", properties.windowPixelSize);
        
        calcBoundary();
        
        foreach( reg; map.regions )
        {
            auto nodes = reg.searchNodes( boundary );
            debug(scene) writeln("found nodes=",nodes.length);
            drawNodes( nodes, drawPoint );
        }
    }
    
	override string toString()
    {
        with(properties)
            return format("center=%s zoom=%g scene bbox=%s size_len=%g", center, zoom, boundary, boundary.getSizeVector.length);	
	}
}

Box!Vector2r getRadiansCoordsBox( in Box!Vector2r meters ) pure
{
    Box!Vector2r res;
    
    res.ld = mercator2coords( meters.ld );
    res.ru = mercator2coords( meters.ru );
    auto lu = mercator2coords( meters.lu );
    auto rd = mercator2coords( meters.rd );
    
    res.addCircumscribe( lu );
    res.addCircumscribe( rd );
    
    return res;
}
