module render.window;

import math.geometry;
import dsfml.graphics: Color;


alias Vector2D!uint Vector2uint;
alias Vector2D!(real, "Window coords") WindowCoords;

interface IWindow
{
    Vector2uint getSize();
    
    /*
    void drawPoint( Vector2r coords, Color color );
    
    void drawArea( Vector2r[] coords, Color color );
    
    void drawRoad( Vector2r[] coords, Color color );
    */
    
    void drawRoadBend( WindowCoords coords, Color color );
}
