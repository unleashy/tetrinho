module tetrinho.config;

import derelict.sdl2.sdl,
       sdlang;

import tetrinho.util;

struct Config
{
    struct Input
    {
        SDL_Scancode right      = SDL_SCANCODE_RIGHT;
        SDL_Scancode left       = SDL_SCANCODE_LEFT;
        SDL_Scancode rotateCCW  = SDL_SCANCODE_Z;
        SDL_Scancode rotateCW   = SDL_SCANCODE_X;
        SDL_Scancode softDrop   = SDL_SCANCODE_DOWN;
        SDL_Scancode hardDrop   = SDL_SCANCODE_SPACE;
        SDL_Scancode pause      = SDL_SCANCODE_P;
        SDL_Scancode restart    = SDL_SCANCODE_R;
        SDL_Scancode highscores = SDL_SCANCODE_H;
        SDL_Scancode quit       = SDL_SCANCODE_ESCAPE;
    }

    Input input;
    bool ghostPiece = true;

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
            mixin(inputLoad!("right",      "RIGHT"));
            mixin(inputLoad!("left",       "LEFT"));
            mixin(inputLoad!("rotateCCW",  "Z"));
            mixin(inputLoad!("rotateCW",   "X"));
            mixin(inputLoad!("softDrop",   "DOWN"));
            mixin(inputLoad!("hardDrop",   "SPACE"));
            mixin(inputLoad!("pause",      "P"));
            mixin(inputLoad!("restart",    "R"));
            mixin(inputLoad!("highscores", "H"));
            mixin(inputLoad!("quit",       "ESCAPE"));
        }

        ghostPiece = rootTag.getTagValue!bool("ghostPiece", true);
    }
}
