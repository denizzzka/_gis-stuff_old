module map.area;

import map.map: Coords;


struct AreaLine
{
    Coords[] points;
    
    this( Description )( Description areaLine )
    {
        foreach( i, ref unused; areaLine.nodes_ids )
            points ~= areaLine.getNode( i ).getCoords;
    }
}

struct Area
{
    AreaLine perimeter;
    AreaLine[] holes;
    
    this( Description )( in Description perimeter, in Description[] holes )
    {
        perimeter = AreaLine( perimeter );
        
        foreach( ref h; holes )
            this.hole ~= AreaLine( h );
    }
}
