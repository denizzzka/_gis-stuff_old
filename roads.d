import math.graph;
import osm: Coords;
import cat = categories: Road;


alias Graph!( DNP, long, float ) G;

class RoadGraph
{
    private G graph;
    
    this()
    {
        //graph = new G;
    }
    
    static struct RoadDescription
    {
        Coords points[];
        
        cat.Road type = cat.Road.OTHER;
    }
        
    
    static struct Road
    {
        Coords start;
        Coords end;
        
        Coords points[];
    }
    
    void addRoad( RoadDescription road )
    {
        
    }
}
