using BepInEx;
using BepInEx.Configuration;
using BepInEx.NET.Common;
using HarmonyLib;

namespace UserspaceLaserSync;

[BepInPlugin(PluginGuid, PluginName, PluginVersion)]
public sealed class Plugin : BasePlugin
{
    public const string PluginGuid = "dev.blhsrwznrghfzpr.UserspaceLaserSync";
    public const string PluginName = "UserspaceLaserSync";
    public const string PluginVersion = PluginMetadata.VERSION;

    private Harmony? _harmony;
    private ConfigEntry<bool>? _enabled;

    public override void Load()
    {
        _enabled = Config.Bind("General", "Enabled", true,
            "Enable userspace laser synchronization. Changes apply immediately. " +
            "When disabled, Resonite's original laser behavior is preserved.");
        _enabled.SettingChanged += OnEnabledChanged;
        LaserSyncRuntime.SetEnabled(_enabled.Value);
        _harmony = new Harmony(PluginGuid);
        try
        {
            _harmony.PatchAll(typeof(Plugin).Assembly);
        }
        catch
        {
            _harmony.UnpatchSelf();
            _enabled.SettingChanged -= OnEnabledChanged;
            LaserSyncRuntime.SetEnabled(false);
            _enabled = null;
            throw;
        }
        Log.LogInfo($"UserspaceLaserSync loaded. Enabled: {_enabled.Value}.");
    }

    private void OnEnabledChanged(object? sender, EventArgs args) =>
        LaserSyncRuntime.SetEnabled(_enabled?.Value == true);

    public override bool Unload()
    {
        if (_enabled != null)
            _enabled.SettingChanged -= OnEnabledChanged;
        LaserSyncRuntime.SetEnabled(false);
        _harmony?.UnpatchSelf();
        _enabled = null;
        return true;
    }
}
