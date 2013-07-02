module scene;

import map;
import math.geometry;
import osm: convert2meters;
import std.conv;
debug(scene) import std.stdio;


alias Vector2D!real Vector2r;
alias Vector2D!size_t Vector2s;
alias Vector2D!long Vector2l;

struct Properties
{
    Vector2r center;
    real zoom;
    Vector2s window_size;
}

class Scene
{
    const Map map;
    Properties properties;
    
    this( in Map m, in Vector2s windowPixelsSize )
    {
        map = m;
        properties.window_size = windowPixelsSize;
    }
    
    void viewToWholeMap()
    {
        auto b = map.regions[0].boundary;
        auto map_size = b.rightUpCorner - b.leftDownCorner;
        properties.center = map_size / 2;
        properties.zoom = to!real(properties.window_size.x) / map_size.x;
    }
    
    void draw( void delegate(Vector2D!(real) coords) drawPoint )
    {
        debug(scene) writeln("Drawing, window size=", properties.window_size);
        
        foreach( reg; map.regions )
        {
            auto nodes = reg.getNodes;
            auto len = nodes.length;
            for(auto i = 0; i < 1000 && i < len; i++)
            {
                debug(scene) writeln("draw point i=", i, " coords=", nodes[i]);
                
                auto coords = convert2meters( nodes[i] );
                drawPoint( coords );
            }
        }
    }
    
    //private Vector2r meters2window( Vector2r coords )
}
