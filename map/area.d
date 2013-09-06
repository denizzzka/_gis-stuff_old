module map.area;

import map.map: Coords;
import cat = config.categories: Line;


struct AreaLine
{
    Coords[] points;
    
    this( Description )( in Description areaLine )
    {
        foreach( i, ref unused; areaLine.nodes_ids )
            points ~= areaLine.getNode( i ).getCoords;
    }
}

struct Area
{
    AreaLine perimeter;
    AreaLine[] holes;
    
    cat.Line type;
    
    this( Description )( in Description perimeter, in cat.Line type, in Description[] holes = null )
    {
        this.perimeter = AreaLine( perimeter );
        
        foreach( ref h; holes )
            this.holes ~= AreaLine( h );
            
        this.type = type;
    }
}
