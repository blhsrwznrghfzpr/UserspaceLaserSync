using System.Reflection;
using HarmonyLib;
using FrooxEngine;
using Renderite.Shared;
using UserspaceLaserSync;

// Invoke the actual shared postfix with engine stand-ins; no game installation
// or loader is required. A failed assertion exits this executable with an error.
var postfix = typeof(LaserEnabledPatch).GetMethod("Postfix", BindingFlags.NonPublic | BindingFlags.Static)!;
var count = 0;
LaserSyncRuntime.SetEnabled(true);
void Check(string name, bool expected, InteractionHandler handler, bool original = true)
{
    object[] args = [handler, original];
    postfix.Invoke(null, args);
    if ((bool)args[1] != expected)
        throw new Exception($"FAIL: {name}: expected {expected}, got {args[1]}");
    Console.WriteLine($"PASS: {name}");
    count++;
}

var world = new World();
var userspace = new World();
Userspace.UserspaceWorld = userspace;
var engine = new Engine();
engine.WorldManager.FocusedWorld = world;
InteractionHandler Handler(World w, Chirality side, bool enabled) => new()
{
    World = w, Engine = engine, Side = new() { Value = side },
    _laserEnabled = new() { Value = enabled }, IsUnderLocalUser = true
};
var left = Handler(world, Chirality.Left, false);
var right = Handler(world, Chirality.Right, true);
world.LocalUser = new() { Root = new() { Handlers = [left, right] } };
var pointer = Handler(userspace, Chirality.Left, true);
pointer.ActiveTool = new UserspacePointer();
Check("default UserspacePointer follows OFF", false, pointer);
pointer.Side.Value = Chirality.Right;
Check("other hand independently follows ON", true, pointer, false);
pointer.Side.Value = Chirality.Left;
left._laserEnabled.Value = true;
Check("re-enable restores pointer", true, pointer, false);
left._laserEnabled.Value = false;
pointer.ActiveTool = new LaserTool();
Check("actual laser tool keeps its exception", true, pointer, false);
pointer.ActiveTool = new NonLaserTool();
Check("non-laser tool follows OFF", false, pointer);
pointer.ActiveTool = null;
Check("no tool follows OFF", false, pointer);
pointer.ActiveTool = new UserspacePointer();
left.ActiveTool = new LaserTool();
Check("world tool does not override raw toggle", false, pointer);
LaserSyncRuntime.SetEnabled(false);
Check("disabled mod preserves true", true, pointer);
Check("disabled mod preserves false", false, pointer, false);
LaserSyncRuntime.SetEnabled(true);
Check("normal world untouched", true, left);
pointer.IsUnderLocalUser = false;
Check("remote user untouched", true, pointer);
pointer.IsUnderLocalUser = true;
engine.WorldManager.FocusedWorld = null;
Check("missing focused world falls back", true, pointer);
engine.WorldManager.FocusedWorld = world;
world.IsDestroyed = true;
Check("destroyed focused world falls back", true, pointer);
world.IsDestroyed = false;
world.LocalUser.Root.Handlers = [right];
Check("missing matching hand falls back", true, pointer);
engine.WorldManager.FocusedWorld = userspace;
Check("userspace focus falls back", true, pointer);
// Capture the real unpatched getter's result before installing the production
// Harmony patch. Compare it after ON -> OFF for each combination, including
// userspace's own toggle and the default pointer's unconditional UsesLaser.
engine.WorldManager.FocusedWorld = world;
world.LocalUser.Root.Handlers = [left, right];
var cases = new List<(InteractionHandler Handler, bool WorldToggle, bool NativeResult)>();
foreach (var side in new[] { Chirality.Left, Chirality.Right })
foreach (var worldToggle in new[] { false, true })
foreach (var userspaceToggle in new[] { false, true })
foreach (var tool in new ITool?[] { null, new UserspacePointer(), new LaserTool(), new NonLaserTool() })
{
    var handler = Handler(userspace, side, userspaceToggle);
    handler.ActiveTool = tool;
    cases.Add((handler, worldToggle, handler.LaserEnabled));
}

void AssertResult(string name, bool expected, bool actual)
{
    if (actual != expected)
        throw new Exception($"FAIL: {name}: expected {expected}, got {actual}");
    count++;
}

const string harmonyId = "UserspaceLaserSync.Tests";
var harmony = new Harmony(harmonyId);
try
{
    harmony.PatchAll(typeof(LaserEnabledPatch).Assembly);
    foreach (var test in cases)
    {
        var handler = test.Handler;
        var worldHandler = handler.Side.Value == Chirality.Left ? left : right;
        var userspaceToggle = handler._laserEnabled.Value;
        worldHandler._laserEnabled.Value = test.WorldToggle;
        var toolOverride = handler.ActiveTool is not UserspacePointer &&
            (handler.ActiveTool?.UsesLaser ?? false);

        LaserSyncRuntime.SetEnabled(true);
        AssertResult("enabled synchronization", test.WorldToggle || toolOverride, handler.LaserEnabled);
        LaserSyncRuntime.SetEnabled(false);
        AssertResult("disabled matches unpatched getter", test.NativeResult, handler.LaserEnabled);
        AssertResult("userspace toggle is not mutated", userspaceToggle, handler._laserEnabled.Value);
        AssertResult("world toggle is not mutated", test.WorldToggle, worldHandler._laserEnabled.Value);

        worldHandler._laserEnabled.Value = !test.WorldToggle;
        LaserSyncRuntime.SetEnabled(true);
        AssertResult("re-enabled follows latest world toggle", !test.WorldToggle || toolOverride, handler.LaserEnabled);
    }
    Console.WriteLine($"PASS: native getter comparison and live ON/OFF/ON for {cases.Count} combinations");
}
finally
{
    LaserSyncRuntime.SetEnabled(false);
    // Shared by Harmony and HarmonyX.
    harmony.Unpatch(AccessTools.PropertyGetter(typeof(InteractionHandler), nameof(InteractionHandler.LaserEnabled)),
        HarmonyPatchType.All, harmonyId);
}
Console.WriteLine($"{count} regression checks passed.");
