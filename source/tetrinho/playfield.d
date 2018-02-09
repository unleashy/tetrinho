module tetrinho.playfield;

import tetrinho.block;

enum ROWS    = 24;
enum COLS    = 10;
enum BLK_QTY = ROWS * COLS;

struct Playfield
{
    private Block[] field_;

    static Playfield opCall() @safe
    {
        Playfield p;

        p.field_.reserve(BLK_QTY);

        return p;
    }

    @safe @nogc invariant
    {
        assert(field_.length < BLK_QTY);
    }

    void add(Block[] block) @safe
    {
        field_ ~= block;
    }

    bool remove(in Block[] blocks) @trusted
    {
        import std.algorithm : remove, SwapStrategy, canFind;

        bool anyRemoved;

        if (blocks.length != 0) {
            field_ = field_.remove!(
                (Block b) {
                    if (b is null) {
                        return true;
                    } else if (blocks.canFind(b)) {
                        return anyRemoved = true;
                    }

                    return false;
                },
                SwapStrategy.unstable
            );
        }

        return anyRemoved;
    }
}
