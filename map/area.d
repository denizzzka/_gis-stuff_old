module map.area;

import map.map: MapCoords, BBox;
import cat = config.categories: Line;
import config.map: polylines, PolylineProperties;


struct AreaLine
{
    MapCoords[] points;
    
    this( Description )( in Description areaLine )
    {
        foreach( i, ref unused; areaLine.nodes_ids )
            points ~= areaLine.getNode( i ).getCoords;
    }
    
    BBox getBoundary() const
    {
        auto res = BBox( points[0].map_coords, MapCoords.Coords(0,0) );
        
        for( auto i = 1; i < points.length; i++ )
            res.addCircumscribe( points[i].map_coords );
        
        return res;
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
    
    BBox getBoundary() const
    {
        return perimeter.getBoundary;
    }
    
    ref PolylineProperties properties() const
    {
        return polylines.getProperty( type );
    }
}
