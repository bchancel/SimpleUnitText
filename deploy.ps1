$ErrorActionPreference = "Stop"

$sourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetRoot = "C:\games\World of Warcraft\_retail_\Interface\AddOns\SimpleUnitText"

if (-not (Test-Path -LiteralPath $sourceRoot)) {
    throw "Source path does not exist: $sourceRoot"
}

if (-not (Test-Path -LiteralPath $targetRoot)) {
    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
}

$exclude = @(
    ".git",
    ".vs",
    ".vscode",
    "deploy.ps1",
    "update_and_push.ps1"
)

Get-ChildItem -LiteralPath $sourceRoot -Force | ForEach-Object {
    if ($exclude -contains $_.Name) {
        return
    }

    $destination = Join-Path $targetRoot $_.Name

    if ($_.PSIsContainer) {
        if (Test-Path -LiteralPath $destination) {
            Remove-Item -LiteralPath $destination -Recurse -Force
        }
        Copy-Item -LiteralPath $_.FullName -Destination $destination -Recurse -Force
    }
    else {
        Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
    }
}

Write-Host "SimpleUnitText deployed to: $targetRoot" -ForegroundColor Green
