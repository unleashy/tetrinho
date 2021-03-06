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

enum FontSize
{
    NORMAL,
    SMALL,
    TINY
}

struct Graphics
{
    private SDL_Window* window_;
    private SDL_Renderer* renderer_;
    private TTF_Font* mainFont_, smallFont_, tinyFont_;
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
        g.mainFont_  = enforceSDL!"a !is null"(TTF_OpenFont(path, 30));
        g.smallFont_ = enforceSDL!"a !is null"(TTF_OpenFont(path, 18));
        g.tinyFont_  = enforceSDL!"a !is null"(TTF_OpenFont(path, 15));

        return g;
    }

    ~this()
    {
        foreach (ref tex; textureCache_) {
            SDL_DestroyTexture(tex.t);
        }

        TTF_CloseFont(mainFont_);
        mainFont_ = null;

        TTF_CloseFont(smallFont_);
        smallFont_ = null;

        TTF_CloseFont(tinyFont_);
        tinyFont_ = null;

        SDL_DestroyRenderer(renderer_);
        renderer_ = null;

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

    void renderText(
        in string text,
        in Coord coords,
        in FontSize fontSize = FontSize.NORMAL,
        in Flag!"cached" cached = Yes.cached
    )
    {
        auto tex = fetchText(text, fontSize, cached);
        renderCopy(tex.t, Rect(coords.x, coords.y, tex.w, tex.h));
    }

    // centers in rect
    void renderText(
        in string text,
        in Rect rect,
        in FontSize fontSize = FontSize.NORMAL,
        in Flag!"cached" cached = Yes.cached
    )
    {
        auto tex = fetchText(text, fontSize, cached);
        immutable coords = Coord(
            rect.x + ((rect.w - tex.w) / 2),
            rect.y + ((rect.h - tex.h) / 2)
        );

        renderCopy(tex.t, Rect(coords.x, coords.y, tex.w, tex.h));
    }

    private TextureData fetchText(in string t, in FontSize fontSize, in bool cached)
    {
        return fetchCache(
            t,
            (string t) {
                auto sfc = enforceSDL!"a !is null"(
                    TTF_RenderText_Blended(
                        fontForSize(fontSize),
                        t.toStringz,
                        Colors.WHITE
                    )
                );
                scope(exit) SDL_FreeSurface(sfc);

                return SDL_CreateTextureFromSurface(renderer_, sfc);
            },
            !cached
        );
    }

    private TTF_Font* fontForSize(in FontSize fontSize) @safe @nogc nothrow pure
    {
        final switch (fontSize) with (FontSize) {
            case NORMAL: return mainFont_;
            case SMALL: return smallFont_;
            case TINY: return tinyFont_;
        }
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

    void blend(SDL_Texture* tex)
    {
        SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_BLEND);
    }

    void blend(SDL_Texture* tex, in ubyte alpha)
    {
        blend(tex);
        SDL_SetTextureAlphaMod(tex, alpha);
    }

    void unblend()
    {
        SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_NONE);
    }

    void unblend(SDL_Texture* tex)
    {
        SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_NONE);
    }

    void destroyTexture(in string str)
    {
        if (auto p = str in textureCache_) {
            SDL_DestroyTexture(p.t);
            textureCache_.remove(str);
        }
    }

    mixin(GenerateFieldAccessors);
}
