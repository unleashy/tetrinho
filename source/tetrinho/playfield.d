module tetrinho.playfield;

import tetrinho.util,
       tetrinho.block,
       tetrinho.graphics;

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

    void draw(ref Graphics graphics) const
    {
        import derelict.sdl2.sdl : SDL_BLENDMODE_BLEND;

        enum BOARD_X      = 255;
        enum BOARD_Y      = 5;
        enum BOARD_WIDTH  = WINDOW_WIDTH - BOARD_X - 5;
        enum BOARD_HEIGHT = WINDOW_HEIGHT - 10;
        enum BLK_WIDTH    = BOARD_WIDTH / COLS;
        enum BLK_HEIGHT   = BOARD_HEIGHT / ROWS;

        // Board background
        graphics.renderRect(
            Color(0, 0, 0),
            Rect(BOARD_X, BOARD_Y, BOARD_WIDTH, BOARD_HEIGHT)
        );

        // Blocks
        foreach (const block; field_) {
            if (block !is null) {
                graphics.renderRect(
                    block.color,
                    Rect(
                        cast(int) (block.coords.x * BLK_WIDTH + BOARD_X),
                        cast(int) (block.coords.y * BLK_HEIGHT + BOARD_Y),
                        BLK_WIDTH,
                        BLK_HEIGHT
                    )
                );
            }
        }

        // Grid
        graphics.setRenderStyle(Color(255, 255, 255, 15), SDL_BLENDMODE_BLEND);

        foreach (const i; 0 .. ROWS) {
            immutable yc = i * BLK_WIDTH + BOARD_Y;
            graphics.renderLine(
                Coord(BOARD_X, yc),
                Coord(COLS * BLK_WIDTH + (BOARD_X - 1), yc)
            );
        }

        foreach (const i; 0 .. COLS) {
            immutable xc = i * BLK_HEIGHT + BOARD_X;
            graphics.renderLine(
                Coord(xc, BOARD_Y),
                Coord(xc, ROWS * BLK_HEIGHT + (BOARD_Y - 1))
            );
        }
    }
}
