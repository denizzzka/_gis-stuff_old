module sfml;

import dsfml.system;
import dsfml.window;
import dsfml.graphics;

import std.string;
import std.exception;


void init()
{
    auto Mode = VideoMode( 800, 600 );
    
    auto window = new RenderWindow(
        Mode,
        "My window"c,
        Window.Style.Resize | Window.Style.Close );
    
    // run the program as long as the window is open
    while( window.isOpen )
    {
        // check all the window's events that were triggered since the last iteration of the loop
        Event event;
        while ( window.pollEvent(event) )
        {
            // "close requested" event: we close the window
            if (event.type == Event.Closed)
                window.close();
        }

        // clear the window with black color
        window.clear(Color.Black);

        // draw everything here...
        // window.draw(...);

        // end the current frame
        window.display();
    }
}
