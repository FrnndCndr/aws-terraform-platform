param(
    [Parameter(Mandatory)]
    [string] $Product,

    [Parameter(Mandatory)]
    [ValidateSet('dev', 'prod')]
    [string] $Environment,

    [ValidateRange(1024, 65535)]
    [int] $LocalPort = 15432
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

if (-not (Get-Command 'session-manager-plugin' -ErrorAction SilentlyContinue)) {
    $pluginDir = 'C:\Program Files\Amazon\SessionManagerPlugin\bin'
    if (Test-Path -LiteralPath (Join-Path $pluginDir 'session-manager-plugin.exe')) {
        $env:Path = "$env:Path;$pluginDir"
    }
    else {
        throw 'session-manager-plugin not found. Install the AWS Session Manager plugin.'
    }
}

$portInUse = Get-NetTCPConnection -LocalPort $LocalPort -State Listen -ErrorAction SilentlyContinue
if ($portInUse) {
    throw "Local port $LocalPort is already in use. Close the other tunnel or use -LocalPort."
}

$environmentContent = Get-Content -LiteralPath $environmentFile -Raw
$profileMatch = [regex]::Match($environmentContent, '(?m)^\s*aws_profile\s*=\s*"([^"]+)"')
if (-not $profileMatch.Success) {
    throw "Variable aws_profile not found in $environmentFile"
}
$awsProfile = $profileMatch.Groups[1].Value

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
) | Out-Null

$outputs = (Invoke-Native -Command 'terraform' -Arguments @("-chdir=$stack", 'output', '-json') | Out-String) | ConvertFrom-Json

$cluster = $outputs.ecs_cluster_name.value
$service = $outputs.ecs_service_name.value
$dbAddress = $outputs.db_address.value

$taskArn = (Invoke-Aws -Arguments @('ecs', 'list-tasks', '--cluster', $cluster, '--service-name', $service, '--desired-status', 'RUNNING', '--query', 'taskArns[0]', '--output', 'text') | Out-String).Trim()
if ([string]::IsNullOrWhiteSpace($taskArn) -or $taskArn -eq 'None') {
    throw "No running task in service $service"
}
$taskId = $taskArn.Split('/')[-1]

$runtimeId = (Invoke-Aws -Arguments @('ecs', 'describe-tasks', '--cluster', $cluster, '--tasks', $taskArn, '--query', 'tasks[0].containers[0].runtimeId', '--output', 'text') | Out-String).Trim()
$agentStatus = (Invoke-Aws -Arguments @('ecs', 'describe-tasks', '--cluster', $cluster, '--tasks', $taskArn, '--query', 'tasks[0].containers[0].managedAgents[?name==`ExecuteCommandAgent`] | [0].lastStatus', '--output', 'text') | Out-String).Trim()
if ($agentStatus -ne 'RUNNING') {
    throw "ECS Exec agent is not running on task $taskId (status: $agentStatus). Check backend_enable_execute_command."
}

$parameters = @{
    host            = @($dbAddress)
    portNumber      = @('5432')
    localPortNumber = @([string] $LocalPort)
} | ConvertTo-Json -Compress
$parametersFile = Join-Path $env:TEMP "db-tunnel-$Product-$Environment.json"
$utf8NoBom = New-Object Text.UTF8Encoding $false
[IO.File]::WriteAllText($parametersFile, $parameters, $utf8NoBom)

Write-Host "Task:   $taskId"
Write-Host "Tunnel: 127.0.0.1:$LocalPort -> ${dbAddress}:5432"
Write-Host 'Press Ctrl+C to close the tunnel.'

try {
    & aws ssm start-session --target "ecs:${cluster}_${taskId}_${runtimeId}" --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters "file://$parametersFile" --profile $awsProfile --region $region
}
finally {
    Remove-Item -LiteralPath $parametersFile -Force -ErrorAction SilentlyContinue
}
