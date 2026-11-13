# UserspaceLaserSync

Make your Userspace lasers follow the laser toggles in the world you are currently using. This includes the dashboard, facets, and facet anchors. Left and right hands are handled independently.

This package is for **BepisLoader**. The separate ResoniteModLoader build is available from [GitHub Releases](https://github.com/blhsrwznrghfzpr/UserspaceLaserSync/releases). Install only one build.

## Usage

1. Install this package using a Resonite-compatible Thunderstore mod manager, such as Gale. BepisLoader and BepInExResoniteShim are declared dependencies.
2. Launch Resonite and toggle a hand's laser from the normal world's context menu.
3. Close the context menu. The same hand's Userspace laser follows that toggle.

Changing worlds or avatars uses the current focused world's local user. If a matching world or hand is unavailable, the mod leaves the original behavior unchanged.

This is not a complete laser-hiding mod: actual tools that require lasers and the normal context-menu exceptions remain available. The default UserspacePointer follows the world toggle. The mod does not write either world's toggle, change other users' settings, or modify saved dashboard data.

## Configuration

For in-game settings, install and enable [BepisModSettings](https://thunderstore.io/c/resonite/p/ResoniteModding/BepisModSettings/), then open **UserspaceLaserSync → General → Enabled**. BepisModSettings is optional; it is needed for the in-game settings UI, not for the laser synchronization itself.

| Setting | Default | Behavior |
| --- | --- | --- |
| `Enabled` | `true` | Synchronize Userspace lasers with the focused world's toggles. |

Changes through the settings UI apply immediately. With `Enabled=false`, the original Resonite laser decision is preserved. Turning it back on follows the latest world toggle; it does not restore an old value or force lasers off.

The configuration file is `BepInEx/config/dev.blhsrwznrghfzpr.UserspaceLaserSync.cfg`. If editing the file directly, exit Resonite first and restart after editing.

## Validation and support

Both loader builds pass compilation. The shared patch passes 175 checks with Harmony and another 175 with HarmonyX against an engine test double, including switching Enabled ON → OFF → ON. These checks do not replace in-game testing; in-game validation of this release is still pending. Resonite updates can affect compatibility.

Report problems, including the Resonite version, loader version, and relevant log, on [GitHub Issues](https://github.com/blhsrwznrghfzpr/UserspaceLaserSync/issues).

AI assistance was used for the code and icon.

## 日本語

通常ワールドの左右のレーザーON/OFFに、Userspaceのダッシュ・Facet・Facet Anchorsのレーザーを連動させます。ワールド移動やアバター変更後も、現在フォーカスしているワールドの状態に追従します。

ゲーム内で切り替える場合はBepisModSettingsを導入・有効化し、**UserspaceLaserSync → General → Enabled** を変更してください。OFFにすると即時にResonite標準の判定へ戻り、再ONで最新のワールドのトグルへ追従します。通常ワールドとUserspaceのトグル値そのものは書き換えません。

レーザーを必要とするツールやコンテキストメニューの例外は維持します。完全なレーザー非表示Modではありません。BepisLoader版とRML版はどちらか一方だけ導入してください。
