import math.geometry;
import math.rtree2d;
import math.graph;
static import osm;
import cat = categories: Road;

import std.algorithm: canFind;

    
struct TRoadDescription( Coords )
{
    alias Box!Coords BBox;
    
    size_t nodes_index[];
    
    cat.Road type = cat.Road.OTHER;
    
    invariant()
    {
        //assert( nodes_index.length >= 2 );
    }
    
    this( size_t[] nodes_index, cat.Road type )
    {
        this.nodes_index = nodes_index;
        this.type = type;
    }
    
    this(this)
    {
        nodes_index = nodes_index.dup;
    }
    
    BBox boundary( in Coords[long] nodes ) const
    {
        auto res = BBox( nodes[ nodes_index[0] ], Coords(0,0) );
        
        for( auto i = 1; i < nodes_index.length; i++ )
        {
            assert( nodes_index[i] in nodes );
            res.addCircumscribe( nodes[ nodes_index[i] ] );
        }
        
        return res;
    }
    
    TRoadDescription opSlice( size_t from, size_t to )
    {
        auto res = this;
        
        res.nodes_index = nodes_index[ from..to ];
        
        return res;
    }
}

class RoadGraph( Coords )
{
    alias Box!Coords BBox;
    alias RTreePtrs!(BBox, RoadGraph.Road) RoadsRTree;
    alias TRoadDescription!Coords RoadDescription;
    alias RTreePtrs!( BBox, RoadDescription ) DescriptionsTree;
    alias Graph!( DNP, long, float ) G;
    
    private
    {
        //Coords[long] nodes_coords;
        G graph;
    }
    
    this( in Coords[long] nodes, scope RoadDescription[] roads )
    {        
        auto descriptions_tree = new DescriptionsTree;
        
        foreach( i, c; roads )
            descriptions_tree.addObject( c.boundary( nodes ), c );
        
        
        
        //graph = new G;
    }
    
    static struct Road
    {
        private
        {
            Coords start;
            Coords end;
            
            size_t[] points_index;
        }
        
        cat.Road type = cat.Road.OTHER;
    }
}

/// Cuts roads on crossroads for creating road graph
private
auto prepareRoadGraph(DescriptionsTree, Coords)( in DescriptionsTree roads_rtree, in Coords[long] nodes )
{
    alias DescriptionsTree.Payload RoadDescription;
    alias Box!Coords BBox;
    
    RoadDescription[] res;
    auto all_roads = roads_rtree.search( roads_rtree.getBoundary );
    
    foreach( roadptr; all_roads )
    {
        RoadDescription road = *roadptr;
        
        for( auto i = 1; i < road.nodes_index.length - 1; i++ )
        {
            auto curr_point = road.nodes_index[i];
            auto point_bbox = BBox( nodes[ curr_point ], Coords(0, 0) );
            auto near_roads = roads_rtree.search( point_bbox );
            
            foreach( n; near_roads )
                if( n != roadptr && canFind( n.nodes_index, curr_point ) )
                {
                    res ~= road[ 0..i+1 ];
                    
                    road = road[ i..road.nodes_index.length ];
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
    
    auto prepared = prepareRoadGraph( roads, nodes );
    
    assert( prepared.length == 5 );
}
