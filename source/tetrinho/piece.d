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

    void rotateRight() @safe
    {
        rotate!(true);
    }

    void rotateLeft() @safe
    {
        rotate!(false);
    }

    private void rotate(bool ccw)() @trusted
    {
        immutable ylen = blockLayout_.length;
        immutable xlen = blockLayout_[0].length;

        bool[][] tmpLayout;
        tmpLayout.length = ylen;
        foreach (const i; 0 .. ylen) {
            tmpLayout[i].length = xlen;
        }

        foreach (const ly, const row; blockLayout_) {
            foreach (const lx, const hasBlock; row) {
                if (hasBlock) {
                    static if (ccw) {
                        immutable newLy = xlen - 1 - lx;
                    } else {
                        immutable newLy = ylen - 1 - lx;
                    }

                    immutable newLx = ly;
                    tmpLayout[newLy][newLx] = true;
                }
            }
        }

        blockLayout_ = tmpLayout;
        injectLayout();
    }

    void center(in int n) @safe
    {
        immutable k = blockLayout_[0].length;

        coord_.x = (n - k) / 2;
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

// This is a bunch of heap-allocated Pieces because I can't shuffle an array
// of straight up Pieces because I can't swap straight up Pieces because it
// has an immutable member.
private static Piece*[7] defaultPieces_ = [
    /* I piece */
    new Piece(
        Colors.CYAN,
        [[0, 0, 0, 0],
         [1, 1, 1, 1],
         [0, 0, 0, 0],
         [0, 0, 0, 0]]
    ),

    /* J piece */
    new Piece(
        Colors.BLUE,
        [[1, 0, 0],
         [1, 1, 1],
         [0, 0, 0]]
    ),

    /* L piece */
    new Piece(
        Colors.ORANGE,
        [[0, 0, 1],
         [1, 1, 1],
         [0, 0, 0]]
    ),

    /* O piece */
    new Piece(
        Colors.YELLOW,
        [[1, 1],
         [1, 1]]
    ),

    /* S piece */
    new Piece(
        Colors.GREEN,
        [[0, 1, 1],
         [1, 1, 0],
         [0, 0, 0]]
    ),

    /* T piece */
    new Piece(
        Colors.PURPLE,
        [[0, 1, 0],
         [1, 1, 1],
         [0, 0, 0]]
    ),

    /* Z piece */
    new Piece(
        Colors.RED,
        [[1, 1, 0],
         [0, 1, 1],
         [0, 0, 0]]
    ),
];

Piece generateNewPiece() @safe
{
    import std.random           : randomShuffle;
    import std.range.primitives : empty, popFront, front;

    static Piece*[] pieceBag_;

    if (pieceBag_.empty) {
        pieceBag_ = defaultPieces_[];
        randomShuffle(pieceBag_);
    }

    scope(exit) pieceBag_.popFront();
    return *(pieceBag_.front);
}
