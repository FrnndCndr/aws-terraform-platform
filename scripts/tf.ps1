param(
    [Parameter(Mandatory)]
    [string] $Product,

    [Parameter(Mandatory)]
    [ValidateSet('dev', 'prod')]
    [string] $Environment,

    [string] $Profile,

    [Parameter(Mandatory)]
    [ValidateSet('init', 'plan', 'apply', 'destroy', 'output')]
    [string] $Command,

    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$stack = Join-Path $repoRoot 'stacks/web-app'
$productDir = Join-Path $repoRoot "clientes/$Product"
$namingFile = Join-Path $productDir 'naming.tfvars'
$backendFile = Join-Path $productDir 'backend.hcl'
$environmentFile = Join-Path $productDir "$Environment.tfvars"

foreach ($required in @($productDir, $namingFile, $backendFile, $environmentFile)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing required path: $required"
    }
}

$needsProfile = $Command -in @('plan', 'apply', 'destroy')
$profileFile = $null
if ($needsProfile) {
    if ([string]::IsNullOrWhiteSpace($Profile)) {
        throw "The -Profile parameter is required for '$Command'. Expected a file in $(Join-Path $repoRoot 'profiles')"
    }
    $profileFile = Join-Path $repoRoot "profiles/$Profile.tfvars"
    if (-not (Test-Path -LiteralPath $profileFile)) {
        throw "Missing required path: $profileFile"
    }
}

$environmentContent = Get-Content -LiteralPath $environmentFile -Raw
$match = [regex]::Match($environmentContent, '(?m)^\s*aws_profile\s*=\s*"([^"]+)"')
if (-not $match.Success) {
    throw "Variable aws_profile not found in $environmentFile"
}
$awsProfile = $match.Groups[1].Value

function Invoke-Terraform {
    param([string[]] $Arguments)

    if ($DryRun) {
        $rendered = foreach ($argument in $Arguments) {
            if ($argument -match '\s') { '"' + $argument + '"' } else { $argument }
        }
        Write-Host ('terraform ' + ($rendered -join ' '))
        return
    }

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & terraform @Arguments
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$initArguments = @(
    "-chdir=$stack",
    'init',
    '-reconfigure',
    '-input=false',
    "-backend-config=$backendFile",
    "-backend-config=key=$Product/$Environment/terraform.tfstate",
    "-backend-config=profile=$awsProfile"
)
Invoke-Terraform -Arguments $initArguments

switch ($Command) {
    { $_ -in @('plan', 'apply', 'destroy') } {
        Invoke-Terraform -Arguments @(
            "-chdir=$stack",
            $Command,
            "-var-file=$profileFile",
            "-var-file=$namingFile",
            "-var-file=$environmentFile"
        )
    }
    'output' {
        Invoke-Terraform -Arguments @("-chdir=$stack", 'output')
    }
}
