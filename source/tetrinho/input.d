module tetrinho.input;

import std.array,
       std.typecons;

import derelict.sdl2.sdl;

import tetrinho.graphics,
       tetrinho.util;

struct TextInput
{
    private Appender!(char[]) buf_ = appender!(char[]);

    void addText(char[] text) @safe
    {
        import std.utf : decodeFront, byUTF;

        if (data.length < 20) {
            buf_ ~= [text.decodeFront].byUTF!(char);
        }
    }

    void removeLast() @safe
    {
        if (data.length > 0) {
            buf_.shrinkTo(buf_.data.length - 1);
        }
    }

    void draw(ref Graphics g, in Coord coord)
    {
        auto d = data;
        if (d.length > 0) {
            g.renderText(d, coord, Yes.small);
        }
    }

    string data() @property @trusted @nogc pure const
    {
        return cast(string) buf_.data;
    }
}
