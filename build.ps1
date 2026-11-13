[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$artifactDirectory = Join-Path $PSScriptRoot 'artifacts'
[xml]$buildProperties = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Directory.Build.props') -Raw
$version = $buildProperties.Project.PropertyGroup.Version
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Invoke-DotNet {
    param([string[]]$Arguments)

    & dotnet @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

# Resolve global.json consistently, including when invoked from another directory.
Push-Location -LiteralPath $PSScriptRoot
try {
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
            # Gale supplies the plugin directory. Import only this mod's files;
            # prerequisites are managed through the manifest dependencies.
            $manifest = [ordered]@{
                name = 'UserspaceLaserSync'
                author = $buildProperties.Project.PropertyGroup.Authors
                version_number = $version
                website_url = 'https://github.com/blhsrwznrghfzpr/UserspaceLaserSync'
                description = 'Synchronizes userspace laser toggles with the focused world lasers. BepisLoader version.'
                dependencies = @('ResoniteModding-BepisLoader-1.7.0', 'ResoniteModding-BepInExResoniteShim-0.9.3')
            }
            $pluginDirectory = Join-Path $PSScriptRoot 'Bepis/bin/publish/mod/client/BepInEx/plugins/UserspaceLaserSync'
            $files = @(
                (Join-Path $PSScriptRoot 'icon.png'),
                (Join-Path $PSScriptRoot 'README.md'),
                (Join-Path $pluginDirectory 'UserspaceLaserSync.dll'),
                (Join-Path $pluginDirectory 'UserspaceLaserSync.pdb')
            )
            foreach ($file in $files) {
                if (!(Test-Path -LiteralPath $file -PathType Leaf)) {
                    throw "Missing Gale package file: $file"
                }
            }

            $galeArchivePath = Join-Path $artifactDirectory "UserspaceLaserSync.Gale-$version-$Configuration.zip"
            $stream = [IO.File]::Open($galeArchivePath, [IO.FileMode]::Create)
            $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
            try {
                $manifestEntry = $zip.CreateEntry('manifest.json')
                $writer = New-Object IO.StreamWriter($manifestEntry.Open(), (New-Object Text.UTF8Encoding($false)))
                try {
                    $writer.Write(($manifest | ConvertTo-Json -Depth 4))
                } finally {
                    $writer.Dispose()
                }
                foreach ($file in $files) {
                    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file, [IO.Path]::GetFileName($file)) | Out-Null
                }
            } finally {
                $zip.Dispose()
                $stream.Dispose()
            }
            Get-Item -LiteralPath $galeArchivePath | Select-Object Name, Length
        }
    }
} finally {
    Pop-Location
}
