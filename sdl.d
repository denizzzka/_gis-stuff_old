module sdl;

import derelict.sdl2.sdl;
import std.exception;

void init()
{
    DerelictSDL2.load();
    enforce( SDL_Init(SDL_INIT_EVERYTHING) == -1 );
    
    
    
    /*    
    main_loop:
        while(true)
        {
            SDL_WaitEvent(&event);
            switch(event.type)
            {
                case SDL_QUIT:
                    break main_loop;
                    break;
                    
                default:
                    break;
            } 
        }
    */
}
