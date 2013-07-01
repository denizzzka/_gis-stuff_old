module sfml;

import dsfml.graphics;
import map;
import osm: Coords, decodeCoords, osm2meters;
import math.earth;
import math.geometry;
debug(sfml) import std.stdio;
debug(scene) import std.stdio;


class Window
{
    RenderWindow window;
    ShowRegion reg;
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
	    
	    if( reg )
		reg.drawRegion;
		
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
    
    void drawPoint( Vector2f coords )
    {
	debug(sfml) writeln("draw point at ", coords);
	
	coords.y = -coords.y + window.size.y; // convert Cartesian to SFML coords
	
	auto r = new RectangleShape( Vector2f(1,1) );
	r.position( coords );
	r.fillColor(Color.Yellow);
	//r.outlineColor(Color.Blue);
	//r.outlineThickness(0.1);
	
	window.draw( r );
    }
    
    class ShowRegion
    {
	private Region region;
	    
	this( Region r )
	{
	    region = r;
	    
	    auto b = region.boundary;
	    map_size = osm2meters( b.rightUpCorner - b.leftDownCorner );
	    center = map_size / 2;
	    k = window.size.x/map_size.x;
	}
	
	alias Vector2D!real Vector2r;
		
	auto meters2window( Vector2r coords ) pure
	{
	    auto res = coords - center; 
	    
	    res.x = res.x * Window.k;
	    res.y = res.y * Window.k;
	    
	    return res;
	}
	
	void drawRegion()
	{
	    auto b = region.boundary;	    
	    auto map_start = osm2meters( b.leftDownCorner );
	    
	    debug(sfml) writeln("Start drawing, window size=", window.size);
	    auto len = region.getNodes.length;
	    for(auto i = 0; i < 1000 && i < len; i++)
	    {
		debug(sfml) writeln("i=", i);
		
		auto m = osm2meters( region.getNodes[i] );
		auto c = meters2window( m );
		drawPoint( Vector2f( c.x, c.y ) );
	    }
	}
    }
}
