module tetrinho.highscores;

import core.time,
       std.algorithm,
       std.array,
       std.datetime.systime,
       std.typecons;

import sdlang;

import tetrinho.graphics,
       tetrinho.util;

struct Highscore
{
    string name;
    uint score;
    uint level;
    Duration time;
    SysTime when;
}

struct Highscores
{
    private enum hsCmp = "a.score > b.score";

    private Highscore[] highscores_;
    private string[24] formattedHighscores_;

    this(in string filename)
    {
        load(filename);
    }

    void load(in string filename)
    {
        highscores_ = parseFile(filename).tags.map!(t => Highscore(
            t.expectValue!string,
            cast(uint) t.expectAttribute!int("score"),
            cast(uint) t.expectAttribute!int("level"),
            t.expectAttribute!Duration("time"),
            t.expectAttribute!SysTime("when"),
        )).array.sort!(hsCmp).release;
    }

    void save(in string filename)
    {
        import std.file  : write;
        import std.array : appender;

        auto scoresBuf = appender!(Tag[]);
        scoresBuf.reserve(highscores_.length);

        foreach (ref hs; highscores_) {
            scoresBuf ~= new Tag(
                null,
                null,
                null,
                [Value(hs.name)],
                [
                    new Attribute(null, "score", Value(cast(int) hs.score)),
                    new Attribute(null, "level", Value(cast(int) hs.level)),
                    new Attribute(null, "time",  Value(hs.time)),
                    new Attribute(null, "when",  Value(hs.when)),
                ]
            );
        }

        auto rootTag = new Tag(null, null, null, null, scoresBuf.data);

        write(filename, rootTag.toSDLDocument());
    }

    void addScore(in Highscore score) @safe
    {
        highscores_ ~= score;
        highscores_.sort!(hsCmp);

        clearHighscoreFormatCache();
    }

    void clearHighscoreFormatCache() @safe
    {
        formattedHighscores_ = new string[formattedHighscores_.length];
    }

    void draw(ref Graphics g)
    {
        import std.format : format;

        static immutable BG = Rect(5, 5, WINDOW_WIDTH - 10, WINDOW_HEIGHT - 10);
        static immutable TITLE_CENTER_RECT = Rect(BG.x, BG.y, BG.w, 30);
        static immutable LEGEND_COORD = Coord(BG.x + 5, BG.y + 60);
        static immutable BASE_COORD   = Coord(LEGEND_COORD.x, LEGEND_COORD.y + 30);

        g.renderRect(Colors.BLACK, BG);

        g.renderText("HIGHSCORES", TITLE_CENTER_RECT);

        if (highscores_.length == 0) {
            g.renderText("No highscores.", BG, FontSize.SMALL);
            return;
        }

        g.renderText(
            "#   Name      Score     Level  Time      When",
            LEGEND_COORD,
            FontSize.TINY
        );

        foreach (const int i, ref const highscore; highscores_) {
            immutable thisCoord = Coord(BASE_COORD.x, BASE_COORD.y + i * 20);

            string formatted = void;
            if (auto f = formattedHighscores_[i]) {
                formatted = f;
            } else {
                long hours, minutes, seconds;
                highscore.time.split!("hours", "minutes", "seconds")(hours, minutes, seconds);

                formattedHighscores_[i] = formatted =
                    format!"%02d. %-8s  %08d  %02d     %02d:%02d:%02d  %-12s"(
                        i + 1,
                        highscore.name.truncate(8),
                        highscore.score,
                        highscore.level,
                        hours, minutes, seconds,
                        highscore.when.agoString
                    );
            }

            g.renderText(formatted, thisCoord, FontSize.TINY);

            if (i >= 23) break; // maximum of 24 scores shown
        }
    }

    Nullable!Highscore highestScore() @property @safe @nogc pure nothrow
    {
        return highscores_.empty ? typeof(return).init : nullable(highscores_[0]);
    }
}
