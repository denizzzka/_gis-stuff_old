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
        rect.rotation = angleOX.radian2degree - 90;
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
    
    void drawRoad( in RoadGraph g, in RoadGraph.EdgeDescr road )
    {
        const type = g.getEdge( road ).payload.type;
        const prop = &polylines.getProperty( type );
        
        auto map_coords = g.getMapCoords( road );
        auto cartesian = MapToWindowCoords( map_coords );
        auto coords = cartesianToSFML( cartesian );
        
        drawOneColoredRoad( coords, prop.outlineThickness, prop.outlineColor );
    }
    
    void drawRoadBend( WindowCoords center, cat.Line type )
    {
        auto prop = &polylines.getProperty( type );
        
        auto radius = prop.thickness / 2;
        
        Vector2f sfml_coords; sfml_coords = cartesianToSFML( center );
        
        auto circle = new CircleShape;
        
        circle.origin = Vector2f( radius, radius );
        circle.radius = radius;
        circle.outlineThickness = prop.outlineThickness;
        circle.fillColor = prop.color;
        circle.outlineColor = prop.outlineColor;
        circle.position = sfml_coords;
        
        window.draw( circle );
    }
    
    private
    void drawRoadSegment( WindowCoords from, WindowCoords to, PolylineProperties* prop )
    {
        auto vector = to - from;
        auto length = vector.length;
        auto angleOX = vector.angleOX;
        
        Vector2f sfml_from;
        sfml_from = cartesianToSFML( from );
        
        auto rect = new RectangleShape;
        
        rect.origin = Vector2f( 0, prop.thickness / 2 );
        rect.position = sfml_from;
        rect.rotation = angleOX.radian2degree - 90;
        rect.size = Vector2f( length, prop.thickness );
        rect.outlineThickness = prop.outlineThickness;
        rect.fillColor = prop.color;
        rect.outlineColor = prop.outlineColor;
        
        window.draw( rect );
    }
    
    void drawRoadSegments( WindowCoords[] coords, cat.Line type )
    in
    {
        assert( coords.length >= 2 );
    }
    body
    {
        auto prop = &polylines.getProperty( type );
        
        auto prev = coords[0];
        
        for( auto i = 1; i < coords.length; i++ )
        {
            drawRoadSegment( prev, coords[i], prop );
            prev = coords[i];
        }
    }
}
