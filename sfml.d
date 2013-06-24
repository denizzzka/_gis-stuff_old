module sfml;

import dsfml.graphics;


void init()
{
    auto vmode = VideoMode( 640, 480 );
    string title = "hello world!";
    
    auto screen = new RenderWindow( vmode, title );
}
