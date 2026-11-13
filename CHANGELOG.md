# Changelog

## 1.0.1

- Add a dedicated Thunderstore package with loader dependencies, documentation, and the Resonite plugin directory layout.
- Share package metadata between Thunderstore and Gale and validate release inputs before packaging.
- Add a publishing script with dry-run support and a separate Thunderstore release guide.
- No changes to laser synchronization or Enabled behavior.

## 1.0.0

- Initial release for BepisLoader and ResoniteModLoader.
- Synchronize each Userspace laser with the same hand's laser toggle in the focused world.
- Preserve the standard Resonite laser decision while `Enabled` is off; apply in-game setting changes immediately.
- Exclude the always-equipped UserspacePointer from the laser-tool exception so the world toggle can disable the pointer.
- Provide an icon and packages for manual installation and mod managers.

## 0.1.2

- Reflect Enabled changes through each loader's configuration events.
- Add Harmony and HarmonyX regression checks for ON/OFF/ON transitions and the original getter result when disabled.

## 0.1.1

- Fix UserspacePointer keeping Userspace lasers enabled while the world's laser toggle is off.
