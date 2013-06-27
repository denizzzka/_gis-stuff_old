module main;

import osm;
static import sfml;

import std.getopt;


void main( string[] args )
{
    bool verbose;
    
    getopt(
        args,
        "verbose", &verbose,
    );
    
    auto w = new sfml.Window;
    
    auto map = getMap( args[1..$], verbose );
}
