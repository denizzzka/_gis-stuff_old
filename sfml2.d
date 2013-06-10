module sfml2;

import derelict.sfml2.graphics;
import derelict.sfml2.window;
//import derelict.sfml2.system;

import std.exception;

void init()
{
    sfVideoMode Mode = {800,600,32}; 
    sfRenderWindow* window = sfRenderWindow_create( Mode, "My window", null, null );
    
    // run the program as long as the window is open
    while (sfRenderWindow_IsOpened(window))
    {
        // check all the window's events that were triggered since the last iteration of the loop
        sfEvent event;
        while (window.pollEvent(event))
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
