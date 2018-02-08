import std.stdio;

import derelict.sdl2.sdl,
       derelict.sdl2.ttf;

import tetrinho.util,
       tetrinho.game;

void main()
{
    DerelictSDL2.load();
    DerelictSDL2TTF.load();

    enforceSDL(SDL_Init(SDL_INIT_VIDEO));
    scope(exit) SDL_Quit();

    enforceSDL(TTF_Init());
    scope(exit) TTF_Quit();


}
