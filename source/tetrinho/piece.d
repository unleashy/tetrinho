module tetrinho.piece;

import std.stdio;

import accessors;

import tetrinho.util,
       tetrinho.block,
       tetrinho.rotation,
       tetrinho.playfield;

enum RotationStyle
{
    NONE,
    NORMAL,
    I_PIECE
}

struct Piece
{
    immutable Color color;
    immutable RotationStyle rotationStyle;

    @ConstRead {
        private Coord coord_;
        private bool[][] blockLayout_;
        private Block[4] blocks_;
    }

    private RotationState curRotSt_;
    private immutable RotationTable rotationTable_;

    this(in Color clr, bool[][] blockLayout, in RotationStyle rs = RotationStyle.NORMAL) @safe
    {
        color = clr;
        blockLayout_ = blockLayout;
        blocks_ = [
            new Block(clr, Coord(0, 0), true),
            new Block(clr, Coord(0, 0), true),
            new Block(clr, Coord(0, 0), true),
            new Block(clr, Coord(0, 0), true)
        ];
        rotationStyle = rs;

        if (rotationStyle == RotationStyle.NORMAL) {
            rotationTable_ = rotationTableNormal;
        } else {
            rotationTable_ = rotationTableI;
        }

        injectLayout();
    }

    ~this() @safe @nogc nothrow pure
    {}

    void detachBlocks() @safe
    {
        foreach (ref blk; blocks_) {
            if (blk !is null) {
                blk.inPiece = false;
            }
        }
    }

    void spawnPiece(ref Playfield p) @safe
    {
        p.add(blocks_);
    }

    bool move(bool checkCollisions = true)(in Coord d, ref Playfield p) @safe
    {
        coord_.x += d.x;
        coord_.y += d.y;

        injectLayout();

        static if (checkCollisions) {
            if (anyCollision(p)) {
                coord_.x -= d.x;
                coord_.y -= d.y;

                injectLayout();

                return false;
            }
        }

        updateGhost(p);
        return true;
    }

    void rotateRight(ref Playfield p) @trusted
    {
        if (rotationStyle != RotationStyle.NONE) {
            rotate!(RotationState.RIGHT_ROT)(p);
        }
    }

    void rotateLeft(ref Playfield p) @trusted
    {
        if (rotationStyle != RotationStyle.NONE) {
            rotate!(RotationState.LEFT_ROT)(p);
        }
    }

    private void rotate(RotationState rot)(ref Playfield p) @safe
        if (rot == RotationState.RIGHT_ROT || rot == RotationState.LEFT_ROT)
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
                    static if (rot == RotationState.RIGHT_ROT) {
                        immutable newLy = lx;
                        immutable newLx = xlen - 1 - ly;
                    } else {
                        immutable newLy = ylen - 1 - lx;
                        immutable newLx = ly;
                    }

                    tmpLayout[newLy][newLx] = true;
                }
            }
        }

        auto savedLayout = blockLayout_.deepCopy();
        blockLayout_ = tmpLayout;

        injectLayout();

        if (anyCollision(p)) {
            if (!tryKick!(rot)(p)) {
                // Rollback!
                blockLayout_ = savedLayout;
                injectLayout();
                return;
            }
        } else {
            curRotSt_ = calculateKey!rot(curRotSt_).to;
        }

        updateGhost(p);
    }

    private bool tryKick(RotationState rot)(ref Playfield p) @trusted
    {
        auto key = calculateKey!rot(curRotSt_);

        foreach (const d; rotationTable_[key]) {
            if (move(d, p)) {
                curRotSt_ = key.to;
                return true;
            }
        }

        return false;
    }

    bool anyCollision(ref Playfield p) @safe
    {
        foreach (ref const block; blocks_) {
            if (!block.coords.isInside(PLAYFIELD_RECT)) {
                return true;
            }

            foreach (ref const fblock; p) {
                if (block !is fblock && block.coords == fblock.coords) {
                    return true;
                }
            }
        }

        return false;
    }

    bool floating(ref Playfield p) @safe
    {
        static immutable TEST_DELTA     = Coord(0, 1);
        static immutable ROLLBACK_DELTA = Coord(0, -1);

        if (move(TEST_DELTA, p)) {
            move!false(ROLLBACK_DELTA, p);
            return true;
        }

        return false;
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

                    blocks_[i].ghost.x = coord_.x + lx;

                    ++i;
                }
            }
        }
    }

    private void updateGhost(ref Playfield p) @safe
    {
        uint ghostY = coord_.y;

        bool ghostCollision() {
            foreach (ref const block; blocks_) {
                if (!block.ghost.isInside(PLAYFIELD_RECT)) {
                    return true;
                }

                foreach (ref const fblock; p) {
                    if (!fblock.inPiece && block.ghost == fblock.coords) {
                        return true;
                    }
                }
            }

            return false;
        }

        void ghostInject() {
            size_t i;

            foreach (const ly, const row; blockLayout_) {
                foreach (const lx, const hasBlock; row) {
                    if (hasBlock) {
                        blocks_[i].ghost.y = ghostY + ly;

                        ++i;
                    }
                }
            }
        }

        while (true) {
            ++ghostY;
            ghostInject();

            if (ghostCollision() && ghostY > 0) {
                do {
                    --ghostY;
                    ghostInject();
                } while (ghostCollision());

                break;
            }
        }
    }

    mixin(GenerateFieldAccessors);
}

// This is a bunch of heap-allocated Pieces because I can't shuffle an array
// of straight up Pieces because I can't swap straight up Pieces because it
// has an immutable member.
private Piece*[7] defaultPieces_;

static this() @safe
{
    defaultPieces_ = [
        /* I piece */
        new Piece(
            Colors.CYAN,
            [[0, 0, 0, 0],
            [1, 1, 1, 1],
            [0, 0, 0, 0],
            [0, 0, 0, 0]],
            RotationStyle.I_PIECE
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
            [1, 1]],
            RotationStyle.NONE
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
}

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
    Piece tmpl = *(pieceBag_.front);
    return Piece(tmpl.color, tmpl.blockLayout_, tmpl.rotationStyle);
}
