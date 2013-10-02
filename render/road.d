module render.road;

import dsfml.graphics;
import cat = config.categories;
import config.map: PolylineProperties, polylines;
import map.region.region: RoadGraph;


mixin template Road()
{
    void drawRoadJointPoint( inout Vector2F center, inout DrawProperties props )
    {
        auto radius = props.width / 2;
        
        auto circle = new CircleShape;
        
        circle.origin = Vector2f( radius, radius );
        circle.position = Vector2f( center );
        circle.radius = radius;
        circle.fillColor = props.color;
        circle.pointCount = 15;
        
        window.draw( circle );
    }
    
    void drawPointsBetween( inout Vector2F[] coords, inout DrawProperties props )
    {
       for( auto i = 1; i < coords.length-1; i++ )
            drawRoadJointPoint( coords[i], props );
    }
    
    void drawEndPoints( inout SfmlRoad road, bool foreground )
    {
        const DrawProperties props = getDrawProperties( road.props.type, foreground );
        
        drawRoadJointPoint( road.coords[0], props );
        drawRoadJointPoint( road.coords[$-1], props );
    }
    
    void drawRoadSegmentLine( inout Vector2F from, inout Vector2F to, inout DrawProperties props )
    {
        auto vector = to - from;
        auto length = vector.length;
        auto angleOX = vector.angleOX;
        
        auto degrees = -angleOX.radian2degree + 90;
        degrees = degrees % 360;
        
        auto rect = new RectangleShape;
        
        rect.origin = Vector2f( 0, props.width / 2 );
        rect.position = Vector2f( from );
        rect.rotation = degrees;
        rect.size = Vector2f( length, props.width );
        rect.fillColor = props.color;
        
        window.draw( rect );
    }
    
    void drawRoadSegments( inout Vector2F[] coords, inout DrawProperties props )
    in
    {
        assert( coords.length >= 2 );
    }
    body
    {
        Vector2F prev = coords[0];
        
        for( auto i = 1; i < coords.length; i++ )
        {
            drawRoadSegmentLine( prev, coords[i], props );
            prev = coords[i];
        }
    }
    
    void forLayer( SfmlRoad[][20] layer, bool foreground,
            void delegate( inout SfmlRoad road, bool foreground ) dg
        )
    {
        foreach_reverse( roads_by_type; layer )
            foreach( ref r; roads_by_type )
                dg( r, foreground );
    }
    
    void drawRoad( inout SfmlRoad road, bool foreground )
    {
        const DrawProperties props = getDrawProperties( road.props.type, foreground );
        
        drawPointsBetween( road.coords, props );
        drawRoadSegments( road.coords, props );
    }
    
    struct DrawProperties
    {
        float width;
        Color color;
    }
    
    DrawProperties getDrawProperties( cat.Line type, bool foreground )
    {
        auto props = &polylines.getProperty( type );
        
        DrawProperties res;
        
        if( foreground )
        {
            res.width = props.thickness;
            res.color = props.color;
        }
        else
        {
            res.width = props.thickness + props.outlineThickness;
            res.color = props.outlineColor;
        }
        
        return res;
    }
    
    void drawRoads( RoadsSorted roads )
    {
        foreach( i, layer; roads.sorted )
        {
            // background
            forLayer( layer, false, &drawRoad );
            
            // background end points for first level
            if( i == 0 )
                forLayer( layer, false, &drawEndPoints );
                
            // background end points for next layer
            if( i < roads.sorted.length-1 )
                forLayer( roads.sorted[i+1], false, &drawEndPoints );
                
            // foreground
            forLayer( layer, true, &drawRoad );
            
            // foreground end points
            forLayer( layer, true, &drawEndPoints );
        }
    }
}
