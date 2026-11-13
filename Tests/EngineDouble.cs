using Renderite.Shared;
using System.Runtime.CompilerServices;

// Minimal stand-ins for the dependencies of the linked production patch.
// Harmony patches this double's getter. Resonite itself is not loaded here.
namespace Renderite.Shared
{
    enum Chirality { Left, Right }
}

namespace FrooxEngine
{
    class Sync<T> { public T Value = default!; }
    interface ITool { bool UsesLaser { get; } }

    // Userspace equips this tool by default. Its unconditional UsesLaser caused
    // the original bug, so it must be represented separately from other tools.
    class UserspacePointer : ITool { public bool UsesLaser => true; }
    class LaserTool : ITool { public bool UsesLaser => true; }
    class NonLaserTool : ITool { public bool UsesLaser => false; }

    class InteractionHandler
    {
        public bool IsRemoved { get; set; }
        public bool IsUnderLocalUser;
        public World World = null!;
        public Engine Engine = null!;
        public Sync<Chirality> Side = new();
        public Sync<bool> _laserEnabled = new();
        public ITool? ActiveTool;
        public bool LaserEnabled
        {
            [MethodImpl(MethodImplOptions.NoInlining)]
            get => _laserEnabled.Value || (ActiveTool?.UsesLaser ?? false);
        }
    }

    static class Userspace { public static World UserspaceWorld = null!; }
    class World { public bool IsDestroyed; public User? LocalUser; }
    class User { public UserRoot? Root; }
    class UserRoot
    {
        public List<InteractionHandler> Handlers = [];
        public InteractionHandler? GetRegisteredComponent(Predicate<InteractionHandler> filter) => Handlers.Find(filter);
    }
    class Engine { public WorldManager WorldManager = new(); }
    class WorldManager { public World? FocusedWorld; }
}
