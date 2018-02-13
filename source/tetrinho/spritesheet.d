module tetrinho.spritesheet;

import std.exception,
       std.functional;

import tetrinho.graphics,
       tetrinho.util;

struct Spritesheet
{
    TextureData tex;
    uint spriteSize;

    this(ref Graphics graphics, in string resourceName, in uint spriteSz)
    {
        tex = graphics.loadResource(resourceName);
        enforce(
            (tex.w % spriteSz == 0) && (tex.h % spriteSz == 0),
            "spriteSize must be divisible by both the resource's width and height"
        );

        spriteSize = spriteSz;
    }

    void draw(ref Graphics graphics, in uint index, in Coord coords)
    {
        immutable src = rectForIndex(index);
        graphics.renderCopy(
            tex.t,
            src,
            Rect(coords.x, coords.y, src.w, src.h)
        );
    }

    private Rect rectForIndex(in uint index) @safe @nogc const pure
    {
        immutable sx = index * spriteSize;
        immutable sy = sx >= tex.w ? (sx / tex.w) * spriteSize : 0;
        return Rect(sx % tex.w, sy, spriteSize, spriteSize);
    }
}
