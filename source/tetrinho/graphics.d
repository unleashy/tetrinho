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

    void renderCopy(SDL_Texture* tex, in Rect dst)
    {
        SDL_RenderCopy(
            renderer_,
            tex,
            null,
            &dst
        );
    }

    void renderCopy(SDL_Texture* tex, in Rect src, in Rect dst)
    {
        SDL_RenderCopy(
            renderer_,
            tex,
            &src,
            &dst
        );
    }

    void renderClear()
    {
        SDL_SetRenderDrawColor(renderer_, 60, 100, 175, SDL_ALPHA_OPAQUE);
        SDL_RenderClear(renderer_);
    }

    TextureData loadResource(in string name, in bool cached = true)
    {
        return fetchCache(name, &loadResourceUncached, !cached);
    }

    private SDL_Texture* loadResourceUncached(in string name)
    {
        return enforceSDL!"a !is null"(
            IMG_LoadTexture(renderer_, resourcePath(name).toStringz)
        );
    }

    void renderText(in string text, in Coord coords, in bool cached = true)
    {
        auto tex = fetchText(text, cached);
        renderCopy(tex.t, Rect(coords.x, coords.y, tex.w, tex.h));
    }

    // centers in rect
    void renderText(in string text, in Rect rect, in bool cached = true)
    {
        auto tex = fetchText(text, cached);
        immutable coords = Coord(
            rect.x + ((rect.w - tex.w) / 2),
            rect.y + ((rect.h - tex.h) / 2)
        );

        renderCopy(tex.t, Rect(coords.x, coords.y, tex.w, tex.h));
    }

    private TextureData fetchText(in string t, in bool cached = true)
    {
        return fetchCache(t, &renderTextUncached, !cached);
    }

    private SDL_Texture* renderTextUncached(in string t)
    {
        auto sfc = enforceSDL!"a !is null"(
            TTF_RenderText_Shaded(mainFont_, t.toStringz, Colors.WHITE, Colors.BLACK)
        );
        scope(exit) SDL_FreeSurface(sfc);

        return SDL_CreateTextureFromSurface(renderer_, sfc);
    }

    private TextureData fetchCache(
        in string id,
        SDL_Texture* delegate(string) elseDg,
        in bool force = false
    )
    {
        if (!force) {
            if (auto p = id in textureCache_) {
                return *p;
            }
        }

        auto tex = elseDg(id);

        int texW = void, texH = void;
        SDL_QueryTexture(tex, null, null, &texW, &texH);

        auto texd = TextureData(tex, texW, texH);
        if (force) {
            return texd;
        } else {
            return textureCache_[id] = texd;
        }
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
