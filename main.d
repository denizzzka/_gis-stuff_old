module main;
import osmproto.fileformat;
import osmproto.osmformat;


import std.getopt;
debug import std.stdio;

void main( string[] args )
{
    string file;
    
    getopt(
        args,
        "osmpbf", &file,
    );
    
    debug(osmpbf) writeln("Open file", file);
}
