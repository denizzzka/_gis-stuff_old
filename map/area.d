module map.area;

import map.map: MapCoords, BBox;
import cat = config.categories: Line;
import config.map: polylines, PolylineProperties;
static import math.reduce_points;

struct AreaProperties
{
    cat.Line type;
}

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
        auto res = BBox( points[0], MapCoords.Coords(0,0) );
        
        for( auto i = 1; i < points.length; i++ )
            res.addCircumscribe( points[i] );
        
        return res;
    }
    
    private
    void generalize( in real epsilon )
    {
        /// FIXME:
        //points = math.reduce_points.reduce( points, epsilon );
    }
}

struct Area
{
    AreaLine perimeter;
    AreaLine[] holes;
    
    AreaProperties _properties;
    
    this( Description )( in Description perimeter, in Description[] holes = null )
    {
        this.perimeter = AreaLine( perimeter );
        
        foreach( ref h; holes )
            this.holes ~= AreaLine( h );
            
        _properties = perimeter.properties;
    }
    
    BBox getBoundary() const
    {
        return perimeter.getBoundary;
    }
    
    ref PolylineProperties properties() const
    {
        return polylines.getProperty( _properties.type );
    }
    
    void generalize( in real epsilon )
    {
        perimeter.generalize( epsilon );
    }
}
