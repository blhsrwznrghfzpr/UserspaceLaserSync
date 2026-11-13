using HarmonyLib;
using ResoniteModLoader;

namespace UserspaceLaserSync;

public sealed class Mod : ResoniteMod
{
    private const string HarmonyId = "dev.blhsrwznrghfzpr.UserspaceLaserSync";

    [AutoRegisterConfigKey]
    private static readonly ModConfigurationKey<bool> Enabled = new(
        "Enabled",
        "Enable userspace laser synchronization. Changes apply immediately. " +
        "When disabled, Resonite's original laser behavior is preserved.",
        () => true);

    private ModConfiguration? _configuration;

    public override string Name => "UserspaceLaserSync";
    public override string Author => "blhsrwznrghfzpr";
    public override string Version => typeof(Mod).Assembly.GetName().Version!.ToString(3);

    public override void OnEngineInit()
    {
        _configuration = GetConfiguration();
        if (_configuration != null)
            _configuration.OnThisConfigurationChanged += OnConfigurationChanged;
        LaserSyncRuntime.SetEnabled(_configuration?.GetValue(Enabled) == true);
        var harmony = new Harmony(HarmonyId);
        try
        {
            harmony.PatchAll(typeof(Mod).Assembly);
        }
        catch
        {
            harmony.UnpatchAll(HarmonyId);
            if (_configuration != null)
                _configuration.OnThisConfigurationChanged -= OnConfigurationChanged;
            LaserSyncRuntime.SetEnabled(false);
            _configuration = null;
            throw;
        }
        Msg($"UserspaceLaserSync loaded. Enabled: {LaserSyncRuntime.IsSyncEnabled}.");
    }

    private void OnConfigurationChanged(ConfigurationChangedEvent change)
    {
        if (change.Key == Enabled)
            LaserSyncRuntime.SetEnabled(_configuration?.GetValue(Enabled) == true);
    }
}
