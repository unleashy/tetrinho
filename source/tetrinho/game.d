module tetrinho.game;

import derelict.sdl2.sdl;

import tetrinho.graphics;

enum uint MS_PER_UPDATE = 16;

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

                    /* TODO: input */

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

    void update()
    {
        /* TODO: update */
    }

    void draw()
    {
        graphics_.renderClear();

        /* TODO: draw */

        graphics_.renderPresent();
    }
}
