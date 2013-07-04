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
	Vertex[5_000] vertices;
	size_t vertices_num;
    }
    
    this()
    {
	auto vmode = VideoMode( 640, 480 );
	string title = "hello world!";
	
	window = new RenderWindow( vmode, title );
	
	window.setFramerateLimit(10);
	//window.setVerticalSyncEnabled(true);
    }
    
    void mainCycle()
    {
	while(window.isOpen)
	{
	    eventsProcessing();
	    
	    window.clear(Color.Black);
	    
	    if( scene )
	    {
		scene.properties.windowPixelSize = window.size;
		vertices_num = 0;
		scene.draw( &drawPoint );
		auto vertex_array = new VertexArray( PrimitiveType.Points, vertices[0..vertices_num] );
		window.draw( vertex_array );
	    }
	    
	    window.display;
	}
    }
    
    void drawPoint( Vector2r coords )
    {
	// convert Cartesian to SFML coords
	coords.y = to!real(window.size.y) - coords.y;
	
	auto c = Vector2f( coords.x, coords.y );
	
	debug(sfml) writeln("draw point, window coords=", c, " window size=", window.size);
	
	vertices[vertices_num] = Vertex(c, Color.Yellow);
	vertices_num++;
    }
    
    private void eventsProcessing()
    {
	Event event;
	while (window.pollEvent(event))
	{
	    switch( event.type )
	    {
		case Event.Closed:
		    window.close();
		    break;
		    
		case Event.Resized:
		    debug(controls)
		    {
			scene.calcBoundary();
			writeln(scene);
		    }
		    break;
		
		case Event.KeyPressed:
		    with(scene.properties)
		    {
			immutable auto zoom_step = 1.05;
			auto dir_step = 10.0 / zoom;
			
			switch( event.key.code )
			{
			    case Keyboard.Key.Escape:
				window.close();
				break;
			    
			    case Keyboard.Key.Equal: // zoom in
				zoom *= zoom_step;
				debug(controls) writeln(scene);
				break;
			    
			    case Keyboard.Key.Dash: // zoom out
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
		    break;
		    
		default:
		    break;
	    }
	}
    }
}
