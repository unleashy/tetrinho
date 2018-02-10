module tetrinho.util;

import derelict.sdl2.sdl;

import std.typecons;

alias Coord = SDL_Point;
alias Rect  = SDL_Rect;
alias Color = SDL_Color;

enum Colors : Color
{
    CYAN   = Color(  0, 255, 255),
    BLUE   = Color(  0,   0, 255),
    ORANGE = Color(255, 165,   0),
    YELLOW = Color(255, 255,   0),
    GREEN  = Color(  0, 255,   0),
    PURPLE = Color(128,   0, 128),
    RED    = Color(255,   0,   0)
}

bool isInside(in Coord c, in Rect r) @trusted @nogc
{
    return SDL_PointInRect(&c, &r);
}

T enforceSDL(alias cmp = "a == 0", T)(T a, lazy string message = "SDL error: %s") @trusted
{
    import std.functional : unaryFun;
    import std.exception  : enforce;
    import std.format     : format;
    import std.string     : fromStringz;

    enforce(unaryFun!(cmp)(a), format(message, fromStringz(SDL_GetError())));

    return a;
}

T deepCopy(U, T : U[][])(ref T src)
{
    import std.algorithm.mutation : copy;

    T dest;

    dest.length = src.length;
    foreach (const i, ref e; src) {
        dest[i].length = e.length;
        e.copy(dest[i]);
    }

    return dest;
}
