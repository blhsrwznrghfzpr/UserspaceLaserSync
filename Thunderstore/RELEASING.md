# Thunderstoreへのリリース手順

この文書のファイルパスとコマンドは、リポジトリのルートを基準にしています。

公開データの編集元:

| ファイル | 編集する内容 |
| --- | --- |
| `Directory.Build.props` | リリースバージョン（唯一の定義元） |
| `Thunderstore/package.json` | Team・Community・カテゴリ識別子・名前・説明・URL・依存Mod |
| `Thunderstore/publish.toml.template` | TCLIの公開設定テンプレート（公開先URL・NSFW指定など） |
| `Thunderstore/README.md` | ThunderstoreとGaleに表示するBepis版の説明 |
| `CHANGELOG.md` | 新しいバージョンの変更履歴 |
| `icon.png` | 共通アイコン（256×256 PNG） |

`Thunderstore/package.json` はこのプロジェクトのビルド・公開スクリプト用の設定ファイルです。Thunderstoreに送信する `manifest.json` は、ここから公開用の項目だけを選び、共通バージョンを加えてZIP内に生成します。Galeのmanifestも同じ情報から生成するため、依存Modや説明を二重管理しません。Team・Community・カテゴリは公開先の指定であり、manifestには含めません。

1. 次のリリースでは `Directory.Build.props` の `Version` を更新し、`CHANGELOG.md` に `## <Version>` の見出しと変更内容を追加します。必要に応じて公開用READMEも更新します。
2. `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1` を実行します。必須ファイル・UTF-8文書・PNG寸法・manifestの名前や説明・バージョン・依存指定の形式・変更履歴の見出し・Bepis DLLのバージョンを確認します。
3. `artifacts/UserspaceLaserSync.Thunderstore-<Version>-Release.zip` を新しいGaleプロファイルに読み込み、ゲーム内で動作確認します。現時点での自動チェックは実機確認を代替しません。
4. [Thunderstoreアップロード画面](https://thunderstore.io/package/create/)で、そのZIPと以下の公開先を選択します。

- Team: `blhsrwznrghfzpr`
- Community: `Resonite`
- Categories: `Mods`、`Controls`、`Dashboard`、`AI Generated`

ZIPの構成:

```text
manifest.json
README.md
CHANGELOG.md
icon.png
plugins/
  UserspaceLaserSync/
    UserspaceLaserSync.dll
    UserspaceLaserSync.pdb
```

Thunderstore用ZIPは、このModのDLL/PDBと公開用文書・アイコンだけを含みます。BepisLoader本体や他ModのDLLは依存指定から導入します。BepisModSettingsはゲーム内設定UI用の任意ModとしてREADMEで案内しています。

WebアップロードではTCLIやAPIトークンは不要です。`build.ps1` はZIP生成までを行います。[Thunderstoreのパッケージ仕様](https://wiki.thunderstore.io/mods/creating-a-package)と[Resoniteの公開ガイド](https://modding.resonite.net/creating-a-mod/packaging-and-publishing/)に沿った構成です。

## コマンドからの公開

以下を順に進めます。公開対象はBepisLoader版です。RML版はGitHub Releasesで別に配布します。

### 1. 初回設定

PowerShellでプロジェクトへ移動し、[TCLI](https://github.com/thunderstore-io/thunderstore-cli)をインストールします。インストールは初回のみ必要です。

```powershell
Set-Location D:\src\UserspaceLaserSync
dotnet tool install --global tcli
```

Thunderstoreにログインし、**Settings → Teams → blhsrwznrghfzpr → Service Accounts → Add service account** でAPIトークンを作成します。表示は一度だけなので保管してください。トークンは手順4で入力します。

### 2. リリース情報を更新

Thunderstoreへの初回公開では、`Directory.Build.props` の現在のバージョンが未使用なら、そのまま公開できます。更新の場合は `Version` を上げ、`CHANGELOG.md` に `## <Version>` の見出しと変更内容を追加します。必要に応じて `Thunderstore/README.md` と `Thunderstore/package.json` も更新します。

GitHub ReleasesとThunderstoreの公開状況は別管理です。Thunderstoreで同じバージョンを公開済みなら上書きできません。更新時もTeamとMod名は維持します。

### 3. ビルドと動作確認

```powershell
Set-Location D:\src\UserspaceLaserSync
powershell -NoProfile -ExecutionPolicy Bypass -File .\publish.ps1 -Build -DryRun
```

テスト・Releaseビルド・ZIP生成・公開内容の確認まで実行し、アップロードはしません。失敗した場合は原因を修正して再実行します。

生成された `artifacts/UserspaceLaserSync.Thunderstore-<Version>-Release.zip` を新しいGaleプロファイルに読み込み、依存Modとともに起動できること、左右のレーザー連動、`Enabled` のOFF/ON、ログに関連エラーがないことを確認します。詳しくは[実機確認項目](../README.md#実機確認項目)を参照してください。ソースや公開文書を修正した場合は再ビルドし、そのZIPで確認し直します。

### 4. 確認済みZIPを公開

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\publish.ps1
```

`Thunderstore API token:` と表示されたら、手順1のトークンを貼り付けてEnterを押します。入力内容は表示されません。環境変数 `TCLI_AUTH_TOKEN` を設定済みなら、その値を使って入力なしで公開します。

このコマンドは再ビルドせず、手順3で確認したZIPを公開します。表示されるTeam・Mod名・バージョン・Community・カテゴリを確認してください。公開先は `blhsrwznrghfzpr` / `resonite` です。

### 5. 公開結果を確認

[Teamの公開一覧](https://thunderstore.io/c/resonite/p/blhsrwznrghfzpr/)からUserspaceLaserSyncを開き、バージョン・アイコン・README・依存Mod・カテゴリを確認します。Galeの一覧からもインストールして起動を確認します。

公開コマンドが通信エラーなどで終了した場合も、再実行する前に公開一覧を確認してください。すでに対象バージョンが公開されていれば、同じバージョンを再送信する必要はありません。

### オプションと生成ファイル

`publish.ps1` は既存のThunderstore用Release ZIPを使用します。ZIPの必須エントリ・バージョン・パッケージ情報を検査し、公開先とSHA256を表示します。DLLやREADMEの内容がソースと同じかは検査しないため、変更後は `build.ps1` で作り直し、そのZIPをゲーム内で確認してください。

既存ZIPの検査と公開先の表示だけを行う場合は `powershell -NoProfile -ExecutionPolicy Bypass -File .\publish.ps1 -DryRun` を実行します。TCLIやトークンは不要で、通信も行いません。

`-Build` を付けると最初に `build.ps1` を実行します。`-Build -DryRun` はビルドと公開内容の確認まで行い、アップロードしません。`-Build` 単独ではビルド成功後にそのまま公開します。

Team・Mod名・バージョン・Community・カテゴリは既存の設定から取得し、`artifacts/thunderstore.publish.toml` を生成します。テンプレートをTCLIへ直接渡さず、スクリプトを使ってください。`package.json` のカテゴリには表示名ではなく `mods`、`controls`、`dashboard`、`ai-generated` のような識別子を指定します。バージョンや依存Modの二重管理は不要です。

配布ZIPと生成したTCLI設定を含む `artifacts/`、および `bin/`・`obj/` はGit管理外です。コミットにはソース・設定元・文書を含め、ビルド成果物は含めません。

認証には環境変数 `TCLI_AUTH_TOKEN` を使用し、未設定なら非表示入力を求めます。入力したトークンはファイルに保存せず、終了時に実行前の環境変数へ戻します。CIではシークレットから環境変数を設定して `-NonInteractive` を指定してください。トークン未設定なら入力待ちにせず失敗します。トークンはGitへコミットしないでください。

同じTeam・Mod名・バージョンを再アップロードして上書きすることはできません。公開済みなら `Directory.Build.props` のバージョンを上げ、変更履歴を追加して再ビルドします。[TCLIの認証・公開手順](https://github.com/thunderstore-io/thunderstore-cli/wiki#authentication)、[Thunderstoreの更新手順](https://wiki.thunderstore.io/mods/updating-a-package)も参照してください。
