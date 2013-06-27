module osm;

import osmpbf.fileformat;
import osmpbf.osmformat;
import math.geometry;
import map: Region, MapNode = Node;

import std.stdio;
import std.string;
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
    
    ubyte[] bs_slice = f.rawRead( new ubyte[4] );
    if( bs_slice.length != 4 ) return res; // file end
    ubyte[4] bs = bs_slice;
    
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

HeaderBlock readOSMHeader( ref File f )
{
    auto hb = readBlob( f );
    
    enforce( hb.type == "OSMHeader", "\""~hb.type~"\" instead of OSMHeader" );                 
    
    auto h = HeaderBlock( hb.data );
    
    debug(osmpbf)
    {
        writefln( "required_features=%s", h.required_features );
    }
    
    return h;
}

ubyte[] readOSMData( ref File f )
{
    auto d = readBlob( f );
    
    if( d.data.length != 0 )
        enforce( d.type == "OSMData", "\""~d.type~"\" instead of OSMData" );
    
    return d.data;
}    

Node[] decodeDenseNodes(DenseNodesArray)( DenseNodesArray dn )
{
    Node[] res;
    Node curr;
    curr.id = 0;
    curr.lat = 0;
    curr.lon = 0;
    
    foreach( i, c; dn.id )
    {
        // decode delta
        curr.id += dn.id[i];
        curr.lat += dn.lat[i];
        curr.lon += dn.lon[i];
        
        res ~= curr;
    }
    
    return res;
}

alias Vector2D!long Vector2;

auto decodeCoords( in PrimitiveBlock pb, in Node n )
{
    Vector2 r;
    
    r.lat = (pb.lat_offset + pb.granularity * n.lat);
    r.lon = (pb.lon_offset + pb.granularity * n.lon);
    
    return r;
}

Region getRegionMap( string filename, bool verbose )
{
    void log(T)( T s )
    {
        if(verbose) writeln(s);
    }
    
    log("Open file "~filename);
    auto f = File(filename);
    
    auto h = readOSMHeader( f );
    
    auto res = new Region;
    
    while(true)
    {
        auto d = readOSMData( f );
        if(d.length == 0 ) break; // eof
        
        auto prim = PrimitiveBlock( d );
        debug(osm) writefln("lat_offset=%d lon_offset=%d", prim.lat_offset, prim.lon_offset );
        debug(osm) writeln("granularity=", prim.granularity);
        
        foreach( i, c; prim.primitivegroup )
        {
            if( !c.dense.isNull )
            {
                auto nodes = decodeDenseNodes( c.dense );
                foreach( n; nodes)
                {
                    debug(osm) writefln( "id=%d coords=%s", n.id, decodeCoords( prim, n ) );
                    
                    MapNode mn = { lat: n.lat, lon: n.lon };
                    res.addNode( mn );
                }
            }
            
            if( !c.nodes.isNull )
                foreach( n; c.nodes )
                {
                    debug(osm) writefln( "id=%d coords=%s", n.id, decodeCoords( prim, n ) );
                    
                    MapNode mn = { lat: n.lat, lon: n.lon };
                    res.addNode( mn );
                }
        }
    }
    
    return res;
}

