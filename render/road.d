module render.road;

import dsfml.graphics;
import cat = config.categories;
import config.map: PolylineProperties, polylines;


mixin template Road()
{
    void drawRoadBend( WindowCoords center, cat.Line type )
    {
        auto prop = &polylines.getProperty( type );
        
        auto radius = prop.thickness / 2;
        
        Vector2f sfml_coords; sfml_coords = cartesianToSFML( center );
        
        sfml_coords.x -= radius;
        sfml_coords.y -= radius;
        
        auto circle = new CircleShape;
        
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
        
        rect.position = sfml_from;
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
