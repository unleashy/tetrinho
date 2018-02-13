module tetrinho.spritesheet;

import std.exception,
       std.functional;

import tetrinho.graphics,
       tetrinho.util;

struct Spritesheet
{
    private TextureData tex_;
    private uint spriteSize_;

    this(ref Graphics graphics, in string resourceName, in uint spriteSize)
    {
        tex_ = graphics.loadResource(resourceName);
        enforce(
            (tex_.w % spriteSize == 0) && (tex_.h % spriteSize == 0),
            "spriteSize must be divisible by both the resource's width and height"
        );

        spriteSize_ = spriteSize;
    }

    void draw(ref Graphics graphics, in uint index, in Coord coords)
    {
        const src = rectForIndex(index);
        graphics.renderCopy(
            tex_.t,
            src,
            Rect(coords.tupleof, src.w, src.h)
        );
    }

    private Rect rectForIndex(in uint index) @safe @nogc const pure
    {
        immutable sx = index * spriteSize_;
        immutable sy = sx >= tex_.w ? (sx / tex_.w) * spriteSize_ : 0;
        return Rect(sx % tex_.w, sy, spriteSize_, spriteSize_);
    }
}
