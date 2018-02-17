module tetrinho.config;

import derelict.sdl2.sdl,
       sdlang;

import tetrinho.util;

struct Config
{
    struct Input
    {
        SDL_Scancode right     = SDL_SCANCODE_RIGHT;
        SDL_Scancode left      = SDL_SCANCODE_LEFT;
        SDL_Scancode rotateCCW = SDL_SCANCODE_Z;
        SDL_Scancode rotateCW  = SDL_SCANCODE_X;
        SDL_Scancode softDrop  = SDL_SCANCODE_DOWN;
        SDL_Scancode hardDrop  = SDL_SCANCODE_SPACE;
        SDL_Scancode pause     = SDL_SCANCODE_P;
        SDL_Scancode quit      = SDL_SCANCODE_ESCAPE;
    }

    Input input;

    this(in string filename)
    {
        load(filename);
    }

    void load(in string filename)
    {
        import std.string : toStringz;

        enum inputLoad(string n, string d) =
            `input.` ~ n ~ ` = SDL_GetScancodeFromName(` ~
                `inputTag.getTagValue!string("` ~ n ~ `", "` ~ d ~ `").toStringz` ~
            `);`;

        auto rootTag = parseFile(filename);

        if (auto inputTag = rootTag.getTag("input")) {
            mixin(inputLoad!("right",     "RIGHT"));
            mixin(inputLoad!("left",      "LEFT"));
            mixin(inputLoad!("rotateCCW", "Z"));
            mixin(inputLoad!("rotateCW",  "X"));
            mixin(inputLoad!("softDrop",  "DOWN"));
            mixin(inputLoad!("hardDrop",  "SPACE"));
            mixin(inputLoad!("pause",     "P"));
            mixin(inputLoad!("quit",      "ESCAPE"));
        }
    }
}
