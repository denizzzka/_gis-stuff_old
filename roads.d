module roads;

import math.geometry;
import math.rtree2d;
import math.graph;
static import osm;
import cat = categories: Road;

import std.algorithm: canFind;

    
struct TRoadDescription( _Coords )
{
    alias _Coords Coords;
    alias Box!Coords BBox;
    
    ulong nodes_ids[];
    
    cat.Road type = cat.Road.OTHER;
    
    this( ulong[] nodes_ids, cat.Road type )
    {
        this.nodes_ids = nodes_ids;
        this.type = type;
    }
    
    this(this)
    {
        nodes_ids = nodes_ids.dup;
    }
    
    BBox getBoundary( in Coords[long] nodes ) const
    {
        auto res = BBox( nodes[ nodes_ids[0] ], Coords(0,0) );
        
        for( auto i = 1; i < nodes_ids.length; i++ )
        {
            assert( nodes_ids[i] in nodes );
            res.addCircumscribe( nodes[ nodes_ids[i] ] );
        }
        
        return res;
    }
    
    TRoadDescription opSlice( size_t from, size_t to )
    {
        auto res = this;
        
        res.nodes_ids = nodes_ids[ from..to ];
        
        return res;
    }
}

struct TRoad( Coords )
{
    private
    {
        Coords[] points; /// points between start and end points
    }
    
    cat.Road type = cat.Road.OTHER;
}

struct Node
{
    osm.Coords coords;
    
    this( osm.Coords coords )
    {
        this.coords = coords;
    }
    
    float distance( in Node v, in float weight ) const
    {
        return (coords - v.coords).length * weight;
    }
    
    float heuristic( in Node v ) const
    {
        return (coords - v.coords).length;
    }
}

@disable
auto boundary(T)( ref const T node )
{
    alias Box!osm.Coords BBox;
    
    auto res = BBox( node.point.coords, Coords(0,0) );
    
    for( auto i = 1; i < node.edges.length; i++ )
        res.addCircumscribe( node.edges[i].to_node.point.coords );
    
    return res;
}

class TRoadGraph( Coords )
{
    alias Box!Coords BBox;
    alias TRoadDescription!Coords RoadDescription;
    alias TRoad!Coords Road;
    alias RTreePtrs!( BBox, RoadDescription ) DescriptionsTree;
    alias RTreePtrs!( BBox, Road ) RoadsRTree;
    alias Graph!( Node, Road, float ) G;
    
    private
    {
        G graph;
    }
    
    this( in Coords[long] nodes, scope RoadDescription[] descriptions )
    {        
        auto descriptions_tree = new DescriptionsTree;
        
        foreach( i, c; descriptions )
            descriptions_tree.addObject( c.getBoundary( nodes ), c );
        
        auto prepared = descriptions_tree.prepareRoads( nodes );
        
        graph = new G;
        
        graph.descriptionsToRoadGraph( prepared, nodes );
    }
    
    RoadDescriptor[] getDescriptors() const
    {
        RoadDescriptor[] res;
        
        foreach( j, ref const node; graph.nodes )
            foreach( i, ref const edge; node.edges )
                res ~= RoadDescriptor( j, i );
        
        return res;
    }
    
    static struct RoadDescriptor
    {
        uint node_idx;
        uint edge_idx;
        
        this( uint node_idx, uint edge_idx )
        {
            this.node_idx = node_idx;
            this.edge_idx = edge_idx;
        }
        
        Coords[] getPoints( in TRoadGraph roadGraph ) const
        {
            Coords[] res;
            
            auto start_node = &roadGraph.graph.nodes[ node_idx ];
            
            res ~= start_node.point.coords;
            
            auto edge = &start_node.edges[ edge_idx ];
            
            foreach( c; edge.payload.points )
                res ~= c;
            
            auto end_node_idx = edge.to_node;
            res ~= roadGraph.graph.nodes[ end_node_idx ].point.coords;
            
            return res;
        }
        
        BBox getBoundary( in TRoadGraph roadGraph ) const
        {
            auto points = getPoints( roadGraph );
            assert( points.length > 0 );
            
            auto res = BBox( points[0], Coords(0,0) );
            
            for( auto i = 1; i < points.length; i++ )
                res.addCircumscribe( points[i] );
            
            return res;
        }
        
        cat.Road getType( in TRoadGraph roadGraph ) const
        {
            auto node = &roadGraph.graph.nodes[ node_idx ];
            auto edge = node.edges[ edge_idx ];
            
            return edge.payload.type;
        }
    }
    
    static struct Roads
    {
        RoadDescriptor*[] descriptors;
        const TRoadGraph road_graph;
        
        this( in TRoadGraph graph )
        {
            road_graph = graph;
        }
        
        Coords[] getPoints( in size_t descriptor_idx ) const
        {
            auto descriptor = descriptors[ descriptor_idx ];
            return descriptor.getPoints( road_graph );
        }
    }
}

/// Cuts roads on crossroads for creating road graph
private
DescriptionsTree.Payload[] prepareRoads(DescriptionsTree, Coords)( in DescriptionsTree roads_rtree, in Coords[long] nodes )
{
    alias DescriptionsTree.Payload RoadDescription;
    alias Box!Coords BBox;
    
    RoadDescription[] res;
    auto all_roads = roads_rtree.search( roads_rtree.getBoundary );
    
    foreach( roadptr; all_roads )
    {
        RoadDescription road = *roadptr;
        
        for( auto i = 1; i < road.nodes_ids.length - 1; i++ )
        {
            auto curr_point = road.nodes_ids[i];
            auto point_bbox = BBox( nodes[ curr_point ], Coords(0, 0) );
            auto near_roads = roads_rtree.search( point_bbox );
            
            foreach( n; near_roads )
                if( n != roadptr && canFind( n.nodes_ids, curr_point ) )
                {
                    res ~= road[ 0..i+1 ];
                    
                    road = road[ i..road.nodes_ids.length ];
                    i = 0;
                    break;
                }
        }
        
        res ~= road;
    }
    
    return res;
}
unittest
{
    alias osm.Coords Coords;
    alias TRoadDescription!Coords RoadDescription;
    alias TRoadGraph!Coords G;
    
    Coords[] points = [
            Coords(0,0), Coords(1,1), Coords(2,2), Coords(3,3), Coords(4,4), // first road
            Coords(4,0), Coords(3,1), Coords(1,3), Coords(2,4) // second road
        ];
    
    Coords[long] nodes;
    
    foreach( i, c; points )
        nodes[ i * 10 ] = c;
    
    ulong[] n1 = [ 0, 10, 20, 30, 40 ];
    ulong[] n2 = [ 50, 60, 20, 70, 80, 30 ];
    
    auto w1 = RoadDescription( n1, cat.Road.HIGHWAY );
    auto w2 = RoadDescription( n2, cat.Road.PRIMARY );
    
    auto roads = new G.DescriptionsTree;
    roads.addObject( w1.getBoundary( nodes ), w1 );
    roads.addObject( w2.getBoundary( nodes ), w2 );
    
    auto prepared = prepareRoads( roads, nodes );
    
    assert( prepared.length == 5 );
}

private
void descriptionsToRoadGraph( Graph, RoadDescription, Coords )( ref Graph graph, in RoadDescription[] descriptions, in Coords[long] nodes )
{
    alias TRoad!Coords Road;
    
    size_t[ulong] already_stored;
    
    // собственная функция нужна чтобы исключить пересечение между разными точками с одинаковыми координатами
    size_t addPoint( ulong node_id )
    {
        auto p = node_id in already_stored;
        
        if( p !is null )
            return *p;
        else
        {
            auto coord = node_id in nodes;
            
            assert( coord != null );
            
            auto node = Node( *coord );
            auto idx = graph.addPoint( node );
            already_stored[ node_id ] = idx;
            
            return idx;
        }
    }
    
    foreach( road; descriptions )
    {
        assert( road.nodes_ids.length >= 2 );
        
        Road r;
        
        for( auto i = 1; i < road.nodes_ids.length - 1; i++ )
            r.points ~= nodes[ road.nodes_ids[i] ];
        
        graph.addEdge(
                addPoint( road.nodes_ids[0] ),
                addPoint( road.nodes_ids[$-1] ),
                r, 0
            );
    }
}
