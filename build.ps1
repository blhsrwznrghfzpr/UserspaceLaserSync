[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'

function Invoke-DotNet {
    param([string[]]$Arguments)

    & dotnet @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

# Run the shared behavior checks before producing either loader's distribution.
Invoke-DotNet -Arguments @(
    'run', '--project', (Join-Path $PSScriptRoot 'tests/UserspaceLaserSync.Regression/UserspaceLaserSync.Regression.csproj'),
    '--configuration', $Configuration
)

foreach ($project in @('UserspaceLaserSync.csproj', 'RML/UserspaceLaserSync.RML.csproj')) {
    Invoke-DotNet -Arguments @(
        'publish', (Join-Path $PSScriptRoot $project), '--configuration', $Configuration,
        '-p:ResoniteInstallOnBuild=false'
    )
}
