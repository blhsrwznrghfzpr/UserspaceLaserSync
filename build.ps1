[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$artifactDirectory = Join-Path $PSScriptRoot 'artifacts'
[xml]$buildProperties = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Directory.Build.props') -Raw
$version = $buildProperties.Project.PropertyGroup.Version

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

    New-Item -ItemType Directory -Path $artifactDirectory -Force | Out-Null
    foreach ($loader in @('Bepis', 'RML')) {
        Invoke-DotNet -Arguments @(
            'publish', "$loader/UserspaceLaserSync.$loader.csproj", '--configuration', $Configuration,
            '-p:ResoniteInstallOnBuild=false', '-p:ResoniteGenerateReleaseArchive=true'
        )

        $archiveName = "UserspaceLaserSync.$loader-$version-$Configuration.zip"
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot "$loader/bin/publish/$archiveName") -Destination $artifactDirectory -Force
        Get-Item -LiteralPath (Join-Path $artifactDirectory $archiveName) | Select-Object Name, Length
    }
} finally {
    Pop-Location
}
