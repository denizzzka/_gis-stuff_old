module sfml;

import dsfml.graphics;


class Window
{
    RenderWindow window;
    
    this()
    {
	auto vmode = VideoMode( 640, 480 );
	string title = "hello world!";
	
	window = new RenderWindow( vmode, title );
    }
}
