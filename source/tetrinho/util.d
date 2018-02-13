module tetrinho.util;

import derelict.sdl2.sdl;

import std.exception,
       std.file,
       std.format,
       std.functional,
       std.path,
       std.typecons;

alias Coord = SDL_Point;
alias Rect  = SDL_Rect;
alias Color = SDL_Color;

enum Colors : Color
{
    CYAN   = Color(  0, 255, 255, SDL_ALPHA_OPAQUE),
    BLUE   = Color(  0,   0, 255, SDL_ALPHA_OPAQUE),
    ORANGE = Color(255, 165,   0, SDL_ALPHA_OPAQUE),
    YELLOW = Color(255, 255,   0, SDL_ALPHA_OPAQUE),
    GREEN  = Color(  0, 255,   0, SDL_ALPHA_OPAQUE),
    PURPLE = Color(128,   0, 128, SDL_ALPHA_OPAQUE),
    RED    = Color(255,   0,   0, SDL_ALPHA_OPAQUE),
    GRAY   = Color(128, 128, 128, SDL_ALPHA_OPAQUE),
    BLACK  = Color(  0,   0,   0, SDL_ALPHA_OPAQUE),
    WHITE  = Color(255, 255, 255, SDL_ALPHA_OPAQUE),
}

bool isInside(in Coord c, in Rect r) @trusted @nogc
{
    return SDL_PointInRect(&c, &r);
}

T enforceSDL(alias cmp = "a == 0", T)(T a, lazy string message = "SDL error: %s") @trusted
{
    import std.string : fromStringz;

    enforce(unaryFun!(cmp)(a), format(message, fromStringz(SDL_GetError())));

    return a;
}

T deepCopy(T : U[][], U)(ref T src) @safe
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

alias resourcesDir = memoize!(() @safe {
    auto path = buildNormalizedPath(dirName(thisExePath()), "res");
    enforce(exists(path), "The resources directory could not be found.");

    return path;
});

alias resourcePath = memoize!((string name) @safe {
    import std.conv : text;

    auto path = buildNormalizedPath(resourcesDir, name);
    enforce(exists(path), text("The resource ", name, " could not be found."));

    return path;
});
