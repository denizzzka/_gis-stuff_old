module main;
import osmproto.fileformat;
import osmproto.osmformat;

import std.stdio;
import std.string;
import std.getopt;
import std.exception;
import std.bitmanip: bigEndianToNative;
import std.zlib;


ubyte[] readBlob( ref File f )
{
    ubyte[4] bs = f.rawRead( new ubyte[4] );
    
    auto BlobHeader_size = bigEndianToNative!uint( bs );
    enforce( BlobHeader_size > 0 );
    
    auto bhc = f.rawRead( new ubyte[BlobHeader_size] );
    auto bh = BlobHeader( bhc );
    enforce( bh.type == "OSMHeader" );
    
    auto bc = f.rawRead( new ubyte[bh.datasize] );
    auto b = Blob( bc );
    
    if( b.raw_size.isNull )
    {
        debug(osmpbf) writeln( "raw block, size=", b.raw.length );
        return b.raw;
    }
    else
    {
        debug(osmpbf) writeln( "zlib compressed block, size=", b.raw_size );
        enforce( !b.zlib_data.isNull );
        
        return cast(ubyte[]) uncompress( b.zlib_data, b.raw_size );
    }
}


void main( string[] args )
{
    string filename;
    bool verbose;
    
    getopt(
        args,
        "verbose", &verbose,
        "osmpbf", &filename,
    );
    
    void log(T)( T s )
    {
        if(verbose) writeln(s);
    }
    
    log("Open file "~filename);
    auto f = File(filename);
    
    writeln( readBlob( f ).length );
}
