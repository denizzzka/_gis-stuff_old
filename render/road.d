module render.road;

import dsfml.graphics;
import cat = config.categories;
import config.map: PolylineProperties, polylines;
import map.map: RoadGraph;


mixin template Road()
{
    void drawRoadJointPoint( Vector2F center, in float diameter, in Color color )
    {
        auto radius = diameter / 2;
        
        auto circle = new CircleShape;
        
        circle.origin = Vector2f( radius, radius );
        circle.position = Vector2f( center );
        circle.radius = radius;
        circle.fillColor = color;
        
        window.draw( circle );
    }
    
    void drawPoints( Vector2F[] coords, in float width, in Color color )
    {
        foreach( c; coords )
            drawRoadJointPoint( c, width, color );
    }
    
    void drawRoadSegmentLine( Vector2F from, Vector2F to, in float width, in Color color )
    {
        auto vector = to - from;
        auto length = vector.length;
        auto angleOX = vector.angleOX;
        
        auto rect = new RectangleShape;
        
        rect.origin = Vector2f( 0, width / 2 );
        rect.position = Vector2f( from );
        rect.rotation = -angleOX.radian2degree + 90;
        rect.size = Vector2f( length, width );
        rect.fillColor = color;
        
        window.draw( rect );
    }
    
    void drawRoadSegments( Vector2F[] coords, in float width, in Color color )
    in
    {
        assert( coords.length >= 2 );
    }
    body
    {
        auto prev = coords[0];
        
        for( auto i = 1; i < coords.length; i++ )
        {
            drawRoadSegmentLine( prev, coords[i], width, color );
            prev = coords[i];
        }
    }
    
    void forAllRoads( SfmlRoad[] roads, bool foreground,
            void delegate( Vector2F[] coords, in float width, in Color color ) dg
        )
    {
        foreach( ref r; roads )
        {
            const props = &polylines.getProperty( r.props.type );
            
            float width;
            Color color;
            
            if( foreground )
            {
                width = props.thickness;
                color = props.color;
            }
            else
            {
                width = props.thickness + props.outlineThickness;
                color = props.outlineColor;
            }
            
            dg( r.coords, width, color );
        }
    }
    
    void drawRoadsLayer( SfmlRoad[] roads )
    {
        // background lines
        forAllRoads( roads, false, &drawRoadSegments );
        
        // background points
        forAllRoads( roads, false, &drawPoints );
        
        // foreground lines
        forAllRoads( roads, true, &drawRoadSegments );
        
        // foreground points
        forAllRoads( roads, true, &drawPoints );
    }
    
    void drawRoads( RoadsSorted sorted )
    {
        foreach( layer; sorted.roads )
            drawRoadsLayer( layer );
    }
}
