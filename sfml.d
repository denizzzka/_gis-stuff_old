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
    Scene scene;
    RenderWindow window;    
    
    private
    {
	VertexArray vertices;
    }
    
    this()
    {
	auto vmode = VideoMode( 640, 480 );
	string title = "hello world!";
	
	window = new RenderWindow( vmode, title );
	
	window.setFramerateLimit(5);
	window.setVerticalSyncEnabled(true);
    }
    
    void mainCycle()
    {
	while(window.isOpen)
	{
	    window.clear(Color.Black);
	    
	    if( scene )
	    {
		scene.properties.windowPixelSize = window.size;
		vertices = new VertexArray( PrimitiveType.Points, 0 );
		scene.draw( &drawPoint );
		window.draw( vertices );
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
		    with(scene.properties)
		    {
			immutable auto zoom_step = 1.05;
			auto dir_step = zoom * 0.05;
			
			switch( event.key.code )
			{
			    case Keyboard.Key.Escape:
				window.close();
				break;
			    
			    case Keyboard.Key.Dash: // zoom out
				zoom *= zoom_step;
				debug(controls) writeln(scene);
				break;
			    
			    case Keyboard.Key.Equal: // zoom in
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
    }
    
    void drawPoint( Vector2r coords )
    {
	// convert Cartesian to SFML coords
	coords.y = to!real(window.size.y) - coords.y;
	
	auto c = Vector2f( coords.x, coords.y );
	
	debug(sfml) writeln("draw point, window coords=", c, " window size=", window.size);
	
	auto v = Vertex(c, Color.Yellow);
	
	vertices.append( v );
    }
}
