module osm;

import osmpbf.fileformat;
import osmpbf.osmformat;
import math.geometry;
import math.earth;
import map: Map, Region, BBox, Point, PointsStorage, MapWay = Way, WaysStorage, addPoint, addWay;

import std.stdio;
import std.string;
import std.exception;
import std.bitmanip: bigEndianToNative;
import std.zlib;
import std.math: round;
import std.algorithm: canFind;


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
    long curr_id = 0;
    Coords curr;
    
    Tags[] tags;
    
    if( !dn.keys_vals.isNull )
        tags = decodeDenseTags( dn.keys_vals );
    
    foreach( i, c; dn.id )
    {
        // decode delta
        curr_id += dn.id[i];
        curr.lat += dn.lat[i];
        curr.lon += dn.lon[i];
        
        Node n;
        n.id = curr_id;
        n.lat = curr.lat;
        n.lon = curr.lon;
        
        if( tags.length > 0 && tags[i].keys.length > 0 )
        {
            n.keys = tags[i].keys;
            n.vals = tags[i].values;
        }
        
        res ~= n;
    }
    
    return res;
}

struct Tags
{
    uint[] keys;
    uint[] values;
}

Tags[] decodeDenseTags( int[] denseTags )
{
    Tags[] res;
    
    auto i = 0;
    while( i < denseTags.length )
    {
        Tags t;
        
        while( i < denseTags.length && denseTags[i] != 0 )
        {
            enforce( denseTags[i] != 0 );
            enforce( denseTags[i+1] != 0 );
            
            t.keys ~= denseTags[i];
            t.values ~= denseTags[i+1];
            
            i += 2;
            
        }
        
        ++i;
        res ~= t;
    }
    
    return res;
}
unittest
{
    int[] t = [ 1, 2, 0, 3, 4, 5, 6 ];
    Tags[] d = decodeDenseTags( t );
    
    assert( d[0].keys[0] == 1 );
    assert( d[0].values[0] == 2 );
    
    assert( d[1].keys[0] == 3 );
    assert( d[1].values[0] == 4 );
    
    assert( d[1].keys[1] == 5 );
    assert( d[1].values[1] == 6 );
}

MapWay decodeWay( in PrimitiveBlock prim, in Coords[long] nodes_coords, in Way way )
{
    Coords[] coords;
    long curr;
    
    // decode delta
    foreach( i, c; way.refs )
    {
        curr += c;
        coords ~= nodes_coords[ curr ];
    }
    
    string tags = prim.stringtable.getTags( way.keys, way.vals );
    auto res = MapWay( coords, tags );
    
    return res;
}

string getStringByIndex( in StringTable stringtable, in uint index )
{
    auto s = cast( char[] ) stringtable.s[index];
    return to!string( s );
}

string getTag( in StringTable stringtable, in uint key, in uint value )
{
    return getStringByIndex( stringtable, key ) ~ "=" ~ getStringByIndex( stringtable, value );
}

string getTags( in StringTable stringtable, in uint[] keys, in uint[] values )
in
{
    assert( keys.length == values.length );
}
body
{
    string res;
    
    for( auto i = 0; i < keys.length; i++ )
        if( !stringtable.isBannedKey( keys[i] ) )
        {
            res ~= stringtable.getTag( keys[i], values[i] )~"\n";
        }
        
    return res;
}

bool isBannedKey( in StringTable stringtable, in uint key )
{
    string[] banned_tags = [
            "created_by",
            "source"
        ];
    
    return canFind( banned_tags, cast(char[]) stringtable.s[key] );
}

bool isPermittedTag( in StringTable stringtable, in uint key )
{
    string[] tags = [
            "building",
            "highway"
        ];
        
    return canFind( tags, cast(char[]) stringtable.s[key] );
}

alias Vector2D!long Coords;

private auto decodeGranularCoords( in PrimitiveBlock pb, in Node n )
{
    Coords r;
    
    r.lat = (pb.lat_offset + pb.granularity * n.lat);
    r.lon = (pb.lon_offset + pb.granularity * n.lon);
    
    return r;
}

Vector2D!real decodeCoords( Coords c ) pure
{
    return Vector2D!real( c.x / 10_000_000f,  c.y / 10_000_000f );
}

Vector2D!real encodeCoords( Vector2D!real c ) pure
{
    return Vector2D!real( c.x * 10_000_000f,  c.y * 10_000_000f );
}

Vector2D!real encodedToMeters( Coords c )
{
    auto decoded = decodeCoords( c );
    auto radians = degrees2radians( decoded );
    return coords2mercator( radians );
}

Coords metersToEncoded( Vector2D!real meters )
{
    auto radians = mercator2coords( meters );
    auto degrees = radians2degrees( radians );
    auto encoded = encodeCoords( degrees );
    
    return encoded.round;
}

void addPoints(
        ref PointsStorage points,
        ref PrimitiveBlock prim,
        ref Coords[long] nodes_coords,
        Node[] nodes
    )
{
    foreach( n; nodes)
    {
        nodes_coords[n.id] = Coords( n.lon, n.lat );
        
        long tmp_id = n.id;
        n.id = tmp_id;
        
        // Point with tags?
        if( !n.keys.isNull && n.keys.length > 0 )
        {
            string tags = prim.stringtable.getTags( n.keys, n.vals );
            
            // Point contains non-banned tags?
            if( tags.length > 0 )
            {
                Coords coords;
                coords.lon = n.lon;
                coords.lat = n.lat;
                
                Point point = Point( coords, tags );
                
                points.addPoint( point );
                
                debug(osm) writeln( "point id=", n.id, " tags:\n", point.tags );
            }
        }
    }
}

void addWay(
        ref WaysStorage storage,
        ref PrimitiveBlock prim,
        ref Coords[long] nodes_coords,
        Way way
    )
{
    MapWay decoded = decodeWay( prim, nodes_coords, way );
    
    // way with tags?
    if( decoded.tags.length > 0 )
    {
        storage.addWay( decoded );
    }
}

Region getRegion( string filename, bool verbose )
{
    void log(T)( T s )
    {
        if(verbose) writeln(s);
    }
    
    log("Opening file "~filename);
    auto f = File(filename);
    
    auto h = readOSMHeader( f );
    
    auto res = new Region;
    Coords[long] nodes_coords;
    
    while(true)
    {
        auto d = readOSMData( f );
        if(d.length == 0 ) break; // eof
        
        auto prim = PrimitiveBlock( d );
        
        debug(osm) writefln("lat_offset=%d lon_offset=%d", prim.lat_offset, prim.lon_offset );
        debug(osm) writeln("granularity=", prim.granularity);
        
        //prim.stringtable;
        
        foreach( i, c; prim.primitivegroup )
        {
            if( !c.dense.isNull )
            {
                auto nodes = decodeDenseNodes( c.dense );
                res.layer0.POI.addPoints( prim, nodes_coords, nodes );
            }
            
            if( !c.nodes.isNull )
                res.layer0.POI.addPoints( prim, nodes_coords, c.nodes );
                
            if( !c.ways.isNull )
                foreach( w; c.ways )
                    res.layer0.ways.addWay( prim, nodes_coords, w );
        }
    }
    
    return res;
}

Map getMap( string[] filenames, bool verbose )
{
    auto res = new Map;
    
    foreach( s; filenames )
        res.regions ~= getRegion( s, verbose );
    
    return res;
}
