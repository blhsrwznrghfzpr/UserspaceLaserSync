[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$artifactDirectory = Join-Path $PSScriptRoot 'artifacts'
[xml]$buildProperties = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Directory.Build.props') -Raw
$version = $buildProperties.Project.PropertyGroup.Version
$package = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Thunderstore/package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Invoke-DotNet {
    param([string[]]$Arguments)

    & dotnet @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Assert-PackageInputs {
    if ($version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
        throw 'Version must use the Thunderstore Major.Minor.Patch format.'
    }
    if ($package.name -cnotmatch '^[a-zA-Z0-9_]{1,128}$' -or $package.team -cnotmatch '^[a-zA-Z0-9_]+$') {
        throw 'Invalid Thunderstore package or team name.'
    }
    if ([string]::IsNullOrWhiteSpace($package.description) -or $package.description.Length -gt 250) {
        throw 'Thunderstore description must contain 1 to 250 characters.'
    }
    if ($package.community -ne 'resonite' -or @($package.categories).Count -eq 0) {
        throw 'Specify the Resonite community and upload categories in Thunderstore/package.json.'
    }
    foreach ($dependency in $package.dependencies) {
        if ($dependency -cnotmatch '^[a-zA-Z0-9_]+-[a-zA-Z0-9_]+-[0-9]+\.[0-9]+\.[0-9]+$') {
            throw "Invalid dependency string: $dependency"
        }
    }
    $utf8 = New-Object Text.UTF8Encoding($false, $true)
    foreach ($file in @('README.md', 'Thunderstore/README.md', 'CHANGELOG.md')) {
        $text = [IO.File]::ReadAllText((Join-Path $PSScriptRoot $file), $utf8)
        if ([string]::IsNullOrWhiteSpace($text)) { throw "Empty package document: $file" }
    }
    $changelog = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'CHANGELOG.md'), $utf8)
    if ($changelog -notmatch ('(?m)^## ' + [regex]::Escape($version) + '\r?$')) {
        throw "Add a ## $version entry to CHANGELOG.md before packaging."
    }
    # PNG signature, IHDR chunk, and big-endian 256x256 dimensions. This also
    # works without System.Drawing on non-Windows PowerShell installations.
    $icon = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'icon.png'))
    if ($icon.Length -lt 24 -or
        [BitConverter]::ToString($icon, 0, 8) -ne '89-50-4E-47-0D-0A-1A-0A' -or
        [BitConverter]::ToString($icon, 12, 12) -ne '49-48-44-52-00-00-01-00-00-00-01-00') {
        throw 'icon.png must be a 256x256 PNG.'
    }
}

function New-ModArchive {
    param(
        [string]$ArchiveName,
        [System.Collections.IDictionary]$Manifest,
        [System.Collections.IDictionary]$Files
    )

    foreach ($file in $Files.Values) {
        if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing package file: $file" }
    }
    $archivePath = Join-Path $artifactDirectory $ArchiveName
    # Preserve the previous archive if writing the replacement fails.
    $temporaryPath = $archivePath + '.tmp'
    $stream = [IO.File]::Open($temporaryPath, [IO.FileMode]::Create)
    $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $writer = New-Object IO.StreamWriter($zip.CreateEntry('manifest.json').Open(), (New-Object Text.UTF8Encoding($false)))
        try { $writer.Write(($Manifest | ConvertTo-Json -Depth 4)) } finally { $writer.Dispose() }
        foreach ($entry in $Files.Keys) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $Files[$entry], $entry) | Out-Null
        }
    } finally {
        $zip.Dispose()
        $stream.Dispose()
    }
    Move-Item -LiteralPath $temporaryPath -Destination $archivePath -Force
    Get-Item -LiteralPath $archivePath | Select-Object Name, Length
}

# Resolve global.json consistently, including when invoked from another directory.
Push-Location -LiteralPath $PSScriptRoot
try {
    Assert-PackageInputs
    # Run the shared behavior checks before producing either loader's distribution.
    Invoke-DotNet -Arguments @(
        'run', '--project', 'Tests/UserspaceLaserSync.Tests.csproj',
        '--configuration', $Configuration
    )
    Invoke-DotNet -Arguments @(
        'run', '--project', 'Tests/UserspaceLaserSync.Tests.csproj',
        '--configuration', $Configuration, '-p:UseHarmonyX=true'
    )

    New-Item -ItemType Directory -Path $artifactDirectory -Force | Out-Null
    foreach ($loader in @('Bepis', 'RML')) {
        Invoke-DotNet -Arguments @(
            'publish', "$loader/UserspaceLaserSync.$loader.csproj", '--configuration', $Configuration,
            '-p:ResoniteInstallOnBuild=false', '-p:ResoniteGenerateReleaseArchive=true'
        )

        $archiveName = "UserspaceLaserSync.$loader-$version-$Configuration.zip"
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot "$loader/bin/publish/$archiveName") -Destination $artifactDirectory -Force
        Get-Item -LiteralPath (Join-Path $artifactDirectory $archiveName) | Select-Object Name, Length

        if ($loader -eq 'Bepis') {
            # Thunderstore and Gale share package metadata. Version is generated
            # from Directory.Build.props; team/community/categories are upload settings.
            $manifest = [ordered]@{
                name = $package.name
                version_number = $version
                website_url = $package.website_url
                description = $package.description
                dependencies = @($package.dependencies)
            }
            $pluginDirectory = Join-Path $PSScriptRoot 'Bepis/bin/publish/mod/client/BepInEx/plugins/UserspaceLaserSync'
            $dllPath = Join-Path $pluginDirectory 'UserspaceLaserSync.dll'
            if ([Reflection.AssemblyName]::GetAssemblyName($dllPath).Version.ToString(3) -ne $version) {
                throw 'Published Bepis DLL version does not match Directory.Build.props.'
            }
            $files = [ordered]@{
                'icon.png' = Join-Path $PSScriptRoot 'icon.png'
                'README.md' = Join-Path $PSScriptRoot 'Thunderstore/README.md'
                'CHANGELOG.md' = Join-Path $PSScriptRoot 'CHANGELOG.md'
                'plugins/UserspaceLaserSync/UserspaceLaserSync.dll' = $dllPath
                'plugins/UserspaceLaserSync/UserspaceLaserSync.pdb' = Join-Path $pluginDirectory 'UserspaceLaserSync.pdb'
            }
            New-ModArchive -ArchiveName "UserspaceLaserSync.Thunderstore-$version-$Configuration.zip" -Manifest $manifest -Files $files

            # Keep Gale's existing flat layout for local imports.
            $galeManifest = [ordered]@{}
            foreach ($key in $manifest.Keys) { $galeManifest[$key] = $manifest[$key] }
            $galeManifest['author'] = [string]$buildProperties.Project.PropertyGroup.Authors
            $galeFiles = [ordered]@{}
            foreach ($entry in $files.Keys) { $galeFiles[[IO.Path]::GetFileName($entry)] = $files[$entry] }
            New-ModArchive -ArchiveName "UserspaceLaserSync.Gale-$version-$Configuration.zip" -Manifest $galeManifest -Files $galeFiles
        }
    }
    Write-Host "Thunderstore upload: team=$($package.team), community=$($package.community), categories=$($package.categories -join ', ')"
} finally {
    Pop-Location
}
