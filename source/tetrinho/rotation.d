module tetrinho.rotation;

import std.typecons,
       std.exception;

import tetrinho.util;

enum RotationState
{
    SPAWN,
    RIGHT_ROT,
    CYCLE,
    LEFT_ROT
}

alias RotationTableKey = Tuple!(RotationState, "from", RotationState, "to");
alias RotationTable    = Coord[4][RotationTableKey];

immutable RotationTable rotationTableNormal;
immutable RotationTable rotationTableI;

static this() @safe
{
    rotationTableNormal = genNormalTable();
    rotationTableI      = genITable();
}

RotationTableKey calculateKey(RotationState rot)(in RotationState from) @safe
    if (rot == RotationState.RIGHT_ROT || rot == RotationState.LEFT_ROT)
{
    RotationTableKey key;
    key.from = from;

    final switch (from) with (RotationState) {
        case SPAWN:
            key.to = rot;
            break;

        case RIGHT_ROT:
            static if (rot == RIGHT_ROT) {
                key.to = CYCLE;
            } else static if (rot == LEFT_ROT) {
                key.to = SPAWN;
            }
            break;

        case CYCLE:
            static if (rot == RIGHT_ROT) {
                key.to = LEFT_ROT;
            } else static if (rot == LEFT_ROT) {
                key.to = RIGHT_ROT;
            }
            break;

        case LEFT_ROT:
            static if (rot == RIGHT_ROT) {
                key.to = SPAWN;
            } else static if (rot == LEFT_ROT) {
                key.to = CYCLE;
            }
            break;
    }

    return key;
}

private immutable(RotationTable) genNormalTable() @trusted pure
{
    RotationTable buf;

    with (RotationState) {
        buf[RotationTableKey(SPAWN, RIGHT_ROT)] = [
            Coord(-1,  0),
            Coord(-1, -1),
            Coord( 0,  2),
            Coord(-1,  2)
        ];

        buf[RotationTableKey(RIGHT_ROT, SPAWN)] = [
            Coord(1,  0),
            Coord(1,  1),
            Coord(0, -2),
            Coord(1, -2)
        ];

        buf[RotationTableKey(RIGHT_ROT, CYCLE)] = [
            Coord( 1,  0),
            Coord( 1,  1),
            Coord( 0, -2),
            Coord( 1, -2)
        ];

        buf[RotationTableKey(CYCLE, RIGHT_ROT)] = [
            Coord(-1,  0),
            Coord(-1, -1),
            Coord( 0,  2),
            Coord(-1,  2)
        ];

        buf[RotationTableKey(CYCLE, LEFT_ROT)] = [
            Coord(1,  0),
            Coord(1, -1),
            Coord(0,  2),
            Coord(1,  2)
        ];

        buf[RotationTableKey(LEFT_ROT, CYCLE)] = [
            Coord(-1,  0),
            Coord(-1,  1),
            Coord( 0, -2),
            Coord(-1, -2)
        ];

        buf[RotationTableKey(LEFT_ROT, SPAWN)] = [
            Coord(-1,  0),
            Coord(-1,  1),
            Coord( 0, -2),
            Coord(-1, -2)
        ];

        buf[RotationTableKey(SPAWN, LEFT_ROT)] = [
            Coord(1,  0),
            Coord(1, -1),
            Coord(0,  2),
            Coord(1,  2)
        ];
    }

    buf.rehash;
    return buf.assumeUnique;
}

private immutable(RotationTable) genITable() @trusted pure
{
    RotationTable buf;

    with (RotationState) {
        buf[RotationTableKey(SPAWN, RIGHT_ROT)] = [
            Coord(-2,  0),
            Coord( 1,  0),
            Coord(-2,  1),
            Coord( 1, -2)
        ];

        buf[RotationTableKey(RIGHT_ROT, SPAWN)] = [
            Coord( 2,  0),
            Coord(-1,  0),
            Coord( 2, -1),
            Coord(-1,  2)
        ];

        buf[RotationTableKey(RIGHT_ROT, CYCLE)] = [
            Coord(-1,  0),
            Coord( 2,  0),
            Coord(-1, -2),
            Coord( 2,  1)
        ];

        buf[RotationTableKey(CYCLE, RIGHT_ROT)] = [
            Coord( 1,  0),
            Coord(-2,  0),
            Coord( 1,  2),
            Coord(-2, -1)
        ];

        buf[RotationTableKey(CYCLE, LEFT_ROT)] = [
            Coord( 2,  0),
            Coord(-1,  0),
            Coord( 2, -1),
            Coord(-1,  2)
        ];

        buf[RotationTableKey(LEFT_ROT, CYCLE)] = [
            Coord(-2,  0),
            Coord( 1,  0),
            Coord(-2,  1),
            Coord( 1, -2)
        ];

        buf[RotationTableKey(LEFT_ROT, SPAWN)] = [
            Coord( 1,  0),
            Coord(-2,  0),
            Coord( 1,  2),
            Coord(-2, -1)
        ];

        buf[RotationTableKey(SPAWN, LEFT_ROT)] = [
            Coord(-1,  0),
            Coord( 2,  0),
            Coord(-1, -2),
            Coord( 2,  1)
        ];
    }

    buf.rehash;
    return buf.assumeUnique;
}
