module tetrinho.util;

import derelict.sdl2.sdl;

T enforceSDL(alias cmp = "a == 0", T)(T a, lazy string message = "SDL error: %s") @trusted
{
    import std.functional : unaryFun;
    import std.exception  : enforce;
    import std.format     : format;
    import std.string     : fromStringz;

    enforce(unaryFun!(cmp)(a), format(message, fromStringz(SDL_GetError())));

    return a;
}

