module tetrinho.scoring;

import accessors;

import tetrinho.graphics,
       tetrinho.util;

struct Scoreboard
{
    static immutable uint[uint] SCORE_MAPPING;

    @ConstRead {
        private uint level_             = 1;
        private uint score_             = 0;
        private uint combo_             = 1;
        private uint totalLinesCleared_ = 0;
    }

    static this()
    {
        SCORE_MAPPING = [
            1: 100,
            2: 300,
            3: 500,
            4: 800
        ];
    }

    void lineClear(in uint linesCleared) @safe
    in
    {
        assert(linesCleared > 0 && linesCleared <= 4);
    }
    do
    {
        combo_ += linesCleared;
        score_ += SCORE_MAPPING[linesCleared] * level_;

        if (combo_ > 1) {
            score_ += 50 * combo_ * level_;
        }

        if (totalLinesCleared_ >= 5 * level_) {
            ++level_;
        }

        totalLinesCleared_ += linesCleared;
    }

    void resetCombo() @safe @nogc nothrow
    {
        combo_ = 1;
    }

    void draw(ref Graphics graphics) const
    {
        import std.format : format;

        static immutable LEVEL_TEXT_BG = Rect(5, 5, 245, 90);

        graphics.renderRect(Colors.BLACK, LEVEL_TEXT_BG);

        graphics.renderText("LEVEL", Coord(10, 5));
        graphics.renderText(format!"%02d"(level_), Coord(110, 5));

        graphics.renderText("SCORE", Coord(10, 35));
        graphics.renderText(format!"%08d"(score_), Coord(110, 35));

        graphics.renderText("COMBO", Coord(10, 65));
        graphics.renderText(format!"%dx"(combo_), Coord(110, 65));
    }
}
