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
	VertexArray vertex_array;
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
		vertex_array = new VertexArray( PrimitiveType.Points, 0 );
		scene.draw( &drawPoint );
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
	
	vertex_array.append( Vertex(c, Color.Yellow) );
    }
    
    void drawCenter()
    {
	auto c = getCenter();
	
	auto horiz = Vector2f(8, 0);
	auto vert = Vector2f(0, 8);
	
	auto cross = new VertexArray( PrimitiveType.Lines, 4 );
	
	cross.append( Vertex(c-vert) );
	cross.append( Vertex(c+vert) );
	cross.append( Vertex(c-horiz) );
	cross.append( Vertex(c+horiz) );
	
	window.draw( cross );
    }
    
    Vector2f getCenter() const
    {
	Vector2f c;
	
	c = scene.properties.windowPixelSize;
	c /= 2;
	
	return c;
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
		    scene.properties.windowPixelSize = Vector2s( event.size.width, event.size.height );
		    
		    auto visibleArea = FloatRect(0, 0, event.size.width, event.size.height);
		    auto view = new View( visibleArea );
		    window.view( view );
		    
		    debug(controls)
		    {
			scene.calcBoundary();
			writeln(scene);
			writeln("window size=", window.size);
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
