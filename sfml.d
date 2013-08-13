module sfml;

import dsfml.graphics;
import scene;
import math.geometry;
import std.conv: to;
debug(sfml) import std.stdio;
debug(scene) import std.stdio;
debug(controls) import std.stdio;


struct Vector2f
{
    dsfml.graphics.Vector2f vector;
    
    this( float X, float Y )
    {
	vector = dsfml.graphics.Vector2f( X , Y );
    }
    
    alias vector this;
    
    void opAssign(T)( in T v )
    if( !isScalarType!(T) )
    {
	x = v.x;
	y = v.y;
    }
}

class Window
{
    POV scene;
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
		vertex_array = new VertexArray( PrimitiveType.Points, 0 );
		
		scene.calcBoundary( this );
		
		auto pois = scene.getPOIs();
		drawPOIs( pois );
		
		auto lines = scene.getLines();
		drawLines( lines );
		
		window.draw( vertex_array );
	    }
	    
	    drawCenter;
	    
	    window.display;
	}
    }
    
    private
    void drawPOIs( in Point[] poi )
    {
        for(auto i = 0; i < poi.length; i++)
        {
            Vector2r node = encodedToMeters( poi[i].coords );
            auto window_coords = scene.metersToScreen( node );
            
            debug(sfml) writeln("draw point i=", i, " encoded coords=", poi[i], " meters=", node, " window_coords=", window_coords);
            
	    Vector2f c; c = cartesianToSFML(window_coords );
	    vertex_array.append( Vertex(c, Color.Cyan) );
        }
    }
    
    private
    void drawLines( in Way[] lines )
    {
        foreach( line; lines )
        {
            Vector2r[]  line_points;
            
            foreach( i, node; line.nodes )
            {
                Vector2r point = encodedToMeters( node );
                auto window_coords = scene.metersToScreen( point );
                line_points ~= window_coords;

                debug(sfml) writeln("draw line point i=", i, " encoded coords=", point, " meters=", node, " window_coords=", window_coords);
            }
            
            drawLine( line_points, line.color );
        }
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
    
    private
    void drawLine( Vector2r[] coords, Color color )
    {
	debug(sfml) writeln("draw line, nodes num=", coords.length, " color=", color);
	
	auto line = new VertexArray( PrimitiveType.LinesStrip, coords.length );
	
	foreach( i, point; coords )
	{
	    Vector2f c; c = cartesianToSFML( point );
	    debug(sfml) writeln("draw line node, window coords=", c);
	    
	    line[i] = Vertex(c, color);
	}
	
	window.draw( line );
    }
        
    Vector2s getWindowSize()
    {
        Vector2s res; res = window.size;
	return res;
    }
    
    Vector2f getCenter()
    {
	Vector2f c;
	
	c = window.size;
	c /= 2;
	
	return c;
    }
    
    T cartesianToSFML( T )( ref T from )
    {
	from.y = to!real(window.size.y) - from.y;
	
	return from;
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
		    auto visibleArea = FloatRect(0, 0, event.size.width, event.size.height);
		    auto view = new View( visibleArea );
		    window.view( view );
		    
		    debug(controls)
			writeln("window size=", window.size);
			
		    break;
		
		case Event.KeyPressed:
		    immutable auto zoom_step = 1.05;
		    auto center = scene.getCenter;
		    auto zoom = scene.getZoom;
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
		    
		    scene.setZoom( zoom );
		    scene.setCenter( center );
		    break;
		    
		default:
		    break;
	    }
	}
    }
}
