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
        map.regions[0].layer0.POI.add( Node(179_0_000_000, 56) );
        map.regions[0].layer0.POI.add( Node(179_1_000_000, 56) );
        map.regions[0].layer0.POI.add( Node(179_1_000_000, 57) );
    }
    else
    {
        auto map = getMap( args[1..$], verbose );
    }
    
    window.scene = new Scene( map );
    
    window.scene.centerToWholeMap;
    window.scene.zoomToWholeMap( window.window.size );
    
    writeln( "Map bbox:", map.regions[0].boundary );
    
    window.mainCycle();
}
