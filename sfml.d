module sfml;

import dsfml.graphics;
import map;
import osm: Coords, decodeCoords;
import math.earth;
import math.geometry;
debug(sfml) import std.stdio;


class Window
{
    RenderWindow window;
    
    this()
    {
	auto vmode = VideoMode( 640, 480 );
	string title = "hello world!";
	
	window = new RenderWindow( vmode, title );
	
	window.setFramerateLimit(1);
	//window.setVerticalSyncEnabled(true);
    }
    
    void mainCycle()
    {
	while(window.isOpen)
	{
	    window.clear(Color.Black);
	    //showMap( region );
	    window.display();
     
	    Event event;
	    while (window.pollEvent(event))
	    {
		if (event.type == Event.Closed)
		    window.close();
		else
		if (event.type == Event.KeyPressed)
		{
		    if (event.key.code == Keyboard.Key.Escape)
			window.close();
		}
	    }
	}
    }
    
    void drawPoint( Vector2f coords )
    {
	debug(sfml) writeln("draw point at ", coords);
	
	auto r = new RectangleShape( Vector2f(1,1) );
	r.position( coords );
	r.fillColor(Color.Yellow);
	r.outlineColor(Color.Blue);
	r.outlineThickness(1);
	
	window.draw( r );
    }
    
    class ShowRegion
    {
	private Region region;
	
	this( Region r )
	{
	    region = r;
	}
	
	alias Coords2D!(WGS84, Vector2D!real) Vector2r;
	    
	Vector2r osm2meters( Coords coords )
	{
	    alias Vector2r C;
	    
	    auto c = decodeCoords( coords );
	    auto radians = C.degrees2radians( c );
	    return C.coords2mercator( radians );
	}
	
	auto meters2window( Vector2r coords, Coords mapStart, Vector2r k )
	{
	    auto res = coords - mapStart;
	    
	    res.x = res.x * k.x;
	    res.y = res.y * k.y;
	    
	    return res;
	}
	
	void drawRegion()
	{
	    auto b = region.boundary;
	    auto map_size = osm2meters( b.rightUpCorner - b.leftDownCorner );
	    auto k = Vector2r( window.size.x/map_size.x, window.size.y/map_size.y );
	    
	    
	    writeln("Start drawing, window size=", window.size);
	    auto len = region.getNodes.length;
	    for(auto i = 0; i < 1000 && i < len; i++)
	    {
		debug(sfml) writeln("i=", i);
		
		auto m = osm2meters( region.getNodes[i] );
		auto c = meters2window( m, b.leftDownCorner, k );
		drawPoint( Vector2f( c.x, c.y ) );
	    }
	}
    }
}
