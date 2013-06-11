module sfml;

import dsfml.system;
import dsfml.window;

import std.string;
import std.exception;


void init()
{
    VideoMode Mode = { width: 800, height: 600, bitsPerPixel: 32 };
    ContextSettings Settings = { depthBits: 24, stencilBits: 8, antialiasingLevel: 0 };
    
    auto window = RenderWindow(
        Mode,
        ("My window").toStringz,
        sfResize|sfClose,
        &Settings );
    
    // run the program as long as the window is open
    while (true)//window.isOpen)
    {
        // check all the window's events that were triggered since the last iteration of the loop
        sfEvent event;
        while ( sfRenderWindow_pollEvent(window, event) )
        {
            // "close requested" event: we close the window
            if (event.type == sfEventType.sfEvtClosed)
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
