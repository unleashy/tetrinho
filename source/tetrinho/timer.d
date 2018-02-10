module tetrinho.timer;

import accessors;

final class Timer
{
    private static Timer[] timers_;

    private uint timeout_, currentTime_;
    @ConstRead private bool expired_;

    @disable this();

    this(in uint timeout) @safe
    {
        timeout_ = timeout;
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
        if (!expired_) {
            currentTime_ += time;
            if (currentTime_ >= timeout_) {
                expired_ = true;
            }
        }
    }

    void reset() @safe @nogc
    {
        expired_     = false;
        currentTime_ = 0;
    }

    mixin(GenerateFieldAccessors);
}
