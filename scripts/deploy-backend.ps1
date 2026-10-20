param(
    [Parameter(Mandatory)]
    [string] $Product,

    [Parameter(Mandatory)]
    [ValidateSet('dev', 'prod')]
    [string] $Environment,

    [Parameter(Mandatory)]
    [string] $Version
)

$ErrorActionPreference = 'Stop'

if ($Version -eq 'latest') {
    throw "The -Version parameter cannot be 'latest'."
}

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

$environmentContent = Get-Content -LiteralPath $environmentFile -Raw
$match = [regex]::Match($environmentContent, '(?m)^\s*aws_profile\s*=\s*"([^"]+)"')
if (-not $match.Success) {
    throw "Variable aws_profile not found in $environmentFile"
}
$awsProfile = $match.Groups[1].Value

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

$ecrUrl = $outputs.ecr_repository_url.value
$cluster = $outputs.ecs_cluster_name.value
$service = $outputs.ecs_service_name.value
$family = $outputs.ecs_task_definition_family.value
$containerName = $outputs.backend_container_name.value

$regionMatch = [regex]::Match($environmentContent, '(?m)^\s*region\s*=\s*"([^"]+)"')
if ($regionMatch.Success) {
    $region = $regionMatch.Groups[1].Value
}
else {
    $region = 'us-east-1'
}

$repositoryName = $ecrUrl.Substring($ecrUrl.IndexOf('/') + 1)
$image = "${ecrUrl}:$Version"

Write-Host "Checking that $image exists"
$imageIds = "imageTag=$Version"
$found = Invoke-Aws -Arguments @('ecr', 'describe-images', '--repository-name', $repositoryName, '--image-ids', $imageIds, '--query', 'imageDetails[0].imageDigest', '--output', 'text')
if ([string]::IsNullOrWhiteSpace(($found | Out-String))) {
    throw "Image tag $Version not found in repository $repositoryName"
}

Write-Host "Reading task definition family $family"
$taskDefinitionJson = Invoke-Aws -Arguments @('ecs', 'describe-task-definition', '--task-definition', $family, '--query', 'taskDefinition', '--output', 'json') | Out-String
$taskDefinition = $taskDefinitionJson | ConvertFrom-Json

$container = $taskDefinition.containerDefinitions | Where-Object { $_.name -eq $containerName }
if ($null -eq $container) {
    throw "Container $containerName not found in task definition $family"
}
$container.image = $image

$readOnlyFields = @(
    'taskDefinitionArn',
    'revision',
    'status',
    'requiresAttributes',
    'compatibilities',
    'registeredAt',
    'registeredBy',
    'deregisteredAt'
)
foreach ($field in $readOnlyFields) {
    $taskDefinition.PSObject.Properties.Remove($field)
}

$inputFile = Join-Path $env:TEMP "task-definition-$Product-$Environment.json"
$utf8NoBom = New-Object Text.UTF8Encoding $false
[IO.File]::WriteAllText($inputFile, ($taskDefinition | ConvertTo-Json -Depth 20), $utf8NoBom)

try {
    Write-Host 'Registering new task definition revision'
    $newTaskDefinitionArn = (Invoke-Aws -Arguments @('ecs', 'register-task-definition', '--cli-input-json', "file://$inputFile", '--query', 'taskDefinition.taskDefinitionArn', '--output', 'text') | Out-String).Trim()
}
finally {
    Remove-Item -LiteralPath $inputFile -Force -ErrorAction SilentlyContinue
}

Write-Host "Updating service $service to $newTaskDefinitionArn"
Invoke-Aws -Arguments @('ecs', 'update-service', '--cluster', $cluster, '--service', $service, '--task-definition', $newTaskDefinitionArn) | Out-Null

Write-Host 'Waiting for the service to become stable'
Invoke-Aws -Arguments @('ecs', 'wait', 'services-stable', '--cluster', $cluster, '--services', $service) | Out-Null

$state = (Invoke-Aws -Arguments @('ecs', 'describe-services', '--cluster', $cluster, '--services', $service, '--query', 'services[0].deployments[?status==`PRIMARY`] | [0].[taskDefinition,rolloutState,runningCount,desiredCount]', '--output', 'text') | Out-String).Trim()

Write-Host "Image:      $image"
Write-Host "Revision:   $newTaskDefinitionArn"
Write-Host "Deployment: $state"
