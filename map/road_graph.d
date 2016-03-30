module map.road_graph;

import map.map_graph;
import math.graph.undirected;
import math.graph.undirected_compressed;
import math.graph.pathfinder: PathFinder;
import cat = config.categories: Line;
static import pbf;


struct RoadProperties
{
    cat.Line type;
    float weight = 1;
    byte layer;
}

struct RoadLine
{
    private const pbf.Road storage;
    alias storage this;
    
    this( MapCoords[] points, RoadProperties properties )
    {
        pbf.Road s;
        
        s.polyline = MapGraphPolyline( points ).storage;
        s.type = properties.type;
        s.weight = properties.weight;
        s.layer = properties.layer;
        
        storage = s;
    }
    
    this( pbf.Road r )
    {
        storage = r;
    }
    
    MapCoords[] points() const
    {
        auto s = cast(pbf.Road) storage;
        
        return MapGraphPolyline(s.polyline).points();
    }
    
    ubyte[] Serialize() const
    {
        return storage.Serialize;
    }
    
    static RoadLine Deserialize( inout ref ubyte[] from )
    {
        auto f = from.dup;
        
        RoadLine res = pbf.Road.Deserialize( f );
        
        return res;
    }
    
    RoadProperties properties() const
    {
        RoadProperties res;
        
        res.type = cast(cat.Line) storage.type;
        res.weight = storage.weight;
        res.layer = cast(byte) storage.layer;
        
        return res;
    }
}

class RoadGraph: MapGraph!( UndirectedGraph, MapCoords, RoadLine )
{
    void sortEdgesByReducingRank()
    {
        bool greater( in EdgeDescr e1, in EdgeDescr e2 )
        {
            auto v1 = getEdge( e1 ).payload.type;
            auto v2 = getEdge( e2 ).payload.type;
            
            return v1 < v2; // less value mean greater road rank
        }
        
        sortEdges( &greater );
    }
}

private alias MapGraph!( UndirectedGraphCompressed, MapCoords, RoadLine ) RGC;

class RoadGraphCompressed: PathFinder!RGC
{
    this( RoadGraph g )
    {
        super(g);
    }
    
    override MapCoords[] getMapCoords( in EdgeDescr descr ) const
    {
        auto orig = super.getMapCoords( descr );
        
        auto edge = getEdge( descr );
        
        if( edge.forward_direction )
            return orig;
        else
        {
            MapCoords[] res = new MapCoords[ orig.length ];
            
            res[0] = orig[0];
            
            foreach( i; 1 .. orig.length )
                res[i] = orig[$-1 - i];
                
            res[$-1] = orig[$-1];
            
            return res;
        }
    }
    
    override real heuristicDistance( in NodeDescr fromDescr, in NodeDescr toDescr ) const
    {
        auto from = getNodePayload( fromDescr );
        auto to = getNodePayload( toDescr );
        
        return from.calcSphericalDistance( to );
    }
    
    override real distance( in EdgeDescr descr ) const
    {
        auto coords = getMapCoords( descr );
        
        assert( coords.length > 0 );
        
        auto prev = coords[0];
        real res = 0;
        
        for( auto i = 1; i < coords.length; i++ )
        {
            res += prev.calcSphericalDistance( coords[i] );
            prev = coords[i];
        }
        
        return res;
    }
}

unittest
{
    auto t = new RoadGraph;
}
