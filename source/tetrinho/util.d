module tetrinho.util;

import derelict.sdl2.sdl;

import std.typecons;

alias Coord = Tuple!(int, "x", int, "y");
alias Color = Tuple!(ubyte, "r", ubyte, "b", ubyte, "g");

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

T enforceSDL(alias cmp = "a == 0", T)(T a, lazy string message = "SDL error: %s") @trusted
{
    import std.functional : unaryFun;
    import std.exception  : enforce;
    import std.format     : format;
    import std.string     : fromStringz;

    enforce(unaryFun!(cmp)(a), format(message, fromStringz(SDL_GetError())));

    return a;
}

