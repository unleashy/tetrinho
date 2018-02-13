module tetrinho.graphics;

import std.conv,
       std.functional,
       std.string,
       std.typecons;

import derelict.sdl2.sdl,
       derelict.sdl2.image,
       derelict.sdl2.ttf,
       accessors;

import tetrinho.util;

enum WINDOW_WIDTH  = 500;
enum WINDOW_HEIGHT = 586;

alias TextureData = Tuple!(SDL_Texture*, "t", int, "w", int, "h");

struct Graphics
{
    private SDL_Window* window_;
    private SDL_Renderer* renderer_;
    private TTF_Font* mainFont_;
    private TextureData[string] textureCache_;

    static Graphics opCall()
    {
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

        immutable path = resourcePath(`VCR_OSD_MONO.ttf`).toStringz();
        g.mainFont_ = enforceSDL!"a !is null"(TTF_OpenFont(path, 30));

        return g;
    }

    ~this()
    {
        foreach (ref tex; textureCache_) {
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

    void renderCopy(SDL_Texture* tex, in Rect src)
    {
        enforceSDL(
            SDL_RenderCopy(
                renderer_,
                tex,
                null,
                &src
            )
        );
    }

    void renderCopy(SDL_Texture* tex, in Rect src, in Rect dst)
    {
        enforceSDL(
            SDL_RenderCopy(
                renderer_,
                tex,
                &dst,
                &src
            )
        );
    }

    void renderClear()
    {
        SDL_SetRenderDrawColor(renderer_, 60, 100, 175, SDL_ALPHA_OPAQUE);
        enforceSDL(SDL_RenderClear(renderer_));
    }

    TextureData loadResource(in string name)
    {
        return fetchCache(text("res$", name), () =>
            enforceSDL!"a !is null"(
                IMG_LoadTexture(renderer_, resourcePath(name).toStringz)
            )
        );
    }

    void renderText(in string text, in Coord coords)
    {
        auto tex = fetchText(text);
        renderCopy(tex.t, Rect(coords.x, coords.y, tex.w, tex.h));
    }

    // centers in rect
    void renderText(in string text, in Rect rect)
    {
        auto tex = fetchText(text);
        immutable coords = Coord(
            rect.x + ((rect.w - tex.w) / 2),
            rect.y + ((rect.h - tex.h) / 2)
        );

        renderCopy(tex.t, Rect(coords.x, coords.y, tex.w, tex.h));
    }

    private TextureData fetchText(in string t)
    {
        return fetchCache(text("text$", t), {
            auto sfc = enforceSDL!"a !is null"(
                TTF_RenderText_Blended(mainFont_, t.toStringz, Colors.WHITE)
            );
            scope(exit) SDL_FreeSurface(sfc);

            return enforceSDL!"a !is null"(
                SDL_CreateTextureFromSurface(renderer_, sfc)
            );
        });
    }

    private TextureData fetchCache(in string id, SDL_Texture* delegate() elseDg)
    {
        if (auto p = id in textureCache_) {
            return *p;
        }

        auto tex = elseDg();

        int texW = void, texH = void;
        enforceSDL(
            SDL_QueryTexture(tex, null, null, &texW, &texH)
        );

        return textureCache_[id] = TextureData(tex, texW, texH);
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

    mixin(GenerateFieldAccessors);
}
