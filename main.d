module main;

import osm;
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
    
    getRegionMap( filename, verbose );
}
