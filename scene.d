module scene;

import map;
import math.geometry;


class Scene
{
    Map map;
    
    alias Vector2D!real Vector2r;
    alias Vector2D!size_t Vector2s;
    
    Vector2s window_size;
    
    this( Map m, Vector2s pixelsSize )
    {
        map = m;
        
        window_size = pixelsSize;
    }
}
