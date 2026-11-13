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
    private static ConfigEntry<bool>? SyncEnabled { get; set; }
    internal static bool IsSyncEnabled => SyncEnabled?.Value == true;

    public override void Load()
    {
        SyncEnabled = Config.Bind("General", "Enabled", true,
            "Make each userspace laser follow the same hand's laser toggle in the focused world.");
        _harmony = new Harmony(PluginGuid);
        try
        {
            _harmony.PatchAll(typeof(Plugin).Assembly);
        }
        catch
        {
            _harmony.UnpatchSelf();
            throw;
        }
        Log.LogInfo("UserspaceLaserSync loaded. Userspace lasers follow the focused world's laser toggles.");
    }

    public override bool Unload()
    {
        _harmony?.UnpatchSelf();
        SyncEnabled = null;
        return true;
    }
}
