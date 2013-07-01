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
    
    Vector2D!size_t window_size;
    window_size = window.window.size;
    
    auto scene = new Scene( getMap( args[1..$], verbose ), window_size );
    
    /*
    auto map = new Map;
    map.regions ~= new Region;
    map.regions[0].addNode( Node(56,94) );
    map.regions[0].addNode( Node(56,95) );
    map.regions[0].addNode( Node(57,95) );
    */
    
    writeln( "Map bbox:", scene.map.regions[0].boundary );
    
    //window.reg = window.new ShowRegion( map.regions[0] );
    //window.mainCycle();
}
