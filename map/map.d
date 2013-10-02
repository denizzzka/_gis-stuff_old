module map.map;

import math.geometry;
static import math.earth;
import map.region.region;
static import pbf = pbf.map_objects;
import map.road_graph: RoadGraphCompressed; // TODO: temporary, need for current dirty path implementation

debug(map) import std.stdio;


alias Vector2D!(real, "Mercator coords") MercatorCoords;

struct MapCoords
{
    alias Vector2D!(long, "Map coords vector") Coords;
    
    package Coords map_coords;
    
    this( Coords coords )
    {
        map_coords = coords;
    }
    
    this( MercatorCoords coords )
    {
        map_coords = ( coords * 10 ).lround;
    }
    
    MercatorCoords getMercatorCoords() const pure
    {
        MercatorCoords res = map_coords;
        res /= 10;
        
        return res;
    }
    
    alias getMercatorCoords this;
    
    real calcSphericalDistance( in MapCoords v ) const
    {
        return math.earth.getSphericalDistance( getRadiansCoords, v.getRadiansCoords );
    }
    
    auto getRadiansCoords() const
    {
        return math.earth.mercator2coords( getMercatorCoords );
    }
    
    pbf.MapCoords toPbf() const
    {
        pbf.MapCoords res;
        
        res.lon = map_coords.lon;
        res.lat = map_coords.lat;
        
        return res;
    }
    
    static MapCoords fromPbf( inout pbf.MapCoords from )
    {
        MapCoords res;
        
        res.map_coords.lon = from.lon;
        res.map_coords.lat = from.lat;
        
        return res;
    }
    
    ubyte[] Serialize() const
    out(r)
    {
        auto d = Deserialize(r);
        
        assert( d == this );
    }
    body
    {
        return toPbf.Serialize;
    }
    
    static MapCoords Deserialize( inout ref ubyte[] from )
    {
        auto f = from.dup;
        auto c = pbf.MapCoords.Deserialize( f );
        
        return MapCoords( MapCoords.Coords( c.lon.get, c.lat.get ) );
    }
    
    alias Box!Coords BBox;
    
    /// Returns: zero-sized BBox containing this point
    BBox getBBox() const
    {
        return BBox( map_coords, Coords(0,0) );
    }
}

alias MapCoords.BBox BBox;
alias Box!MercatorCoords MBBox;

BBox toBBox( in MBBox mbox )
{
    BBox res;
    
    res.ld = (mbox.ld * 10).roundToLeftDown!long;
    res.ru = (mbox.ru * 10).roundToRightUpper!long;
    
    return res;
}

MBBox toMBBox( in BBox bbox )
{
    MBBox res;
    
    res.ld = MapCoords( bbox.ld );
    res.ru = MapCoords( bbox.ru );
    
    return res;
}

struct MapLinesDescriptor
{
    const Region* region;
    const size_t layer_num;
    
    LinesRTree_array.Found lines;
}

class Map
{
    Region[] regions;
    
    RoadGraphCompressed.Polylines found_path;
    
    MBBox boundary() const
    {
        return regions[0].boundary; // FIXME
    }
    
    MapLinesDescriptor[] getLines( in size_t layer_num, in BBox boundary ) const
    {
        MapLinesDescriptor[] res;
        
        foreach( ref region; regions )
        {
            MapLinesDescriptor curr = {
                    region: &region,
                    layer_num: layer_num,
                    lines: region.layers[ layer_num ]._lines.search( boundary )
                };
            
            res ~= curr;
        }
        
        debug(map)
        {
            size_t num;
            
            foreach( ref c; res )
                num += c.lines.length;
                
            writeln( __FUNCTION__~": found ", num, " lines" );
        }
        
        return res;
    }
    
    void updatePath()
    {
        RoadGraphCompressed g = regions[0].layers[0].road_graph;
        
        RoadGraphCompressed.EdgeDescr[] path;
        
        do
        {
            path = g.findPath( g.getRandomNode, g.getRandomNode );
        }
        while( path.length == 0 );
        
        RoadGraphCompressed.Polylines.GraphLines gl = { map_graph: g, descriptors: path };
        
        found_path.lines.destroy;
        found_path.lines ~= gl;
    }
}
