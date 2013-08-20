module osm;

import osmpbf.fileformat;
import osmpbf.osmformat;
import math.geometry;
import math.earth;
import map: Map, Region, BBox, Point, PointsStorage, MapWay = Way, WaysStorage, addPoint, addWayToStorage;
import cat = categories;
import osm_tags_parsing;
import roads: TRoadGraph;

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

struct DecodedLine
{
    ulong[] coords_idx;
    LineClass classification = LineClass.OTHER;
    Tag[] tags;
    
    Coords[] getCoords( in Coords[long] nodes_coords ) const
    {
        Coords[] res;
        
        foreach( c; coords_idx )
            res ~= nodes_coords[ c ];
        
        return res;
    }
    
    MapWay createMapWay( in PrimitiveBlock prim, in Coords[long] nodes_coords ) const
    {
        return MapWay(
                getCoords( nodes_coords ),
                prim.stringtable.getLineType( this ),
                tags.toString()
            );
    }
}

DecodedLine decodeWay( in PrimitiveBlock prim, in Way way )
{
    DecodedLine res;
    
    // decode index delta
    long curr = 0;
    foreach( c; way.refs )
    {
        curr += c;
        res.coords_idx ~= curr;
    }
    
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
            Coords coords;
            coords.lon = n.lon;
            coords.lat = n.lat;
            
            string tags = prim.stringtable.getTags( n ).toString;
            
            Point point = Point( coords, prim.stringtable.getPointType( n ), tags );
            
            region.addPoint( point );
            
            debug(osm) writeln( "point id=", n.id, " tags:\n", point.tags );
        }
    }
}

/// Cuts roads on crossroads for creating road graph
@disable
WaysStorage prepareRoadGraph( in WaysStorage roads_rtree )
{
    WaysStorage res = new WaysStorage;
    auto all_roads = roads_rtree.search( roads_rtree.getBoundary );
    
    foreach( j, roadptr; all_roads )
    {
        MapWay road = *roadptr;
        
        for( auto i = 1; i < road.nodes.length - 1; i++ )
        {
            auto curr_point = road.nodes[i];
            auto point_bbox = BBox( curr_point, Coords(0, 0) );
            auto near_roads = roads_rtree.search( point_bbox );
            
            foreach( n; near_roads )
                if( n != roadptr && canFind( n.nodes, curr_point ) )
                {
                    res.addWayToStorage( road[ 0..i+1 ] );
                    road = road[ i..road.nodes.length ];
                    i = 0;
                    break;
                }
        }
        
        res.addWayToStorage( road );
    }
    
    return res;
}
unittest
{
    Coords[] n1 = [ Coords(0,0), Coords(1,1), Coords(2,2), Coords(3,3), Coords(4,4) ];
    Coords[] n2 = [ Coords(4,0), Coords(3,1), Coords(2,2), Coords(1,3), Coords(2,4), Coords(3,3) ];
    
    auto w1 = MapWay( n1, cat.Line.ROAD_HIGHWAY, "" );
    auto w2 = MapWay( n2, cat.Line.ROAD_PRIMARY, "" );
    
    auto roads = new WaysStorage;
    roads.addWayToStorage( w1 );
    roads.addWayToStorage( w2 );
    
    //auto prepared = prepareRoadGraph( roads );
    //auto res = prepared.search( prepared.getBoundary );
    
    //assert( res.length == 5 );
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
    
    alias TRoadGraph!Coords RGraph;
    RGraph.RoadDescription[] roads;
    
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
                {
                    auto decoded = decodeWay( prim, w );
                    
                    with( LineClass )
                    switch( decoded.classification )
                    {
                        case BUILDING:
                            MapWay mw = decoded.createMapWay( prim, nodes_coords );
                            res.addWay( mw );
                            break;
                            
                        case ROAD:
                            roads ~= RGraph.RoadDescription( decoded.coords_idx, cat.Road.OTHER );
                            break;
                            
                        default:
                            break;
                    }
                }
        }
    }
    
    auto graph = new RGraph( nodes_coords, roads );
    
    return res;
}

Map getMap( string[] filenames, bool verbose )
{
    auto res = new Map;
    
    foreach( s; filenames )
        res.regions ~= getRegion( s, verbose );
    
    return res;
}
