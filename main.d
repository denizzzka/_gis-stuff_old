module main;

import osm: getMap;
import map;
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
    
    auto w = new sfml.Window;
    
    auto map = getMap( args[1..$], verbose );
    
    //auto map = new Map;
    //map.regions ~= new Region;
    //map.regions[0].addNode( Node(1,2) );
    
    writeln( map.regions[0].boundary );
}
