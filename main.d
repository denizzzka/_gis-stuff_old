module main;

import math.geometry;
import osm: getMap;
import map;
import scene;
static import sfml;

import std.getopt;
import std.stdio;

void main( string[] args )
{
    bool verbose;
    
    getopt(
        args,
        "verbose", &verbose,
    );
    
    auto window = new sfml.Window;
    auto map = getMap( args[1..$], verbose );
    
    Vector2s window_size;
    window_size = window.window.size;
    
    window.scene = new Scene( map, window_size );
    window.scene.viewToWholeMap;
    
    /*
    auto map = new Map;
    map.regions ~= new Region;
    map.regions[0].addNode( Node(56,94) );
    map.regions[0].addNode( Node(56,95) );
    map.regions[0].addNode( Node(57,95) );
    */
    
    writeln( "Map bbox:", map.regions[0].boundary );
    
    window.mainCycle();
}
