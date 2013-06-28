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
    }
    
    //void showMap( Region region )
    
    void mainCycle( Region region )
    {
	while(window.isOpen)
	{
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
}
