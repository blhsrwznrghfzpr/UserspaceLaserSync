[CmdletBinding()]
param(
    [switch]$Build,
    [switch]$DryRun,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
Push-Location -LiteralPath $PSScriptRoot
try {
    if ($Build) {
        & (Join-Path $PSScriptRoot 'build.ps1') -Configuration Release
    }

    [xml]$props = Get-Content -LiteralPath 'Directory.Build.props' -Raw
    $version = [string]$props.Project.PropertyGroup.Version
    $package = Get-Content -LiteralPath 'Thunderstore/package.json' -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -or
        $package.name -cnotmatch '^[a-zA-Z0-9_]{1,128}$' -or
        $package.team -cnotmatch '^[a-zA-Z0-9_]+$' -or
        $package.community -cne 'resonite') {
        throw 'Invalid package identity, version, or community.'
    }
    if (@($package.categories).Count -eq 0) { throw 'Specify category slugs in Thunderstore/package.json.' }
    foreach ($category in $package.categories) {
        if ($category -cnotmatch '^[a-z0-9-]+$') { throw "Invalid category slug: $category" }
    }

    $archivePath = Join-Path $PSScriptRoot "artifacts/UserspaceLaserSync.Thunderstore-$version-Release.zip"
    if (!(Test-Path -LiteralPath $archivePath -PathType Leaf)) {
        throw "Release ZIP not found: $archivePath. Run build.ps1 first, or use -Build."
    }

    # Check the exact archive being uploaded, including stale metadata after edits.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        foreach ($entry in @('manifest.json', 'README.md', 'CHANGELOG.md', 'icon.png',
            'plugins/UserspaceLaserSync/UserspaceLaserSync.dll')) {
            if ($null -eq $zip.GetEntry($entry)) { throw "Missing ZIP entry: $entry" }
        }
        $reader = New-Object IO.StreamReader($zip.GetEntry('manifest.json').Open())
        try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        if ($manifest.version_number -cne $version) { throw 'ZIP version differs from Directory.Build.props. Rebuild the package.' }
        foreach ($field in @('name', 'description', 'website_url')) {
            if ($manifest.$field -cne $package.$field) { throw "ZIP $field differs from package.json. Rebuild the package." }
        }
        if (($manifest.dependencies -join "`n") -cne ($package.dependencies -join "`n")) {
            throw 'ZIP dependencies differ from package.json. Rebuild the package.'
        }
    } finally {
        $zip.Dispose()
    }

    $config = Get-Content -LiteralPath 'Thunderstore/publish.toml.template' -Raw -Encoding UTF8
    $values = @{
        team = $package.team
        name = $package.name
        version = $version
        community = $package.community
        categories = (($package.categories | ForEach-Object { '"' + $_ + '"' }) -join ', ')
    }
    foreach ($key in $values.Keys) { $config = $config.Replace('{{' + $key + '}}', $values[$key]) }
    # Ignore the template's introductory comment when looking for unexpanded values.
    if (($config -split "`n" | Where-Object { $_ -notmatch '^\s*#' }) -match '\{\{') {
        throw 'Unresolved placeholder in publish.toml.template.'
    }
    $configPath = Join-Path $PSScriptRoot 'artifacts/thunderstore.publish.toml'
    [IO.File]::WriteAllText($configPath, $config, (New-Object Text.UTF8Encoding($false)))
    $arguments = @('publish', '--config-path', $configPath, '--file', $archivePath)

    Write-Host "Package: $($package.team)-$($package.name)-$version"
    Write-Host "Community: $($package.community); categories: $($package.categories -join ', ')"
    Write-Host "ZIP: $archivePath"
    Write-Host "SHA256: $((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash)"
    if ($DryRun) {
        Write-Host "Dry run: tcli publish --config-path `"$configPath`" --file `"$archivePath`""
        return
    }

    $tcli = Get-Command tcli -CommandType Application -ErrorAction SilentlyContinue
    if ($null -eq $tcli) { throw 'TCLI is not installed. Run: dotnet tool install --global tcli' }
    $originalToken = $env:TCLI_AUTH_TOKEN
    $secret = $null
    try {
        if ([string]::IsNullOrWhiteSpace($originalToken)) {
            if ($NonInteractive) { throw 'Set TCLI_AUTH_TOKEN before using -NonInteractive.' }
            $secret = Read-Host 'Thunderstore API token' -AsSecureString
            $env:TCLI_AUTH_TOKEN = (New-Object System.Net.NetworkCredential('', $secret)).Password
            if ([string]::IsNullOrWhiteSpace($env:TCLI_AUTH_TOKEN)) { throw 'An API token is required.' }
        }
        # Keep credentials out of command arguments, generated files, and output.
        & $tcli.Source @arguments
        if ($LASTEXITCODE -ne 0) { throw "TCLI publish failed with exit code $LASTEXITCODE." }
    } finally {
        $env:TCLI_AUTH_TOKEN = $originalToken
        if ($null -ne $secret) { $secret.Dispose() }
    }
} finally {
    Pop-Location
}
