import math.graph;
import osm: Coords;

alias Graph!( DNP, long, float ) G;

class RoadGraph
{
    
    
    static struct Road
    {
        Coords start;
        Coords end;
        
        Coords points[];
    }
}
