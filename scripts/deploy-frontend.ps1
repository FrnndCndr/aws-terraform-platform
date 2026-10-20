param(
    [Parameter(Mandatory)]
    [string] $Product,

    [Parameter(Mandatory)]
    [ValidateSet('dev', 'prod')]
    [string] $Environment,

    [Parameter(Mandatory)]
    [string] $SourcePath
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$stack = Join-Path $repoRoot 'stacks/web-app'
$productDir = Join-Path $repoRoot "clientes/$Product"
$backendFile = Join-Path $productDir 'backend.hcl'
$environmentFile = Join-Path $productDir "$Environment.tfvars"

foreach ($required in @($productDir, $backendFile, $environmentFile)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing required path: $required"
    }
}

if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
    throw "Missing source folder: $SourcePath"
}
if (-not (Test-Path -LiteralPath (Join-Path $SourcePath 'index.html'))) {
    throw "index.html not found in $SourcePath"
}

$forbiddenUrls = @('localhost', 'execute-api')
$builtFiles = Get-ChildItem -LiteralPath $SourcePath -Recurse -File -Include '*.html', '*.js'
foreach ($forbidden in $forbiddenUrls) {
    $hits = $builtFiles | Select-String -SimpleMatch -Pattern $forbidden -List
    if ($hits) {
        $list = ($hits | ForEach-Object { $_.Path }) -join [Environment]::NewLine
        throw "Found '$forbidden' in the built site. Not uploading:$([Environment]::NewLine)$list"
    }
}

$environmentContent = Get-Content -LiteralPath $environmentFile -Raw
$match = [regex]::Match($environmentContent, '(?m)^\s*aws_profile\s*=\s*"([^"]+)"')
if (-not $match.Success) {
    throw "Variable aws_profile not found in $environmentFile"
}
$awsProfile = $match.Groups[1].Value

$regionMatch = [regex]::Match($environmentContent, '(?m)^\s*region\s*=\s*"([^"]+)"')
if ($regionMatch.Success) {
    $region = $regionMatch.Groups[1].Value
}
else {
    $region = 'us-east-1'
}

function Invoke-Native {
    param(
        [string] $Command,
        [string[]] $Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $Command @Arguments
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "$Command failed with exit code $exitCode"
    }
    return $output
}

function Invoke-Aws {
    param([string[]] $Arguments)

    return Invoke-Native -Command 'aws' -Arguments ($Arguments + @('--profile', $awsProfile, '--region', $region))
}

Invoke-Native -Command 'terraform' -Arguments @(
    "-chdir=$stack",
    'init',
    '-reconfigure',
    '-input=false',
    "-backend-config=$backendFile",
    "-backend-config=key=$Product/$Environment/terraform.tfstate",
    "-backend-config=profile=$awsProfile"
) | Out-Host

$outputs = (Invoke-Native -Command 'terraform' -Arguments @("-chdir=$stack", 'output', '-json') | Out-String) | ConvertFrom-Json

$bucket = $outputs.site_bucket_name.value
$distributionId = $outputs.site_distribution_id.value

Write-Host "Uploading $SourcePath to s3://$bucket"
Invoke-Aws -Arguments @('s3', 'sync', $SourcePath, "s3://$bucket", '--delete') | Out-Host

Write-Host "Invalidating distribution $distributionId"
$invalidationId = (Invoke-Aws -Arguments @('cloudfront', 'create-invalidation', '--distribution-id', $distributionId, '--paths', '/*', '--query', 'Invalidation.Id', '--output', 'text') | Out-String).Trim()

Write-Host "Invalidation: $invalidationId"
