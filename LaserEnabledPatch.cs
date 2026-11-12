using FrooxEngine;
using HarmonyLib;
using Renderite.Shared;

namespace UserspaceLaserSync;

[HarmonyPatch(typeof(InteractionHandler), nameof(InteractionHandler.LaserEnabled), MethodType.Getter)]
internal static class LaserEnabledPatch
{
    // Reuse predicates: this getter is called multiple times per frame.
    private static readonly Predicate<InteractionHandler> LeftHand =
        handler => !handler.IsRemoved && handler.Side.Value == Chirality.Left;
    private static readonly Predicate<InteractionHandler> RightHand =
        handler => !handler.IsRemoved && handler.Side.Value == Chirality.Right;

    [HarmonyPostfix]
    private static void Postfix(InteractionHandler __instance, ref bool __result)
    {
        if (!Plugin.IsSyncEnabled || __instance.IsRemoved ||
            !__instance.IsUnderLocalUser || __instance.World != Userspace.UserspaceWorld)
            return;

        var focusedWorld = __instance.Engine.WorldManager.FocusedWorld;
        if (focusedWorld == null || focusedWorld.IsDestroyed || focusedWorld == __instance.World)
            return;

        var filter = __instance.Side.Value switch
        {
            Chirality.Left => LeftHand,
            Chirality.Right => RightHand,
            _ => null
        };
        if (filter == null)
            return;

        var worldHandler = focusedWorld.LocalUser?.Root?.GetRegisteredComponent(filter);
        if (worldHandler == null || !worldHandler.IsUnderLocalUser)
            return;

        // Read the actual menu toggle, not LaserEnabled: world tools can temporarily
        // require a laser even when the user's toggle is off. Keep the equivalent
        // exception for tools in userspace, just as the original getter does.
        // No Sync fields are written across worlds, and no dashboard state is saved.
        __result = worldHandler._laserEnabled.Value || (__instance.ActiveTool?.UsesLaser ?? false);
    }
}
