module render.road;

import dsfml.graphics;
import cat = config.categories;


mixin template Road()
{
    void drawRoadBend( WindowCoords coords, cat.Line type )
    {
        auto sfml_coords = cartesianToSFML( coords );
    }
}
