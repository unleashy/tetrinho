module tetrinho.util;

import derelict.sdl2.sdl;

import std.exception,
       std.datetime.systime,
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

string truncate(in string what, in size_t len, in string dots = "...") @safe
{
    if (what.length > len) {
        return what[0 .. (len - dots.length)] ~ dots;
    }

    return what;
}

string agoString(in SysTime time) @safe
{
    import std.conv : text;

    enum difOut(string name) =
        `if (dif == 1) {
            return "1 ` ~ name ~ ` ago";
        } else {
            return text(dif, " ` ~ name ~ `s ago");
        }`;

    immutable curTime = Clock.currTime();

    // Years and months testing
    if (time > curTime) {
        return "FUUUUTURE!"; // sponge bob memes
    } else if (time == curTime) {
        return "just now"; // this will probably never happen but
    } else if (auto dif = curTime.year - time.year) {
        // neat trick in the condition: if dif == 0, its the same year;
        // 0 autoconverts to false, ignoring this, which is what we want!

        // do this manually due to exception in branching
        if (dif == 1) {
            return "1 yr ago";
        } else if (dif >= curTime.year) {
            return "many yrs ago";
        } else {
            return text(dif, " yrs ago");
        }
    } else if (auto dif = curTime.month - time.month) {
        // same trick
        mixin(difOut!"month");
    }

    // deal with duration normally
    immutable difs = (curTime - time).split();

    if (auto dif = difs.weeks) {
        mixin(difOut!"week");
    } else if (auto dif = difs.days) {
        mixin(difOut!"day");
    } else if (auto dif = difs.hours) {
        mixin(difOut!"hour");
    } else if (auto dif = difs.minutes) {
        mixin(difOut!"min");
    } else if (auto dif = difs.seconds) {
        if (dif > 5) {
            return text(dif, " secs ago");
        }
    }

    return "just now";
}
