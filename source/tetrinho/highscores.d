module tetrinho.highscores;

import core.time,
       std.algorithm,
       std.array,
       std.datetime.systime,
       std.typecons;

import sdlang;

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
    }

    Nullable!Highscore highestScore() @property @safe @nogc pure nothrow
    {
        return highscores_.empty ? typeof(return).init : nullable(highscores_[0]);
    }
}
