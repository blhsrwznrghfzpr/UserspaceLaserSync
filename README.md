# UserspaceLaserSync

通常ワールドのレーザーON/OFFに、Userspace（ダッシュメニュー、Facet、Facet Anchorsなど）のレーザーを連動させるResonite Modです。

## 動作

- 通常ワールドの既存コンテキストメニューからレーザーを切り替えると、同じ手のUserspaceレーザーも追従します。左右は個別に扱います。
- 現在フォーカスしているワールドのローカルユーザーの状態を参照します。ワールド移動やアバター変更後は、その時点の状態に追従します。
- 対応するワールドや手が見つからない間は、元の動作に戻ります。
- レーザーを必要とするUserspace内のツール、およびコンテキストメニュー操作時の例外はResonite標準の動作を維持します。完全なレーザー非表示Modではありません。
- Userspaceに常時装備される標準の `UserspacePointer` はツールの例外から除外し、通常ワールドのトグルに追従させます。
- Userspace側の判定を通常ワールドのトグルに連動させます。Userspaceから通常ワールドへ逆方向に書き戻す機能はありません。
- ダッシュの保存データや、他ユーザーのレーザー設定は変更しません。
- `Enabled` は既定でONです。設定UIでOFFにすると即時に同期を停止し、Resonite標準のレーザー判定をそのまま使います。再びONにすると、その時点の通常ワールドのトグルに追従します。切り替え時にどちらの空間のトグルも書き換えません。

Resoniteでの空間名は[Userspace](https://wiki.resonite.com/Userspace)です。[FacetとFacet Anchors](https://wiki.resonite.com/Facets)もこの空間に存在します。

## 必要環境・導入

BepisLoader版とRML版があります。利用するローダーに合う版を**どちらか一方だけ**導入してください。両方ともResoniteエンジン側のModで、Unity Renderer側への導入は不要です。

### BepisLoader版

BepisLoaderを導入した環境で、配布ZIP内の `BepInEx/plugins/UserspaceLaserSync/` をResoniteまたはModプロファイルの同じ場所に展開して起動します。

Galeで管理する場合は、`UserspaceLaserSync.Gale-<Version>-Release.zip` をローカルModとしてインポートします。Bepis版のDLLに加えて、名前・バージョン・依存Modを記載した `manifest.json`、アイコン、READMEを含みます。手動配置用のBepis版ZIPとGale用ZIPは同じModなので、導入方法に合う一方を使用してください。

ゲーム内で変更するには、BepisModSettingsを導入・有効化して、`UserspaceLaserSync` → `General` → `Enabled` を切り替えます。設定変更は即時反映され、再起動は不要です。OFFはレーザーの強制無効化ではなく、Modなしと同じ標準の判定へ戻す設定です。

設定ファイルは起動後に `BepInEx/config/dev.blhsrwznrghfzpr.UserspaceLaserSync.cfg` に生成されます。`[General]` の `Enabled` は既定で `true` です。ファイルを直接編集する場合はResoniteを終了してから編集し、再起動してください。

### RML版

ResoniteModLoader 5.0.1向けです。RMLとその指定するHarmonyを導入済みの環境で、配布ZIP内の `rml_mods/UserspaceLaserSync.dll` をResoniteまたはModプロファイルの `rml_mods` に配置して起動します。ZIPにRML本体やHarmonyは含みません。

RML設定の `Enabled` は既定で `true` です。ResoniteModSettingsなどから変更でき、設定UIでの切り替えは再起動なしで即時反映されます。OFFの間はResonite標準のレーザー判定を使います。通常のRMLでは設定の保存先は `rml_config/UserspaceLaserSync.json` です。設定ファイルを直接編集する場合はResoniteを終了してから編集し、再起動してください。

この版は `ResoniteModLoaderStandalone` を対象にビルドします。MonkeyLoaderのRML互換機能での動作は未検証です。

## ビルド

.NET 10 SDKと [Remora.Resonite.Sdk 2.3.4](https://www.nuget.org/packages/Remora.Resonite.Sdk/2.3.4) を使用します。SDK同梱の参照アセンブリはResonite `2026.8.27.1094` 向けです。以下はプロジェクトのルートディレクトリで実行します。

両ローダー版の検証・配布物作成:

```powershell
.\build.ps1
```

署名なしスクリプトの実行が制限されている環境では、今回のプロセスだけで許可して実行できます。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

共通処理の回帰チェックを実行してから、BepisLoader版とRML版を順にビルド・publishします。失敗するとそこで停止します。既定は `Release` で、両版の配布ZIPを `artifacts/` にまとめます。ゲームへの自動コピーは行いません。

両版とテストプロジェクトのビルドだけを行う場合は、ソリューションを指定します。このコマンドは回帰チェックの実行やZIP生成は行いません。

```powershell
dotnet build UserspaceLaserSync.slnx -c Release
```

個別にビルドする場合は、以下のプロジェクトを指定します。

BepisLoader版:

```powershell
dotnet build Bepis/UserspaceLaserSync.Bepis.csproj -c Release
dotnet publish Bepis/UserspaceLaserSync.Bepis.csproj -c Release
```

RML版:

```powershell
dotnet build RML/UserspaceLaserSync.RML.csproj -c Release
dotnet publish RML/UserspaceLaserSync.RML.csproj -c Release
```

| 対象 | 配布ZIP |
| --- | --- |
| BepisLoader | `artifacts/UserspaceLaserSync.Bepis-<Version>-Release.zip` |
| Gale（BepisLoader） | `artifacts/UserspaceLaserSync.Gale-<Version>-Release.zip` |
| RML | `artifacts/UserspaceLaserSync.RML-<Version>-Release.zip` |

上記は `build.ps1` の出力先です。個別の `dotnet publish` では各ローダーフォルダの `bin/publish/` に手動配置用ZIPを生成します。Gale用ZIPは `build.ps1` で生成します。

`<Version>` は `Directory.Build.props` の `Version` です。リリース時のバージョン変更はこの1か所で行います。両版のアセンブリ・配布ZIPに加え、BepisLoaderのプラグイン属性はSDKが生成する `PluginMetadata.VERSION`、RMLの表示バージョンはアセンブリのバージョンから取得します。

BepisLoader版DLL: `Bepis/bin/Release/mod/client/BepInEx/plugins/UserspaceLaserSync/UserspaceLaserSync.dll`

RML版DLL: `RML/bin/Release/mod/client/rml_mods/UserspaceLaserSync.dll`

通常のビルドではゲームへの自動コピーを行いません。ローカル導入先を指定する場合は、対象プロジェクトのビルドに `-p:ResoniteInstallOnBuild=true -p:ResonitePath="D:\Path\To\Resonite"` を追加します。

## 回帰チェック

```powershell
dotnet run --project Tests/UserspaceLaserSync.Tests.csproj -c Release
dotnet run --project Tests/UserspaceLaserSync.Tests.csproj -c Release -p:UseHarmonyX=true
```

本体の `Shared/*.cs` を直接コンパイルし、`Tests/EngineDouble.cs` のエンジン代替実装を使って確認します。HarmonyとHarmonyXの両方で、実際のパッチを適用したgetterを検証します。左右・両空間のトグル・ツールの32通りについて、ON→OFFでパッチ前と同じ結果に戻ること、トグル値を書き換えないこと、再ONで最新の値に追従することを確認します。既存の対象範囲チェックと合わせて各175項目を実行し、失敗時は非ゼロの終了コードを返します。テスト用コードは両ローダー版のDLLには含まれません。`build.ps1` も両方のチェックを実行します。

これはエンジン代替実装でのチェックです。各ローダーの設定UIとの連携、Resonite APIとの実行時互換性、3DDashOnScreen併用時の動作は下記の実機確認が必要です。

## プロジェクト構成

```text
UserspaceLaserSync/
├─ Bepis/
│  ├─ Plugin.cs
│  └─ UserspaceLaserSync.Bepis.csproj
├─ RML/
│  ├─ Mod.cs
│  └─ UserspaceLaserSync.RML.csproj
├─ Shared/
│  ├─ LaserEnabledPatch.cs
│  └─ LaserSyncRuntime.cs
├─ Tests/
│  ├─ EngineDouble.cs
│  ├─ Program.cs
│  └─ UserspaceLaserSync.Tests.csproj
├─ artifacts/                  # build.ps1の配布ZIP（Git管理外）
├─ Directory.Build.props      # バージョンと共通設定
├─ Directory.Build.targets    # 両版にShared/*.csを取り込む
├─ global.json                # Remora SDKバージョン
├─ UserspaceLaserSync.slnx
└─ build.ps1
```

`Bepis/Plugin.cs` と `RML/Mod.cs` が各ローダーの起動・設定処理を担当します。起動時と設定変更時に `Shared/LaserSyncRuntime.cs` の有効状態を更新し、共通パッチがローダーの入口クラスに依存しない構成にしています。

## 実機確認項目

ビルド検証とゲーム内での動作確認は別です。以下は実機確認が必要です。

1. VRで左手のレーザーをOFFにし、左手からダッシュとFacet Anchorsをレーザー操作できなくなること。右手は従来どおり操作できること。
2. 同じコンテキストメニューからONに戻し、Userspaceの操作が復帰すること。右手でも同様に確認すること。
3. OFFのままダッシュやFacet Anchorsを開閉しても、通常ワールドの状態に追従すること。
4. ワールド切り替え・退出・アバター変更後に、その時点のワールドのトグル状態へ追従すること。
5. ツール使用時とコンテキストメニュー操作時の標準の例外が維持されること。
6. デスクトップモードでもダッシュとキーボードが操作でき、VRとの切り替えで異常がないこと。
7. 通常ワールドのレーザーをOFFにした状態で、設定UIの `Enabled` をOFFにすると標準のUserspaceレーザー操作に戻り、再ONで同期が再開すること。両ローダーで再起動なしに確認すること。`Enabled=false` を保存して再起動した場合も標準の動作になること。
8. 3DDashOnScreen併用のデスクトップモードで、操作する手の通常ワールドのレーザーをOFFにすると3Dダッシュへのレーザー操作が止まり、ONで復帰すること。コンテキストメニューを閉じて確認すること。

## 変更履歴

### 1.0.0

- BepisLoader版・ResoniteModLoader版の初回正式リリース。
- 通常ワールドの左右のレーザートグルとUserspaceのレーザーを連動させます。
- `Enabled` 設定は即時反映され、OFF時はResonite標準の判定を使います。
- アイコン付きGale用ZIPの生成をビルドスクリプトに追加しました。バージョンは共通設定から取得します。

### 0.1.2

- 両ローダーの `Enabled` 設定変更をイベントで共通処理へ反映するよう整理しました。無効時は元のgetterの結果を変更せず、有効化し直すと最新のワールドのトグルへ追従します。
- Harmony / HarmonyXでのON→OFF→ONと、無効時のパッチ前後の結果一致を検証する回帰チェックを追加しました。

### 0.1.1

- 標準の `UserspacePointer.UsesLaser` が常に `true` のため、通常ワールドのトグルがOFFでもUserspaceのレーザーが有効になっていた問題を修正しました。両ローダー共通の修正です。3DDashOnScreen併用環境からの報告をもとに修正していますが、ゲーム内での動作確認は別途必要です。

## 実装

Harmonyで `InteractionHandler.LaserEnabled` のgetterにPostfixを追加しています。ローカルユーザーのUserspaceハンドラだけを対象に、フォーカス中のワールドの同じ手の `_laserEnabled` を読みます。ツール使用による一時的なレーザー有効化と、ユーザーが選んだON/OFFを区別するため、ワールド側のgetterではなくトグル値を参照します。

Resonite内部APIへの依存があるため、Resoniteの更新後には再検証が必要です。

レーザー判定の実装は `Shared/LaserEnabledPatch.cs` を両プロジェクトから共有し、起動処理と設定APIのみローダー別に実装しています。
