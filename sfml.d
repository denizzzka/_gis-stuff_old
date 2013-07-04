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
	Vertex[] vertices;
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
		vertices.destroy;
		scene.draw( &drawPoint );
		auto vertex_array = new VertexArray( PrimitiveType.Points, vertices );
		window.draw( vertex_array );
	    }
	    
	    drawCenter;
	    
	    window.display;
	}
    }
    
    void drawPoint( Vector2r coords )
    {
	// convert Cartesian to SFML coords
	coords.y = to!real(window.size.y) - coords.y;
	
	auto c = Vector2f( coords.x, coords.y );
	
	debug(sfml) writeln("draw point, window coords=", c, " window size=", window.size);
	
	vertices ~= Vertex(c, Color.Yellow);
    }
    
    void drawCenter()
    {
	auto c = Vector2f(320,240); // c = getCenter();
	
	auto horiz = Vector2f(8, 0);
	auto vert = Vector2f(0, 8);
	
	auto cross = new VertexArray( PrimitiveType.Lines, 4 );
	
	cross.append( Vertex(c-vert) );
	cross.append( Vertex(c+vert) );
	cross.append( Vertex(c-horiz) );
	cross.append( Vertex(c+horiz) );
	
	window.draw( cross );
    }
    
    Vector2r getCenter()
    {
	Vector2r res;
	res = window.size;
	res /= 2;
	return res;
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
		    scene.properties.windowPixelSize = window.size;
		    
		    debug(controls)
		    {
			scene.calcBoundary();
			writeln(scene);
			writeln("window size=", window.size, " window center=", getCenter);
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
