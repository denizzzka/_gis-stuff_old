module render.road;

import dsfml.graphics;
import cat = config.categories;
import config.map: polylines;


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
}
