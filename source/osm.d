module osm;

import osmproto;
import math.geometry: Vector2D, degrees2radians, radians2degrees;
import math.earth;
import map.map: Map, Region, BBox, Point, MapCoords, MercatorCoords, TPrepareLines;
import map.adapters: TPolylineDescription;
import map.line_graph: LineProperties;
import map.road_graph: RoadProperties;
import map.area: Area, AreaProperties;
import cat = config.categories;
import osm_tags_parsing;
import map.objects_properties: LineClass; // FIXME: remove it
import map.objects_properties: MapObjectProperties;

import std.stdio;
import std.string;
import std.exception: enforce, Exception;
import std.bitmanip: bigEndianToNative;
import std.zlib;
import std.math: round;
import std.algorithm: canFind;
import std.conv: to;


alias Vector2D!(long, "OSM coords") Coords;
alias ulong OSM_id;

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
    
    if( b.raw_size == 0 )
    {
        debug(osmpbf) writeln( "raw block, size=", b.raw.length );
        res.data = b.raw;
    }
    else
    {
        debug(osmpbf) writeln( "zlib compressed block, size=", b.raw_size );
        enforce( b.zlib_data.length > 0 );
        
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
    OSM_id curr_id = 0;
    Coords curr;
    
    Tags[] tags;
    
    if( dn.keys_vals.length != 0 )
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
    OSM_id[] coords_idx;
    Tag[] tags;
    
    invariant()
    {
        assert( coords_idx.length >= 2 );
    }
}

DecodedLine decodeWay( in PrimitiveBlock prim, in Way way )
{
    if( way.refs.length < 2 )
        throw new ReadPrimitiveException( "too short way (nodes number: "~to!string( way.refs.length )~")" );
    
    DecodedLine res;
    
    // decode index delta
    OSM_id curr = 0;
    foreach( c; way.refs )
    {
        curr += c;
        res.coords_idx ~= curr;
    }
    
    if( way.keys.length > 0 )
        res.tags = prim.stringtable.getTagsByArray( way.keys, way.vals );
        
    return res;
}

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

MercatorCoords encodedToMercator( in Coords c )
{
    auto decoded = decodeCoords( c );
    auto radians = degrees2radians( decoded );
    MercatorCoords res = coords2mercator( radians );
    return res;
}

MapCoords encodedToMapCoords( in Coords c )
{
    return MapCoords( c.encodedToMercator );
}

void addPoints(
        ref Region region,
        ref PrimitiveBlock prim,
        ref Coords[OSM_id] nodes_coords,
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
    Coords[OSM_id] nodes_coords;
    
    MapCoords getMapCoordsByNodeIdx( in OSM_id node_id )
    {
        auto node_ptr = node_id in nodes_coords;
        
        if( !node_ptr )
            throw new ReadPrimitiveException( "node "~to!string( node_id )~" is not found" );
        
        return encodedToMapCoords( *node_ptr );
    }
    
    alias TPolylineDescription!( LineProperties, getMapCoordsByNodeIdx ) LineDescription;
    alias TPolylineDescription!( RoadProperties, getMapCoordsByNodeIdx ) RoadDescription;
    alias TPolylineDescription!( AreaProperties, getMapCoordsByNodeIdx ) AreaDescription;
    
    auto lines = new TPrepareLines!( LineDescription );
    auto roads = new TPrepareLines!( RoadDescription );
    Area[] areas;    
    
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
            
            if( c.nodes.length != 0 )
                addPoints( res, prim, nodes_coords, c.nodes );
                
            if( c.ways.length != 0 )
                foreach( w; c.ways )
                    try
                    {
                        auto decoded = decodeWay( prim, w );
                        auto nullableProp = parseTags( decoded.tags );
                        
                        if( nullableProp.isNull )
                            continue;
                        
                        MapObjectProperties prop = nullableProp;
                        
                        with( LineClass )
                        final switch( prop.classification )
                        {
                            case POLYLINE:
                                auto line = LineDescription( decoded.coords_idx, prop.line );
                                lines.addLine( line );
                                break;
                                
                            case ROAD:
                                auto road = RoadDescription( decoded.coords_idx, prop.road );
                                roads.addLine( road );
                                break;
                                
                            case AREA:
                                if( decoded.coords_idx.length < 3 )
                                    throw new ReadPrimitiveException("too few points in the area");
                                
                                if( decoded.coords_idx[0] != decoded.coords_idx[$-1] )
                                    throw new ReadPrimitiveException("area is not looped");
                                
                                auto descr = AreaDescription( decoded.coords_idx[0..$-1], prop.area );
                                areas ~= Area( descr );
                                break;
                        }
                    }
                    catch( ReadPrimitiveException e )
                    {
                        stderr.writeln("Way ", w.id, " excluded: ", e.msg );
                        continue;
                    }
        }
    }
    
    res.fillAreas( areas );
    res.fillRoads( roads );
    res.fillLines( lines );
    res.moveInfoIntoRTreeArray;
    
    return res;
}

Map getMap( string[] filenames, bool verbose )
{
    auto res = new Map;
    
    foreach( s; filenames )
        res.regions ~= getRegion( s, verbose );
    
    return res;
}

private
class ReadPrimitiveException : Exception
{
    this( in string msg )
    {
        super( msg );
    }
}
