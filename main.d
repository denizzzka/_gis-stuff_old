module main;

import math.geometry;
import osm: getMap;
import map;
import scene;
static import sfml;

import std.getopt;
import std.stdio;
import std.math: fmin;
import std.conv: to;


void main( string[] args )
{
    bool verbose;
    
    getopt(
        args,
        "verbose", &verbose,
    );
    
    auto window = new sfml.Window;
    
    debug(test_map)
    {
        auto map = new Map;
        map.regions ~= new Region;
        map.regions[0].addNode( Node(56,94) );
        map.regions[0].addNode( Node(56,95) );
        map.regions[0].addNode( Node(57,95) );
    }
    else
    {
        auto map = getMap( args[1..$], verbose );
    }
    
    Properties p;
    p.windowPixelSize = window.window.size;
    
    window.scene = new Scene( map );
    window.scene.properties = p;
    
    window.scene.centerToWholeMap;
    window.scene.zoomToWholeMap;
    
    writeln( "Map bbox:", map.regions[0].boundary );
    
    window.mainCycle();
}
