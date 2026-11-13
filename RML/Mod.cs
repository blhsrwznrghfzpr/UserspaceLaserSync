using HarmonyLib;
using ResoniteModLoader;

namespace UserspaceLaserSync;

public sealed class Mod : ResoniteMod
{
    private const string HarmonyId = "dev.blhsrwznrghfzpr.UserspaceLaserSync";

    [AutoRegisterConfigKey]
    private static readonly ModConfigurationKey<bool> Enabled = new(
        "Enabled",
        "Make each userspace laser follow the same hand's laser toggle in the focused world.",
        () => true);

    private static ModConfiguration? _configuration;

    public override string Name => "UserspaceLaserSync";
    public override string Author => "blhsrwznrghfzpr";
    public override string Version => typeof(Mod).Assembly.GetName().Version!.ToString(3);

    public override void OnEngineInit()
    {
        _configuration = GetConfiguration();
        LaserSyncRuntime.ReadEnabled = () => _configuration?.GetValue(Enabled) == true;
        var harmony = new Harmony(HarmonyId);
        try
        {
            harmony.PatchAll(typeof(Mod).Assembly);
        }
        catch
        {
            harmony.UnpatchAll(HarmonyId);
            _configuration = null;
            LaserSyncRuntime.ReadEnabled = null;
            throw;
        }
        Msg("UserspaceLaserSync loaded. Userspace lasers follow the focused world's laser toggles.");
    }
}
