module main;

import osm: getMap;
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
    
    writeln( map.regions[0].boundary );
}
