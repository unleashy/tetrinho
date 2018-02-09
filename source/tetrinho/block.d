module tetrinho.block;

import accessors;

import tetrinho.util;

// Blocks are classes so that i don't have to use Block* or Nullable!Block
// everywhere since I expect these to be nullable.
final class Block
{
    immutable Color color;

    @RefRead
    private Coord coords_;

    @(ConstRead, Write)
    private bool inFormation_;

    this(in Color c, in Coord coords, in bool inFormation) @safe @nogc
    {
        color  = c;
        coords_ = coords;
        inFormation_ = inFormation;
    }

    mixin(GenerateFieldAccessors);
}
