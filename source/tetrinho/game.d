module tetrinho.game;

import derelict.sdl2.sdl;

import tetrinho.block,
       tetrinho.config,
       tetrinho.graphics,
       tetrinho.piece,
       tetrinho.playfield,
       tetrinho.scoring,
       tetrinho.timer,
       tetrinho.util;

enum uint MS_PER_UPDATE = 16;

enum uint LOCKING_TIMEOUT = 500;

enum KeyState
{
    KEY_DOWN,
    KEY_REPEAT,
    KEY_UP
}

enum GameState
{
    STOPPED,
    RUNNING,
    PAUSED,
    GAME_OVER
}

struct Game
{
    private GameState state_;
    private Config config_;
    private Graphics graphics_;
    private Playfield playfield_;
    private Piece currentPiece_, nextPiece_;
    private Timer gravityTimer_, lockTimer_;
    private Scoreboard scoreboard_;
    private bool pieceDropping_;

    static Game opCall()
    {
        Game g;

        g.config_       = Config(resourcePath("config.sdl"));
        g.graphics_     = Graphics();
        g.playfield_    = Playfield();
        g.gravityTimer_ = new Timer(g.calculateGravityTimeout(1));
        g.lockTimer_    = new Timer(LOCKING_TIMEOUT);
        g.lockTimer_.deactivate();

        return g;
    }

    void run()
    {
        state_ = GameState.RUNNING;

        scoreboard_.onLevelUp((level) {
            gravityTimer_.timeout = calculateGravityTimeout(level);
            gravityTimer_.reset();
        });

        nextPiece_ = generateNewPiece();
        nextPiece_.center(COLS);
        advancePieces();

        SDL_Event e;
        auto previousTimeMs = SDL_GetTicks();
        auto lag = 0.0;

        while (state_ != GameState.STOPPED) {
            immutable currentTimeMs = SDL_GetTicks();
            immutable elapsedTimeMs = currentTimeMs - previousTimeMs;
            previousTimeMs = currentTimeMs;
            lag += elapsedTimeMs;

            while (SDL_PollEvent(&e)) {
                switch (e.type) {
                    case SDL_QUIT:
                        state_ = GameState.STOPPED;
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

            if (state_ == GameState.STOPPED) break;

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

    private void handleInput(in SDL_Scancode sc, in KeyState ks)
    {
        if (ks == KeyState.KEY_DOWN && sc == config_.input.quit) {
            state_ = GameState.STOPPED;
            return;
        }

        final switch (state_) with (GameState) {
            case STOPPED:
            case GAME_OVER:
                return;

            case PAUSED:
                if (ks == KeyState.KEY_DOWN && sc == config_.input.pause) {
                    state_ = RUNNING;
                }
                return;

            case RUNNING: break; // just go
        }

        if (ks == KeyState.KEY_DOWN) {
            if (sc == config_.input.hardDrop) {
                pieceDropping_ = true;
                gravityTimer_.deactivate();
            } else if (sc == config_.input.pause) {
                state_ = GameState.PAUSED;
            }
        }

        if (!pieceDropping_ && (ks == KeyState.KEY_DOWN || ks == KeyState.KEY_REPEAT)) {
            if (sc == config_.input.right) {
                currentPiece_.move(Coord(1, 0), playfield_);
            } else if (sc == config_.input.left) {
                currentPiece_.move(Coord(-1, 0), playfield_);
            } else if (sc == config_.input.softDrop) {
                if (currentPiece_.move(Coord(0, 1), playfield_)) {
                    scoreboard_.drop(1);
                }
            } else if (sc == config_.input.rotateCCW) {
                currentPiece_.rotateLeft(playfield_);
            } else if (sc == config_.input.rotateCW) {
                currentPiece_.rotateRight(playfield_);
            }
        }
    }

    private void update()
    {
        static immutable GRAVITY_DELTA = Coord(0, 1);

        if (state_ != GameState.RUNNING) return;

        if (pieceDropping_) {
            if (currentPiece_.move(GRAVITY_DELTA, playfield_)) {
                scoreboard_.drop(2);
            } else {
                pieceDropping_ = false;
                lockTimer_.activate();
            }

            goto end; // YES YES THIS IS A GOTO, WHATCHA GONNA DO ABOUT IT?
        }

        if (lockTimer_.active) {
            if (lockTimer_.expired) {
                lockTimer_.deactivate();
                gravityTimer_.activate();
                advancePieces();
            } else if (currentPiece_.floating(playfield_)) {
                lockTimer_.deactivate();
                gravityTimer_.activate();
            }
        } else if (!currentPiece_.floating(playfield_)) {
            lockTimer_.activate();
            gravityTimer_.deactivate();
        }

        if (gravityTimer_.expired) {
            currentPiece_.move(GRAVITY_DELTA, playfield_);
            gravityTimer_.reset();
        }

    end:
        Timer.tickAll(MS_PER_UPDATE);
    }

    private void advancePieces()
    {
        currentPiece_.detachBlocks();

        clearLines();

        currentPiece_ = nextPiece_;
        currentPiece_.spawnPiece(playfield_);

        nextPiece_ = generateNewPiece();
        nextPiece_.center(COLS);

        if (currentPiece_.anyCollision(playfield_)) {
            state_ = GameState.GAME_OVER;
        }
    }

    private void clearLines()
    {
        auto lineData = playfield_.findLines();
        if (playfield_.remove(lineData.blocks)) {
            immutable linesCleared = lineData.rows.length;

            foreach (const row; lineData.rows) {
                playfield_.gravityFrom(row, 1);
            }

            scoreboard_.lineClear(linesCleared);

            foreach (ref blk; lineData.blocks) {
                destroy(blk); // we have no need for these at all anymore
            }
        } else {
            scoreboard_.resetCombo();
        }
    }

    private uint calculateGravityTimeout(in uint level) @safe @nogc pure
    {
        immutable levelR = level - 1;
        return cast(uint) (((0.8 - (levelR * 0.007)) ^^ levelR) * 1000);
    }

    private void draw()
    {
        graphics_.renderClear();

        playfield_.draw(graphics_, config_.ghostPiece);
        scoreboard_.draw(graphics_);

        if (state_ == GameState.GAME_OVER) {
            drawGameOver();
        } else if (state_ == GameState.PAUSED) {
            drawPaused();
        }

        // Draw next piece
        enum NEXT_FORMATION_COORDS = Coord(10, 230);
        enum NEXT_FORMATION_TXT_COORDS = Coord(95, 200);
        static immutable NEXT_FORMATION_BG = Rect(
            82, NEXT_FORMATION_COORDS.y - 30, BLK_WIDTH * 4, BLK_HEIGHT * 2 + 30
        );

        graphics_.renderRect(Colors.BLACK, NEXT_FORMATION_BG);
        graphics_.renderText("NEXT", NEXT_FORMATION_TXT_COORDS);

        foreach (const block; nextPiece_.blocks) {
            block.draw(graphics_, NEXT_FORMATION_COORDS, false);
        }

        graphics_.renderPresent();
    }

    private void drawGameOver()
    {
        drawOverBoard("GAME OVER");
    }

    private void drawPaused()
    {
        drawOverBoard("PAUSED");
    }

    private void drawOverBoard(in string text)
    {
        static immutable BG  = Rect(BOARD_X, BOARD_Y, BOARD_WIDTH, BOARD_HEIGHT);
        static immutable CLR = Color(0, 0, 0, 170);

        graphics_.blend();
        graphics_.renderRect(CLR, BG);
        graphics_.renderText(text, BG);
    }
}
