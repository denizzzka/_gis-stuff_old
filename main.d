module main;

import osm;
static import sdl;

import std.getopt;


void main( string[] args )
{
    string filename;
    bool verbose;
    
    getopt(
        args,
        "verbose", &verbose,
        "osmpbf", &filename,
    );
    
    sdl.init;
    
    getRegionMap( filename, verbose );
}
