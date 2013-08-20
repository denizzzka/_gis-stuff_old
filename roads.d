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
    
    size_t nodes_ids[];
    
    cat.Road type = cat.Road.OTHER;
    
    this( size_t[] nodes_ids, cat.Road type )
    {
        this.nodes_ids = nodes_ids;
        this.type = type;
    }
    
    this(this)
    {
        nodes_ids = nodes_ids.dup;
    }
    
    BBox boundary( in Coords[long] nodes ) const
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

auto boundary(T)( ref const T node )
{
    alias Box!osm.Coords BBox;
    
    auto res = BBox( node.point.coords, Coords(0,0) );
    
    for( auto i = 1; i < node.edges.length; i++ )
        res.addCircumscribe( node.edges[i].to_node.point.coords );
    
    return res;
}

struct RoadDescriptor
{
    size_t node;
    size_t edge;
    
    this( size_t node, size_t edge )
    {
        this.node = node;
        this.edge = edge;
    }
    
    /*
    osm.Way getWay() const
    {
    }
    */
}

class RoadGraph( Coords )
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
            descriptions_tree.addObject( c.boundary( nodes ), c );
        
        auto prepared = prepareRoads( descriptions_tree, nodes );
        
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
    alias RoadGraph!Coords G;
    
    Coords[] points = [
            Coords(0,0), Coords(1,1), Coords(2,2), Coords(3,3), Coords(4,4), // first road
            Coords(4,0), Coords(3,1), Coords(1,3), Coords(2,4) // second road
        ];
    
    Coords[long] nodes;
    
    foreach( i, c; points )
        nodes[ i * 10 ] = c;
    
    size_t[] n1 = [ 0, 10, 20, 30, 40 ];
    size_t[] n2 = [ 50, 60, 20, 70, 80, 30 ];
    
    auto w1 = RoadDescription( n1, cat.Road.HIGHWAY );
    auto w2 = RoadDescription( n2, cat.Road.PRIMARY );
    
    auto roads = new G.DescriptionsTree;
    roads.addObject( w1.boundary( nodes ), w1 );
    roads.addObject( w2.boundary( nodes ), w2 );
    
    auto prepared = prepareRoads( roads, nodes );
    
    assert( prepared.length == 5 );
}

private
void descriptionsToRoadGraph( Graph, RoadDescription, Coords )( ref Graph graph, in RoadDescription[] descriptions, in Coords[long] nodes )
{
    alias TRoad!Coords Road;
    
    size_t[long] already_stored;
    
    size_t addNode( long node_id )
    {
        auto p = node_id in already_stored;
        
        if( p !is null )
            return *p;
        else
        {
            auto node = Node( nodes[ node_id ] );
            auto idx = graph.addPoint( node );
            already_stored[ node_id ] = idx;
            
            return idx;
        }
    }
    
    foreach( road; descriptions )
    {
        Road r;
        
        for( auto i = 1; i < road.nodes_ids.length - 1; i++ )
            r.points ~= nodes[ road.nodes_ids[i] ];
        
        graph.addEdge(
                addNode( road.nodes_ids[0] ),
                addNode( road.nodes_ids.length-1 ),
                r, 0
            );
    }
}
