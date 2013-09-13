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
    
    void drawOneColoredRoad( Vector2F[] coords, in float width, in Color color )
    {
        drawRoadSegments( coords, width, color );
        
        foreach( c; coords )
            drawRoadJointPoint( c, width, color );
    }
    
    struct RoadDrawProperties
    {
        float thickness;
        float outlineThickness;
        Color color;
        Color outlineColor;
    }
    
    void drawRoad( in RoadGraph g, in RoadGraph.EdgeDescr road, in RoadDrawProperties prop )
    {
        auto map_coords = g.getMapCoords( road );
        WindowCoords[] cartesian = MapToWindowCoords( map_coords );
        auto coords = cartesianToSFML( cartesian );
        
        drawOneColoredRoad( coords, prop.outlineThickness, prop.outlineColor );
        drawOneColoredRoad( coords, prop.thickness, prop.color );
    }
    
    void drawRoad( in RoadGraph g, in RoadGraph.EdgeDescr road )
    {
        const type = g.getEdge( road ).payload.type;
        const prop = &polylines.getProperty( type );
        
        RoadDrawProperties drawProps = {
            thickness: prop.thickness,
            outlineThickness: prop.outlineThickness,
            color: prop.color,
            outlineColor: prop.outlineColor
        };
        
        drawRoad( g, road, drawProps );
    }
    
    void drawPathSegment( in RoadGraph g, in RoadGraph.EdgeDescr road )
    {
        const prop = &polylines.getProperty( cat.Line.PATH );
        
        RoadDrawProperties drawProps = {
            thickness: prop.thickness,
            outlineThickness: prop.outlineThickness,
            color: prop.color,
            outlineColor: prop.outlineColor
        };
        
        drawRoad( g, road, drawProps );
    }    
}
