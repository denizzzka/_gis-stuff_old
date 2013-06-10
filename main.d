module main;

import osm;
import std.getopt;
import derelict.sdl2.sdl;


void main( string[] args )
{
    string filename;
    bool verbose;
    
    getopt(
        args,
        "verbose", &verbose,
        "osmpbf", &filename,
    );
    
    DerelictSDL2.load();
    /*
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Surface* SDL_GetWindowSurface(SDL_Window* window);
    */
    SDL_Event event;
    
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
    
    getRegionMap( filename, verbose );
}
