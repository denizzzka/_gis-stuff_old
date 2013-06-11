module main;

import osm;
static import sfml;

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
    
    sfml2.init;
    
    getRegionMap( filename, verbose );
}
