module tetrinho.scoring;

import accessors;

import tetrinho.graphics,
       tetrinho.util;

struct Scoreboard
{
    alias LevelUpDelegate = void delegate(uint) @safe;

    static immutable uint[uint] SCORE_MAPPING;

    @ConstRead {
        private uint level_      = 1;
        private uint score_      = 0;
        private uint combo_      = 1;
        private uint levelScore_ = 0;
    }

    private LevelUpDelegate levelUpDg_;

    static this()
    {
        SCORE_MAPPING = [
            1: 100,
            2: 300,
            3: 500,
            4: 800
        ];
    }

    void drop(in uint multiplier) @safe
    {
        score_ += level_ * multiplier;
    }

    void lineClear(in uint linesCleared) @safe
    in
    {
        assert(linesCleared > 0 && linesCleared <= 4);
    }
    do
    {
        immutable pts = SCORE_MAPPING[linesCleared];

        score_      += pts * level_;
        levelScore_ += pts / 100;

        if (combo_ > 1) {
            score_ += 50 * combo_ * level_;
        }

        ++combo_;

        if (levelScore_ >= 5 * level_) {
            levelScore_ = 0;
            ++level_;

            if (levelUpDg_ !is null) {
                levelUpDg_(level_);
            }
        }
    }

    void resetCombo() @safe @nogc nothrow
    {
        combo_ = 1;
    }

    void onLevelUp(scope LevelUpDelegate dg)
    {
        levelUpDg_ = dg;
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
