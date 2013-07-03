module scene;

import map;
import math.geometry;
import osm: convert2meters;
import std.conv;
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
    
    auto getMapBoundary() const
    {
        auto v = Vector2r(properties.zoom, properties.zoom);
        
        auto map_size = map.boundary.getSizeVector();
        
        real ratio = to!real(map_size.x) / map_size.y;
        
        if( ratio > 1 )
            v.x *= ratio;
        else
            v.y /= ratio;
        
        return Box!Vector2r( -v/2, v );
    }
    
    private
    void drawNodes( in Node[] nodes, void delegate(Vector2D!(real) coords) drawPoint )
    {
        auto len = nodes.length;
        for(auto i = 0; i < 1000 && i < len; i++)
        {
            debug(scene) writeln("draw point i=", i, " coords=", nodes[i]);
            
            auto coords = convert2meters( nodes[i] );
            drawPoint( coords );
        }
    }
    
    void draw( void delegate(Vector2D!(real) coords) drawPoint )
    {
        debug(scene) writeln("Drawing, window size=", properties.window_size);
        
        auto boundary = getMapBoundary();
        
        foreach( reg; map.regions )
        {
            auto nodes = reg.searchNodes( boundary );
            drawNodes( nodes, drawPoint );
        }
    }
    
    //private Vector2r meters2window( Vector2r coords )
}
