namespace UserspaceLaserSync;

internal static class LaserSyncRuntime
{
    // Configuration callbacks can run outside the world update thread.
    // Keep the getter independent of either loader's configuration API.
    private static volatile bool _enabled;

    internal static bool IsSyncEnabled => _enabled;

    internal static void SetEnabled(bool enabled) => _enabled = enabled;
}
