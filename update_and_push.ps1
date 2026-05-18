param(
    [string]$NewVersion
)

$tocPath = Join-Path $PSScriptRoot "SimpleUnitText.toc"
$toc = Get-Content $tocPath -Raw

if ($toc -notmatch '## Version:\s*(\d+)\.(\d+)\.(\d+)') {
    Write-Error "Could not find ## Version: in SimpleUnitText.toc"
    exit 1
}

$major = [int]$Matches[1]
$minor = [int]$Matches[2]
$patch = [int]$Matches[3]

if ($NewVersion) {
    if ($NewVersion -notmatch '^\d+\.\d+\.\d+$') {
        Write-Error "Version must be in major.minor.patch format (for example 1.2.0)"
        exit 1
    }
    $version = $NewVersion
}
else {
    $patch++
    $version = "$major.$minor.$patch"
}

Write-Host "Updating version: $major.$minor.$($Matches[3]) -> $version"

$tag = "v$version"

$toc = $toc -replace '## Version:\s*\d+\.\d+\.\d+', "## Version: $version"
Set-Content $tocPath $toc -NoNewline

git add -A
git commit -m "update version $tag"
git push origin main

git tag -a $tag -m "Release $tag"
git push origin $tag

Write-Host "Done. Tagged and pushed $tag"
