module tetrinho.scoring;

import accessors;

import tetrinho.graphics,
       tetrinho.util;

struct Scoreboard
{
    alias LevelUpDelegate = void delegate(uint) @safe;

    private struct Formatted
    {
        string str;
        bool needsUpdate = true;

        void set(in string f) @safe @nogc nothrow
        {
            str = f;
            needsUpdate = false;
        }

        void mark() @safe @nogc nothrow
        {
            needsUpdate = true;
        }
    }

    static immutable uint[uint] SCORE_MAPPING;

    @ConstRead {
        private uint level_      = 1;
        private uint score_      = 0;
        private uint combo_      = 1;
        private uint levelScore_ = 0;
    }

    private LevelUpDelegate levelUpDg_;

    private Formatted levelFormatted_, scoreFormatted_, comboFormatted_;

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
        scoreFormatted_.mark();
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

            levelFormatted_.mark();
        }

        scoreFormatted_.mark();
        comboFormatted_.mark();
    }

    void resetCombo() @safe @nogc nothrow
    {
        combo_ = 1;
        comboFormatted_.mark();
    }

    void onLevelUp(scope LevelUpDelegate dg)
    {
        levelUpDg_ = dg;
    }

    void draw(ref Graphics graphics)
    {
        import std.format : format;

        static immutable LEVEL_TEXT_BG = Rect(5, 5, 245, 90);

        if (levelFormatted_.needsUpdate) {
            levelFormatted_.set(format!"%02d"(level_));
        }

        if (scoreFormatted_.needsUpdate) {
            graphics.destroyTexture(scoreFormatted_.str);
            scoreFormatted_.set(format!"%08d"(score_));
        }

        if (comboFormatted_.needsUpdate) {
            comboFormatted_.set(format!"%dx"(combo_));
        }

        graphics.renderRect(Colors.BLACK, LEVEL_TEXT_BG);

        graphics.renderText("LEVEL", Coord(10, 5));
        graphics.renderText(levelFormatted_.str, Coord(110, 5));

        graphics.renderText("SCORE", Coord(10, 35));
        graphics.renderText(scoreFormatted_.str, Coord(110, 35));

        graphics.renderText("COMBO", Coord(10, 65));
        graphics.renderText(comboFormatted_.str, Coord(110, 65));
    }
}
