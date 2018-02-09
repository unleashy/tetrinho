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
        blocks_ = [
            new Block(clr, Coord(0, 0), true),
            new Block(clr, Coord(0, 0), true),
            new Block(clr, Coord(0, 0), true),
            new Block(clr, Coord(0, 0), true)
        ];

        injectLayout();
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

    void move(in Coord d) @safe
    {
        coord_.x += d.x;
        coord_.y += d.y;

        injectLayout();
    }

    private void injectLayout() @safe
    {
        size_t i;

        foreach (const ly, const row; blockLayout_) {
            foreach (const lx, const hasBlock; row) {
                if (hasBlock) {
                    blocks_[i].coords.x = coord_.x + lx;
                    blocks_[i].coords.y = coord_.y + ly;

                    ++i;
                }
            }
        }
    }
}
