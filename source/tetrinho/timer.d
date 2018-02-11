module tetrinho.timer;

import accessors;

final class Timer
{
    private static Timer[] timers_;

    uint timeout;
    private uint currentTime_;
    @ConstRead private bool active_, expired_;

    @disable this();

    this(in uint t) @safe
    {
        active_ = true;
        timeout = t;

        timers_ ~= this;
    }

    static void register(ref Timer timer) @safe
    {
        timers_ ~= timer;
    }

    static void unregister(ref Timer timer) @safe @nogc
    {
        import std.algorithm : remove;
        timers_ = timers_.remove!(t => t is timer);
    }

    static void tickAll(in uint time) @safe @nogc
    {
        foreach (timer; timers_) {
            if (timer !is null) {
                timer.tick(time);
            }
        }
    }

    void tick(in uint time) @safe @nogc
    {
        if (active) {
            currentTime_ += time;
            if (currentTime_ >= timeout) {
                expired_ = true;
            }
        }
    }

    void reset() @safe @nogc
    {
        active_      = true;
        expired_     = false;
        currentTime_ = 0;
    }

    void activate() @safe @nogc
    {
        if (!active_) {
            reset();
        }
    }

    void deactivate() @safe @nogc
    {
        if (active_) {
            active_      = false;
            expired_     = false;
            currentTime_ = 0;
        }
    }

    mixin(GenerateFieldAccessors);
}
