module tetrinho.piece;

import accessors;

import tetrinho.util,
       tetrinho.block,
       tetrinho.playfield;

struct Piece
{
    immutable Color color;

    @ConstRead
    private Coord coord_;

    @ConstRead
    private bool[][] blockLayout_;

    private Block[4] blocks_;

    this(in Color clr, bool[][] blockLayout) @safe
    {
        color = clr;
        blockLayout_ = blockLayout;
    }

    ~this() @safe
    {
        foreach (blk; blocks_) {
            if (blk !is null) {
                blk.inFormation = false;
            }
        }
    }

    void spawnPiece(ref Playfield p) @safe
    {
        p.add(blocks_);
    }
}
