module main;

import math.geometry;
import osm: getMap;
import map;
import scene;
static import sfml;

import std.getopt;
import std.stdio;
import std.math: fmax;


void main( string[] args )
{
    bool verbose;
    
    getopt(
        args,
        "verbose", &verbose,
    );
    
    auto window = new sfml.Window;
    
    static if(true)
    {
        auto map = getMap( args[1..$], verbose );
    }
    else
    {
        auto map = new Map;
        map.regions ~= new Region;
        map.regions[0].addNode( Node(56,94) );
        map.regions[0].addNode( Node(56,95) );
        map.regions[0].addNode( Node(57,95) );
    }
    
    Properties p;
    auto map_size = map.boundary.getSizeVector;
    p.zoom = fmax( map_size.x, map_size.y );
    p.center = map.boundary.getCenter;
    
    writeln( p );
    
    window.scene = new Scene( map );
    window.scene.properties = p;
    
    writeln( "Map bbox:", map.regions[0].boundary );
    
    window.mainCycle();
}
