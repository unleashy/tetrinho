module tetrinho.game;

import std.datetime.stopwatch,
       std.string,
       std.typecons;

import derelict.sdl2.sdl;

import tetrinho.block,
       tetrinho.config,
       tetrinho.graphics,
       tetrinho.highscores,
       tetrinho.input,
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
    HIGHSCORES,
    RESTART,
    GAME_OVER
}

enum NEXT_FORMATION_COORDS = Coord(10, 230);
enum NEXT_FORMATION_TXT_COORDS = Coord(95, 200);
immutable NEXT_FORMATION_BG = Rect(
    82, NEXT_FORMATION_COORDS.y - 30, BLK_WIDTH * 4, BLK_HEIGHT * 2 + 30
);
immutable BOARD = Rect(BOARD_X, BOARD_Y, BOARD_WIDTH, BOARD_HEIGHT);

struct Game
{
    private GameState state_;
    private Config config_;
    private Graphics graphics_;
    private Playfield playfield_;
    private Scoreboard scoreboard_;
    private Highscores highscores_;
    private Piece currentPiece_, nextPiece_;
    private Timer gravityTimer_, lockTimer_, timeTimer_;
    private StopWatch timeSW_;
    private TextInput textInput_;
    private bool pieceDropping_;

    static Game opCall()
    {
        Game g;

        g.config_       = Config(resourcePath("config.sdl"));
        g.graphics_     = Graphics();
        g.playfield_    = Playfield();
        g.highscores_   = Highscores(resourcePath("highscores.sdl"));
        g.timeTimer_    = new Timer(1000); // 1000 ms = 1 second
        g.gravityTimer_ = new Timer(g.calculateGravityTimeout(1));
        g.lockTimer_    = new Timer(LOCKING_TIMEOUT);
        g.lockTimer_.deactivate();

        return g;
    }

    void run()
    {
    start:
        state_ = GameState.RUNNING;
        SDL_StopTextInput();

        scoreboard_.onLevelUp((level) {
            gravityTimer_.timeout = calculateGravityTimeout(level);
            gravityTimer_.reset();
        });

        nextPiece_ = generateNewPiece();
        nextPiece_.center(COLS);
        advancePieces();

        assert(!timeSW_.running);
        timeSW_.start();

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

                    case SDL_TEXTINPUT:
                        if (SDL_IsTextInputActive()) {
                            textInput_.addText(e.text.text[]);
                        }
                        break;

                    default: break;
                }
            }

            if (state_ == GameState.STOPPED || state_ == GameState.RESTART) {
                break;
            }

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

        if (state_ == GameState.RESTART) {
            timeSW_.stop();
            timeSW_.reset();

            playfield_  = Playfield();
            scoreboard_ = Scoreboard();
            gravityTimer_.reset();
            lockTimer_.deactivate();

            goto start; // HOLY SHIT ANOTHER GOTO THEY ARE COMPLETELY MAD!!!
        }
    }

    private void handleInput(in SDL_Scancode sc, in KeyState ks)
    {
        import std.datetime.systime : Clock;

        if (ks == KeyState.KEY_DOWN) {
            if (sc == config_.input.quit) {
                state_ = state_ == GameState.GAME_OVER ? GameState.RESTART : GameState.STOPPED;
                return;
            } else if (state_ != GameState.GAME_OVER && sc == config_.input.restart) {
                state_ = GameState.RESTART;
                return;
            }
        }

        final switch (state_) with (GameState) {
            case STOPPED:
            case RESTART:
                return;

            case GAME_OVER:
                if (SDL_IsTextInputActive() && (ks == KeyState.KEY_DOWN || ks == KeyState.KEY_REPEAT)) {
                    if (sc == SDL_SCANCODE_BACKSPACE) {
                        textInput_.removeLast();
                    } else if (sc == SDL_SCANCODE_KP_ENTER || sc == SDL_SCANCODE_RETURN) {
                        SDL_StopTextInput();

                        highscores_.addScore(
                            Highscore(
                                textInput_.data,
                                scoreboard_.score,
                                scoreboard_.level,
                                timeSW_.peek(),
                                Clock.currTime()
                            )
                        );

                        highscores_.save(resourcePath("highscores.sdl"));

                        state_ = GameState.RESTART;
                    }
                }
                return;

            case PAUSED:
                if (ks == KeyState.KEY_DOWN && sc == config_.input.pause) {
                    state_ = RUNNING;
                    timeSW_.start();
                }
                return;

            case HIGHSCORES:
                if (ks == KeyState.KEY_DOWN && sc == config_.input.highscores) {
                    state_ = RUNNING;
                    highscores_.clearHighscoreFormatCache();
                    timeSW_.start();
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
                timeSW_.stop();
                return;
            } else if (sc == config_.input.highscores) {
                state_ = GameState.HIGHSCORES;
                timeSW_.stop();
                return;
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

        if (timeTimer_.active && timeTimer_.expired) {
            scoreboard_.timeTick(timeSW_);
        }

        if (pieceDropping_) {
            if (currentPiece_.move(GRAVITY_DELTA, playfield_)) {
                scoreboard_.drop(2);
            } else {
                pieceDropping_ = false;
                gravityTimer_.activate();
                advancePieces();
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
            timeSW_.stop();
            SDL_StartTextInput();
        }
    }

    private void clearLines()
    {
        auto lineData = playfield_.findLines();
        if (playfield_.remove(lineData.blocks)) {
            immutable linesCleared = cast(uint) lineData.rows.length;

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
        scope(exit) graphics_.renderPresent();

        if (state_ == GameState.HIGHSCORES) {
            drawHighscores();
            return;
        }

        playfield_.draw(graphics_, config_.ghostPiece);
        scoreboard_.draw(graphics_, highscores_);

        // Draw next piece
        graphics_.renderRect(Colors.BLACK, NEXT_FORMATION_BG);
        graphics_.renderText("NEXT", NEXT_FORMATION_TXT_COORDS);

        foreach (const block; nextPiece_.blocks) {
            block.draw(graphics_, NEXT_FORMATION_COORDS, false);
        }

        if (state_ == GameState.GAME_OVER) {
            drawGameOver();
        } else if (state_ == GameState.PAUSED) {
            drawPaused();
        }
    }

    private void drawGameOver()
    {
        static immutable CENTER_RECT      = Rect(BOARD_X, BOARD_Y + 60, BOARD_WIDTH, BOARD_HEIGHT);
        static immutable INPUT_BG_RECT    = Rect(BOARD_X + 8, 370, BOARD_WIDTH - 16, 20);
        static immutable INPUT_OUTL_RECT  = Rect(BOARD_X + 5, 367, BOARD_WIDTH - 10, 26);
        static immutable INPUT_TEXT_COORD = Coord(INPUT_BG_RECT.x, INPUT_BG_RECT.y);

        drawOverBoard("GAME OVER");
        graphics_.renderText("Highscore name:", CENTER_RECT, FontSize.SMALL);
        graphics_.renderRect(Colors.WHITE, INPUT_OUTL_RECT);
        graphics_.renderRect(Colors.BLACK, INPUT_BG_RECT);

        textInput_.draw(graphics_, INPUT_TEXT_COORD);
    }

    private void drawPaused()
    {
        drawOverBoard!true("PAUSED");
    }

    private void drawHighscores()
    {
        highscores_.draw(graphics_);
    }

    private void drawOverBoard(bool hideStuff = false)(in string text)
    {
        // this is a bit bootleg but whatever
        static immutable NEXT_BG = Rect(
            NEXT_FORMATION_BG.x,
            NEXT_FORMATION_COORDS.y,
            NEXT_FORMATION_BG.w,
            NEXT_FORMATION_BG.h - 30
        );
        static immutable CLR = Color(0, 0, 0, hideStuff ? 255 : 170);

        graphics_.blend();
        graphics_.renderRect(CLR, BOARD);
        graphics_.renderText(text, BOARD);

        static if (hideStuff) {
            graphics_.renderRect(CLR, NEXT_BG);
        }
    }
}
