module main;
import osmproto.fileformat;
import osmproto.osmformat;

import std.stdio;
import std.getopt;
import std.stdio;


void main( string[] args )
{
    string filename;
    bool verbose;
    
    getopt(
        args,
        "verbose", &verbose,
        "osmpbf", &filename,
    );
    
    void log( string s )
    {
        if(verbose) writeln("Open file", filename);
    }
    
    log("Open file "~filename);
    auto file = File(filename, "r");
}
