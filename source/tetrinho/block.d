module tetrinho.block;

import accessors;

import tetrinho.util;

// Blocks are classes so that i don't have to use Block* or Nullable!Block
// everywhere since I expect these to be nullable.
final class Block
{
    immutable Color color;
    Coord coords;
    bool inFormation;

    this(in Color c, in Coord crds, in bool inF) @safe @nogc
    {
        color       = c;
        coords      = crds;
        inFormation = inF;
    }

    mixin(GenerateFieldAccessors);
}
