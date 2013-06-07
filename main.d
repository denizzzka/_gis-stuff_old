module main;
import osmproto.fileformat;
import osmproto.osmformat;

import std.stdio;
import std.string;
import std.getopt;
import std.exception;
import std.bitmanip: bigEndianToNative;
import std.zlib;


struct PureBlob
{
    string type;
    ubyte[] data;
}

PureBlob readBlob( ref File f )
{
    PureBlob res;
    
    ubyte[4] bs = f.rawRead( new ubyte[4] );
    
    auto BlobHeader_size = bigEndianToNative!uint( bs );
    enforce( BlobHeader_size > 0 );
    
    auto bhc = f.rawRead( new ubyte[BlobHeader_size] );
    auto bh = BlobHeader( bhc );
    
    res.type = bh.type;
    
    auto bc = f.rawRead( new ubyte[bh.datasize] );
    auto b = Blob( bc );
    
    if( b.raw_size.isNull )
    {
        debug(osmpbf) writeln( "raw block, size=", b.raw.length );
        res.data = b.raw;
    }
    else
    {
        debug(osmpbf) writeln( "zlib compressed block, size=", b.raw_size );
        enforce( !b.zlib_data.isNull );
        
        res.data = cast(ubyte[]) uncompress( b.zlib_data, b.raw_size );
    }
    
    return res;
}

PrimitiveBlock readPrimitiveBlock( ref File f )
{
    auto hb = readBlob( f );
    enforce( hb.type == "OSMHeader" );                 
    
    auto h = HeaderBlock( hb.data );
    
    debug(osmpbf)
    {
        writefln( "required_features=%s", h.required_features );
    }
    
    auto d = readBlob( f );
    enforce( d.type == "OSMData" );
    
    return PrimitiveBlock( d.data );
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
    
    auto primitive = readPrimitiveBlock( f );
    
    //foreach( i, c; primitive.PrimitiveGroup )
    writeln( primitive );
}
