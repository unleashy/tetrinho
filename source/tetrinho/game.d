module tetrinho.game;

import derelict.sdl2.sdl;

import tetrinho.block,
       tetrinho.graphics,
       tetrinho.piece,
       tetrinho.playfield,
       tetrinho.timer,
       tetrinho.util;

enum uint MS_PER_UPDATE   = 16;
enum uint GRAVITY_TIMEOUT = 750;

enum KeyState
{
    KEY_DOWN,
    KEY_REPEAT,
    KEY_UP
}

struct Game
{
    private bool running_;
    private Graphics graphics_;
    private Playfield playfield_;
    private Piece currentPiece_, nextPiece_;
    private Timer gravityTimer_;

    static Game opCall()
    {
        Game g;

        g.graphics_     = Graphics();
        g.playfield_    = Playfield();
        g.gravityTimer_ = new Timer(GRAVITY_TIMEOUT);

        return g;
    }

    void run()
    {
        running_ = true;

        nextPiece_ = generateNewPiece();
        nextPiece_.center(COLS);
        advancePieces();

        SDL_Event e;
        auto previousTimeMs = SDL_GetTicks();
        auto lag = 0.0;

        while (running_) {
            immutable currentTimeMs = SDL_GetTicks();
            immutable elapsedTimeMs = currentTimeMs - previousTimeMs;
            previousTimeMs = currentTimeMs;
            lag += elapsedTimeMs;

            while (SDL_PollEvent(&e)) {
                switch (e.type) {
                    case SDL_QUIT:
                        running_ = false;
                        break;

                    case SDL_KEYDOWN:
                        handleInput(
                            e.key.keysym.scancode,
                            e.key.repeat ? KeyState.KEY_REPEAT : KeyState.KEY_DOWN
                        );
                        break;

                    case SDL_KEYUP:
                        handleInput(e.key.keysym.scancode, KeyState.KEY_UP);
                        break;

                    default: break;
                }
            }

            if (!running_) break;

            while (lag >= MS_PER_UPDATE) {
                update();
                lag -= MS_PER_UPDATE;
            }

            draw();

            // Cap frames per second to MS_PER_UPDATE ish.
            if (elapsedTimeMs < MS_PER_UPDATE) {
                SDL_Delay((cast(Uint32) MS_PER_UPDATE) - elapsedTimeMs);
            }
        }
    }

    private void advancePieces()
    {
        currentPiece_ = nextPiece_;
        currentPiece_.spawnPiece(playfield_);

        nextPiece_ = generateNewPiece();
        nextPiece_.center(COLS);
    }

    private void handleInput(in SDL_Scancode sc, in KeyState state)
    {
        if (state == KeyState.KEY_DOWN || state == KeyState.KEY_REPEAT) {
            switch (sc) {
                case SDL_SCANCODE_ESCAPE:
                    running_ = false;
                    break;

                case SDL_SCANCODE_RIGHT:
                    currentPiece_.move(Coord(1, 0), playfield_);
                    break;

                case SDL_SCANCODE_LEFT:
                    currentPiece_.move(Coord(-1, 0), playfield_);
                    break;

                case SDL_SCANCODE_DOWN:
                    currentPiece_.move(Coord(0, 1), playfield_);
                    break;

                case SDL_SCANCODE_Z:
                    currentPiece_.rotateLeft(playfield_);
                    break;

                case SDL_SCANCODE_X:
                    currentPiece_.rotateRight(playfield_);
                    break;

                default: break;
            }
        }
    }

    private void update()
    {
        static immutable GRAVITY_DELTA = Coord(0, 1);

        if (gravityTimer_.expired) {
            if (!currentPiece_.move(GRAVITY_DELTA, playfield_)) {
                advancePieces();
            }

            gravityTimer_.reset();
        }

        Timer.tickAll(MS_PER_UPDATE);
    }

    private void draw()
    {
        graphics_.renderClear();

        playfield_.draw(graphics_);

        graphics_.renderPresent();
    }
}
