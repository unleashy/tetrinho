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
    Coord coords;
    bool inFormation;

    this(in Color c, in Coord crds, in bool inF) @safe @nogc
    {
        color       = c;
        coords      = crds;
        inFormation = inF;
    }

    void draw(ref Graphics graphics, in Coord modifier) const
    {
        graphics.renderRect(
            color,
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
