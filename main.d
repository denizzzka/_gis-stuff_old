module main;
import osmproto.fileformat;
import osmproto.osmformat;

import std.stdio;
import std.string;
import std.getopt;
//import std.mmfile;
import std.bitmanip: bigEndianToNative;


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
        if(verbose) writeln(s);
    }
    
    log("Open file "~filename);
    auto f = File(filename);
    
    ubyte[4] bs = f.rawRead( new ubyte[4] );
    
    auto BlobHeader_size = bigEndianToNative!uint( bs );
    log(format("%d", BlobHeader_size ));
    
    //auto bha = b[4..$];
    //auto bh = BlobHeader( bha );
}
