module sfml;

import dsfml.graphics;
import scene;
import math.geometry;
import std.conv: to;
debug(sfml) import std.stdio;
debug(scene) import std.stdio;
debug(controls) import std.stdio;


class Window
{
    RenderWindow window;
    Scene scene;
    
    this()
    {
	auto vmode = VideoMode( 640, 480 );
	string title = "hello world!";
	
	window = new RenderWindow( vmode, title );
	
	window.setFramerateLimit(30);
	//window.setVerticalSyncEnabled(true);
    }
    
    void mainCycle()
    {
	while(window.isOpen)
	{
	    window.clear(Color.Black);
	    
	    if( scene )
	    {
		scene.properties.windowPixelSize = window.size;
		scene.draw( &drawPoint );
	    }
	    
	    window.display;
     
	    Event event;
	    while (window.pollEvent(event))
	    {
		if (event.type == Event.Closed)
		    window.close();
		else
		if (event.type == Event.KeyPressed)
		{
		    immutable auto zoom_step = 1.05;
		    immutable auto dir_step = 0.1;
		    
		    with(scene.properties)
			switch( event.key.code )
			{
			    case Keyboard.Key.Escape:
				window.close();
				break;
			    
			    case Keyboard.Key.P:
				zoom *= zoom_step;
				debug(controls) writeln(scene);
				break;
			    
			    case Keyboard.Key.O:
				zoom /= zoom_step;
				debug(controls) writeln(scene);
				break;
				
			    case Keyboard.Key.Right:
				center.x += dir_step;
				debug(controls) writeln(scene);
				break;
				
			    case Keyboard.Key.Left:
				center.x -= dir_step;
				debug(controls) writeln(scene);
				break;
				
			    case Keyboard.Key.Up:
				center.y += dir_step;
				debug(controls) writeln(scene);
				break;
				
			    case Keyboard.Key.Down:
				center.y -= dir_step;
				debug(controls) writeln(scene);
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
	// convert Cartesian to SFML coords
	//coords.y = to!real(window.size.y) - coords.y;
	
	debug(sfml) writeln("draw point, window coords=", coords, " window size=", window.size);
	
	auto c = Vector2f( coords.x, coords.y );
	
	auto r = new RectangleShape( Vector2f(1,1) );
	r.position( c );
	r.fillColor(Color.Yellow);
	//r.outlineColor(Color.Blue);
	//r.outlineThickness(0.1);
	
	window.draw( r );
    }
}
