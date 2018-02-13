module tetrinho.playfield;

import std.algorithm,
       std.typecons;

import tetrinho.util,
       tetrinho.block,
       tetrinho.graphics;

enum ROWS    = 24;
enum COLS    = 10;
enum BLK_QTY = ROWS * COLS;

enum BOARD_X      = 255;
enum BOARD_Y      = 5;
enum BOARD_WIDTH  = WINDOW_WIDTH - BOARD_X - 5;
enum BOARD_HEIGHT = WINDOW_HEIGHT - 10;

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

    alias LineData = Tuple!(uint[], "rows", Block[], "blocks");

    LineData findLines() @safe
    {
        import std.range : iota;
        import std.array : appender, array;

        auto ybuf = appender!(uint[]);
        ybuf.reserve(4);

        auto bbuf = appender!(Block[]);
        bbuf.reserve(COLS * 4);

        foreach (y; iota(0, ROWS)) {
            auto ln = field_.filter!(b => b !is null && b.coords.y == y).array;
            if (ln.length == COLS) {
                ybuf ~= y;
                bbuf ~= ln;
            }
        }

        return LineData(ybuf.data, bbuf.data);
    }

    void gravityFrom(in uint y, in uint dy) @safe
    {
        field_.filter!(b => b !is null && !b.inPiece && b.coords.y < (ROWS - 1) && b.coords.y <= y)
              .each!(b => b.coords.y += dy);
    }

    void draw(ref Graphics graphics) const
    {
        import derelict.sdl2.sdl : SDL_BLENDMODE_BLEND;

        static immutable BOARD_COORD = Coord(BOARD_X, BOARD_Y);

        // Board background
        graphics.renderRect(
            Color(0, 0, 0),
            Rect(BOARD_X, BOARD_Y, BOARD_WIDTH, BOARD_HEIGHT)
        );

        // Blocks
        foreach (const ref block; field_) {
            if (block !is null) {
                block.draw(graphics, BOARD_COORD);
            }
        }

        // Grid
        graphics.setRenderStyle(Color(255, 255, 255, 15), SDL_BLENDMODE_BLEND);

        foreach (const ref i; 0 .. ROWS) {
            immutable yc = i * BLK_WIDTH + BOARD_Y;
            graphics.renderLine(
                Coord(BOARD_X, yc),
                Coord(COLS * BLK_WIDTH + (BOARD_X - 1), yc)
            );
        }

        foreach (const ref i; 0 .. COLS) {
            immutable xc = i * BLK_HEIGHT + BOARD_X;
            graphics.renderLine(
                Coord(xc, BOARD_Y),
                Coord(xc, ROWS * BLK_HEIGHT + (BOARD_Y - 1))
            );
        }
    }

    void build(in string pat) @trusted
    {
        import std.range : iota, lockstep, retro;
        import std.array : appender;

        auto fieldAppender = appender(field_);
        auto lines = pat.splitter('\n').retro();

        foreach (line, row; lockstep(lines, iota(ROWS - 1, -1, -1))) {
            fieldAppender.reserve(line.length);

            foreach (block, col; lockstep(line, iota(0, COLS))) {
                final switch (block) {
                    case '#':
                        fieldAppender ~= new Block(Colors.CYAN, Coord(col, row), false);
                        break;

                    case ' ':
                        // space, ignore
                        break;
                }
            }
        }

        field_ = fieldAppender.data;
    }

    int opApply(scope int delegate(ref Block) dg) @trusted
    {
        int result = 0;

        foreach (ref block; field_) {
            if (block !is null) {
                result = dg(block);
                if (result) {
                    break;
                }
            }
        }

        return result;
    }
}
