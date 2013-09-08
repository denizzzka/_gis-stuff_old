module render.road;

import dsfml.graphics;
import cat = config.categories;
import config.map: polylines;


mixin template Road()
{
    void drawRoadBend( WindowCoords coords, cat.Line type )
    {
        Vector2f sfml_coords; sfml_coords = cartesianToSFML( coords );
        
        auto property = &polylines.getProperty( type );
        
        auto circle = new CircleShape;
        
        circle.radius = property.thickness / 2;
        circle.outlineThickness = property.outlineThickness;
        circle.fillColor = property.color;
        circle.position = sfml_coords;
        
        window.draw( circle );
    }
}
