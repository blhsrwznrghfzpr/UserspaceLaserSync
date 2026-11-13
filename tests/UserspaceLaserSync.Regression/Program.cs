using System.Reflection;
using FrooxEngine;
using Renderite.Shared;
using UserspaceLaserSync;

// Invoke the actual shared postfix with engine stand-ins; no game installation
// or loader is required. A failed assertion exits this executable with an error.
var postfix = typeof(LaserEnabledPatch).GetMethod("Postfix", BindingFlags.NonPublic | BindingFlags.Static)!;
var count = 0;
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
Plugin.IsSyncEnabled = false;
Check("disabled mod preserves true", true, pointer);
Check("disabled mod preserves false", false, pointer, false);
Plugin.IsSyncEnabled = true;
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
Console.WriteLine($"{count} regression checks passed.");
