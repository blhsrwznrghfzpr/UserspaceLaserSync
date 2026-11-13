namespace UserspaceLaserSync;

internal static class LaserSyncRuntime
{
    // Each loader supplies its live configuration reader without exposing its
    // entry-point type to the shared patch.
    internal static Func<bool>? ReadEnabled { get; set; }
    internal static bool IsSyncEnabled => ReadEnabled?.Invoke() == true;
}
