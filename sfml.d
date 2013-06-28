module sfml;

import dsfml.graphics;
import map;
import osm: Coords;
import math.earth;
import math.geometry;


class Window
{
    RenderWindow window;
    
    this()
    {
	auto vmode = VideoMode( 640, 480 );
	string title = "hello world!";
	
	window = new RenderWindow( vmode, title );
	
	window.setFramerateLimit(10);
	window.setVerticalSyncEnabled(true);
    }
    
    void mainCycle( Region region )
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
    
    void showPoint( Vector2f coords )
    {
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
	
	Vector2f calcPointPosition( Coords coords )
	{
	    alias Coords2D!(WGS84, Vector2D!real) C;
	    
	    auto k = C( 320.0/coords.x, 240.0/coords.y ); 
	    auto mercator = C.coords2mercator( C.degrees2radians( coords ) );
	    
	    return Vector2f( k.x * mercator.x,  k.y * mercator.y );
	}
	
	void drawRegion()
	{
	    foreach( i, c; region.getNodes )
		showPoint( calcPointPosition( c ) );
	}
    }
}
