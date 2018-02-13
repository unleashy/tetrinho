module tetrinho.graphics;

import std.typecons,
       std.string;

import derelict.sdl2.sdl,
       derelict.sdl2.ttf,
       accessors;

import tetrinho.util;

enum WINDOW_WIDTH  = 500;
enum WINDOW_HEIGHT = 586;

struct Graphics
{
    private alias TextCacheVal = Tuple!(SDL_Texture*, "t", int, "w", int, "h");

    private SDL_Window* window_;
    private SDL_Renderer* renderer_;
    private TTF_Font* mainFont_;
    private TextCacheVal[string] textTexsCache_;

    static Graphics opCall()
    {
        import std.file : thisExePath;
        import std.path : dirName, buildPath;

        Graphics g;

        g.window_ = enforceSDL!"a !is null"(
            SDL_CreateWindow(
                "Tetris",
                SDL_WINDOWPOS_CENTERED,
                SDL_WINDOWPOS_CENTERED,
                WINDOW_WIDTH,
                WINDOW_HEIGHT,
                cast(SDL_WindowFlags) 0
            )
        );

        g.renderer_ = enforceSDL!"a !is null"(
            SDL_CreateRenderer(g.window_, -1, cast(SDL_RendererFlags) 0)
        );

        immutable path = buildPath(dirName(thisExePath()), `VCR_OSD_MONO.ttf`).toStringz;
        g.mainFont_ = enforceSDL!"a !is null"(TTF_OpenFont(path, 30));

        return g;
    }

    ~this()
    {
        foreach (ref tex; textTexsCache_) {
            SDL_DestroyTexture(tex.t);
        }

        TTF_CloseFont(mainFont_);
        mainFont_ = null;

        SDL_DestroyRenderer(renderer_);
        renderer_ = null;

        SDL_DestroyWindow(window_);
        window_ = null;
    }

    void renderPresent()
    {
        SDL_RenderPresent(renderer_);
    }

    void renderClear()
    {
        setRenderClearColor();
        enforceSDL(SDL_RenderClear(renderer_));
    }

    void renderText(in string text, in Coord coords)
    {
        auto tex = fetchText(text);

        renderTextDirect(tex.t, Rect(coords.x, coords.y, tex.w, tex.h));
    }

    // centers in rect
    void renderText(in string text, in Rect rect)
    {
        int textW = void, textH = void;
        TTF_SizeText(mainFont_, text.toStringz, &textW, &textH);

        immutable coords = Coord(
            rect.x + ((rect.w - textW) / 2),
            rect.y + ((rect.h - textH) / 2)
        );

        renderText(text, coords);
    }

    private TextCacheVal fetchText(in string text)
    {
        TextCacheVal tex = void;
        if (auto ptr = text in textTexsCache_) {
            tex = *ptr;
        } else {
            auto sfc = enforceSDL!"a !is null"(
                TTF_RenderText_Blended(mainFont_, text.toStringz, Colors.WHITE)
            );
            scope(exit) SDL_FreeSurface(sfc);

            auto texT = enforceSDL!"a !is null"(
                SDL_CreateTextureFromSurface(renderer_, sfc)
            );

            int texW = void, texH = void;
            enforceSDL(
                SDL_QueryTexture(texT, null, null, &texW, &texH)
            );

            tex = TextCacheVal(texT, texW, texH);
            textTexsCache_[text] = tex;
        }

        return tex;
    }

    private void renderTextDirect(SDL_Texture* tex, in Rect rect)
    {
        enforceSDL(
            SDL_RenderCopy(
                renderer_,
                tex,
                null,
                &rect
            )
        );
    }

    void renderRect(Color color, in Rect rect)
    {
        // if alpha is zero, change it to SDL_ALPHA_OPAQUE;
        // we'll never want to draw a fully transparent thing
        if (color.a == 0) {
            color.a = SDL_ALPHA_OPAQUE;
        }

        SDL_SetRenderDrawColor(renderer_, color.tupleof);
        SDL_RenderFillRect(renderer_, &rect);
    }

    void renderLine(in Coord start, in Coord end)
    {
        SDL_RenderDrawLine(renderer_, start.tupleof, end.tupleof);
    }

    void setRenderStyle(Color color, in SDL_BlendMode blendMode = SDL_BLENDMODE_NONE)
    {
        // if alpha is zero, change it to SDL_ALPHA_OPAQUE;
        // we'll never want to draw a fully transparent thing
        if (color.a == 0) {
            color.a = SDL_ALPHA_OPAQUE;
        }

        SDL_SetRenderDrawColor(renderer_, color.tupleof);
        SDL_SetRenderDrawBlendMode(renderer_, blendMode);
    }

    void blend()
    {
        SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_BLEND);
    }

    private void setRenderClearColor()
    {
        SDL_SetRenderDrawColor(renderer_, 60, 100, 175, SDL_ALPHA_OPAQUE);
    }

    mixin(GenerateFieldAccessors);
}
