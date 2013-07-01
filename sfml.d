module sfml;

import dsfml.graphics;
import scene;
import math.earth;
import math.geometry;
debug(sfml) import std.stdio;
debug(scene) import std.stdio;


class Window
{
    RenderWindow window;
    Scene scene;
    real k; // zoom
    Vector2D!real center;
    Vector2D!real map_size;
    
    this()
    {
	auto vmode = VideoMode( 640, 480 );
	string title = "hello world!";
	
	window = new RenderWindow( vmode, title );
	
	//window.setFramerateLimit(5);
	window.setVerticalSyncEnabled(true);
    }
    
    void mainCycle()
    {
	while(window.isOpen)
	{
	    window.clear(Color.Black);
	    
	    if( scene )
		scene.draw( &drawPoint );
		
	    window.display;
     
	    Event event;
	    while (window.pollEvent(event))
	    {
		if (event.type == Event.Closed)
		    window.close();
		else
		if (event.type == Event.KeyPressed)
		{
		    switch( event.key.code )
		    {
			case Keyboard.Key.Escape:
			    window.close();
			    break;
			    
			case Keyboard.Key.P:
			    k += 0.001;
			    debug(scene) writeln("k=", k);
			    break;
			    
			case Keyboard.Key.O:
			    k -= 0.001;
			    debug(scene) writeln("k=", k);
			    break;
			    
			case Keyboard.Key.Right:
			    center.x += 0.001;
			    debug(scene) writeln("center=", center);
			    break;
			    
			case Keyboard.Key.Left:
			    center.x -= 0.001;
			    debug(scene) writeln("center=", center);
			    break;
			    
			case Keyboard.Key.Up:
			    center.y += 0.001;
			    debug(scene) writeln("center=", center);
			    break;
			    
			case Keyboard.Key.Down:
			    center.y -= 0.001;
			    debug(scene) writeln("center=", center);
			    break;
			    
			default:
			    break;
		    }
		}
	    }
	}
    }
    
    void drawPoint( Vector2r coords )
    {
	debug(sfml) writeln("draw point at ", coords);
	
	coords.y = -coords.y + window.size.y; // convert Cartesian to SFML coords
	
	auto c = Vector2f( coords.x, coords.y );
	
	auto r = new RectangleShape( Vector2f(1,1) );
	r.position( c );
	r.fillColor(Color.Yellow);
	//r.outlineColor(Color.Blue);
	//r.outlineThickness(0.1);
	
	window.draw( r );
    }
}
