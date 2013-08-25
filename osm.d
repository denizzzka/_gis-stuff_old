module osm;

import osmpbf.fileformat;
import osmpbf.osmformat;
import math.geometry;
import math.earth;
import map: Map, Region, BBox, Point, PointsStorage, Line, LinesStorage, addPoint, addLineToStorage, MapCoords = Coords, RGraph;
import cat = categories;
import osm_tags_parsing;
import roads: TRoadDescription, TRoadGraph;

import std.stdio;
import std.string;
import std.exception: enforce;
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

struct DecodedLine
{
    ulong[] coords_idx;
    LineClass classification = LineClass.OTHER;
    Tag[] tags;
    
    invariant()
    {
        assert( coords_idx.length >= 2 );
    }
    
    MapCoords[] getCoords( in Coords[long] nodes_coords ) const
    {
        MapCoords[] res;
        
        foreach( c; coords_idx )
            res ~= encodedToMapCoords( nodes_coords[ c ] );
        
        return res;
    }
    
    private
    Line createLine( in PrimitiveBlock prim, in Coords[long] nodes_coords ) const
    {
        return Line(
                getCoords( nodes_coords ),
                prim.stringtable.getLineType( this ),
                tags.toString()
            );
    }
}

DecodedLine decodeWay( in PrimitiveBlock prim, in Way way )
in
{
    assert( way.refs.length >= 2 );
}
body
{
    DecodedLine res;
    
    // decode index delta
    long curr = 0;
    foreach( c; way.refs )
    {
        curr += c;
        res.coords_idx ~= curr;
    }
    
    enforce( res.coords_idx.length >= 2, "way id="~to!string(way.id)~" - too short way" );
    
    if( !way.keys.isNull )
        res.tags = prim.stringtable.getTagsByArray( way.keys, way.vals );
        
    res.classification = classifyLine( res.tags );
    
    return res;
}

alias Vector2D!long Coords;

private auto decodeGranularCoords( in PrimitiveBlock pb, in Node n )
{
    Coords r;
    
    r.lat = (pb.lat_offset + pb.granularity * n.lat);
    r.lon = (pb.lon_offset + pb.granularity * n.lon);
    
    return r;
}

Vector2D!real decodeCoords( in Coords c ) pure
{
    return Vector2D!real( c.x / 10_000_000f,  c.y / 10_000_000f );
}

Vector2D!real encodeCoords( Vector2D!real c ) pure
{
    return Vector2D!real( c.x * 10_000_000f,  c.y * 10_000_000f );
}

Vector2D!real encodedToMeters( in Coords c )
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

MapCoords encodedToMapCoords( in Coords c )
{
    auto m = encodedToMeters( c );
    
    return MapCoords( to!double( m.x ), to!double( m.y ) );
}

void addPoints(
        ref Region region,
        ref PrimitiveBlock prim,
        ref Coords[long] nodes_coords,
        Node[] nodes
    )
{
    foreach( n; nodes)
    {
        nodes_coords[n.id] = Coords( n.lon, n.lat );
        
        auto type = prim.stringtable.getPointType( n );
        
        // Point contains understandable tags?
        if( type != cat.Point.UNSUPPORTED )
        {
            Coords coords = Coords( n.lon, n.lat );
            
            string tags = prim.stringtable.getTags( n ).toString;
            
            Point point = Point(
                    encodedToMapCoords( coords ),
                    prim.stringtable.getPointType( n ),
                    tags
                );
            
            region.addPoint( point );
            
            debug(osm) writeln( "point id=", n.id, " tags:\n", point.tags );
        }
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
    
    alias TRoadDescription!( MapCoords, Coords ) RoadDescription;
    RoadDescription[] roads;
    
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
                addPoints( res, prim, nodes_coords, nodes );
            }
            
            if( !c.nodes.isNull )
                addPoints( res, prim, nodes_coords, c.nodes );
                
            if( !c.ways.isNull )
                foreach( w; c.ways )
                    if( w.refs.length >= 2 )
                    {
                        auto decoded = decodeWay( prim, w );
                        
                        with( LineClass )
                        switch( decoded.classification )
                        {
                            case BUILDING:
                                Line line = decoded.createLine( prim, nodes_coords );
                                res.addLine( line );
                                break;
                                
                            case ROAD:
                                auto type = getRoadType( decoded.tags );
                                roads ~= RoadDescription( decoded.coords_idx, type, w.id );
                                break;
                                
                            default:
                                break;
                        }
                    }
        }
    }
    
    res.addRoadGraph = new RGraph( nodes_coords, roads );
    
    return res;
}

Map getMap( string[] filenames, bool verbose )
{
    auto res = new Map;
    
    foreach( s; filenames )
        res.regions ~= getRegion( s, verbose );
    
    return res;
}
