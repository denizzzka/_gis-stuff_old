module sfml;

import dsfml.graphics;
import map;


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
	    showMap( region );
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
    
    void showMap( Region region )
    {
	auto r = new RectangleShape( Vector2f(100,100) );
	r.position( Vector2f(50,50) );
	r.fillColor(Color.Yellow);
	r.outlineColor(Color.Blue);
	r.outlineThickness(3);
	
	window.draw( r );
    }
}
