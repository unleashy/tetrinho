module tetrinho.block;

import accessors;

import tetrinho.graphics,
       tetrinho.playfield,
       tetrinho.spritesheet,
       tetrinho.util;

import derelict.sdl2.sdl;

enum BLK_WIDTH  = BOARD_WIDTH / COLS;
enum BLK_HEIGHT = BOARD_HEIGHT / ROWS;

// Blocks are classes so that i don't have to use Block* or Nullable!Block
// everywhere since I expect these to be nullable.
final class Block
{
    private static Spritesheet* spritesheet_;

    immutable Color color;
    Coord coords;
    Coord ghost;
    bool inPiece;

    private uint index_;

    this(in Color c, in Coord crds, in bool inP) @safe @nogc
    {
        color       = c;
        coords      = crds;
        inPiece     = inP;

        index_ = indexForColor(c);
    }

    private uint indexForColor(in Color c) @safe @nogc
    {
        import std.traits : EnumMembers;

        foreach (i, clr; EnumMembers!Colors) {
            if (c == clr) {
                return i;
            }
        }

        assert(false, "given color is not a Colors member");
    }

    void draw(ref Graphics graphics, in Coord modifier, in bool drawGhost = true) const
    {
        if (spritesheet_ is null) {
            spritesheet_ = new Spritesheet(graphics, "blocks.png", BLK_WIDTH);
        }

        scope(exit) graphics.unblend(spritesheet_.tex.t);

        if (inPiece) {
            if (drawGhost && ghost != coords) {
                graphics.blend(spritesheet_.tex.t, 255);

                spritesheet_.draw(
                    graphics,
                    7,
                    Coord(
                        cast(int) (ghost.x * BLK_WIDTH + modifier.x),
                        cast(int) (ghost.y * BLK_HEIGHT + modifier.y)
                    )
                );
            }
        } else {
            graphics.blend(spritesheet_.tex.t, 195);
        }

        spritesheet_.draw(
            graphics,
            index_,
            Coord(
                cast(int) (coords.x * BLK_WIDTH + modifier.x),
                cast(int) (coords.y * BLK_HEIGHT + modifier.y)
            )
        );
    }

    mixin(GenerateFieldAccessors);
}
