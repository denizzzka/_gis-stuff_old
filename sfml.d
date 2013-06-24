module sfml;

import dsfml.window;
import dsfml.graphics;

import std.exception;


void init()
{
    auto vmode = VideoMode( 640, 480 );
    ContextSettings settings = { depthBits: 24 };
    
    string title = "hello world!";
    
    auto screen = new RenderWindow(
	vmode,
	title,
	Window.Style.DefaultStyle,
	settings
    );
    
    /*
    auto font = new Font("arial.ttf");
    auto text = new Text();
    text.font = font;
    text.string = "Hello world";
    text.color = sfBlue;
    text.position = sfVector2f(10,10);
    
    sfEvent ev;
    
    while(screen.isOpen)
    {
	while(screen.pollEvent(&ev))
	{
	    if(ev.type == sfEvtClosed)
	    screen.close();
	}
	
	screen.clear(sfBlack);
	screen.draw(text, null);			
	screen.display();
    }
    */
}
