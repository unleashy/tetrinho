module tetrinho.game;

import derelict.sdl2.sdl;

import tetrinho.util,
       tetrinho.graphics;

enum uint MS_PER_UPDATE = 16;

enum KeyState
{
    KEY_DOWN,
    KEY_REPEAT,
    KEY_UP
}

struct Game
{
    private Graphics graphics_;
    private bool running_ = false;

    static Game opCall()
    {
        Game g;

        g.graphics_ = Graphics();

        return g;
    }

    void run()
    {
        running_ = true;

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

    private void handleInput(in SDL_Scancode sc, in KeyState state)
    {
        if (state == KeyState.KEY_DOWN && sc == SDL_SCANCODE_ESCAPE) {
            running_ = false;
        }
    }

    private void update()
    {
        /* TODO: update */
    }

    private void draw()
    {
        graphics_.renderClear();

        /* TODO: draw */

        graphics_.renderPresent();
    }
}
