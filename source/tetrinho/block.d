module tetrinho.block;

import accessors;

import tetrinho.graphics,
       tetrinho.playfield,
       tetrinho.util;

enum BLK_WIDTH  = BOARD_WIDTH / COLS;
enum BLK_HEIGHT = BOARD_HEIGHT / ROWS;

// Blocks are classes so that i don't have to use Block* or Nullable!Block
// everywhere since I expect these to be nullable.
final class Block
{
    immutable Color color;
    immutable Color lockedColor;
    Coord coords;
    bool inPiece;

    this(in Color c, in Coord crds, in bool inP) @safe @nogc
    {
        color       = c;
        coords      = crds;
        inPiece     = inP;
        lockedColor = Color(c.r, c.g, c.b, 195);
    }

    void draw(ref Graphics graphics, in Coord modifier) const
    {
        Color clr = void;
        if (inPiece) {
            clr = color;
        } else {
            clr = lockedColor;
            graphics.blend();
        }

        graphics.renderRect(
            clr,
            Rect(
                cast(int) (coords.x * BLK_WIDTH + modifier.x),
                cast(int) (coords.y * BLK_HEIGHT + modifier.y),
                BLK_WIDTH,
                BLK_HEIGHT
            )
        );
    }

    mixin(GenerateFieldAccessors);
}
