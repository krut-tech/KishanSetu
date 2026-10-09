# One-command release (Windows): bumps the version, tags it and pushes.
# GitHub Actions then builds the APK and publishes it to Releases.
#
# Usage: ./scripts/release.ps1 [patch|minor|major|X.Y.Z]   (default: patch)
param([string]$Bump = "patch")
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (git status --porcelain) { throw "Commit or stash your changes first." }

git checkout main
git pull --ff-only
git fetch --tags --quiet

$pub = [version](Select-String -Path pubspec.yaml -Pattern '^version:\s*(\d+\.\d+\.\d+)').Matches[0].Groups[1].Value
$tags = @(git tag -l 'v[0-9]*' | ForEach-Object { try { [version]($_.TrimStart('v')) } catch { } })
$cur = (@($tags) + $pub | Sort-Object | Select-Object -Last 1)

switch -Regex ($Bump) {
  '^patch$' { $new = [version]::new($cur.Major, $cur.Minor, $cur.Build + 1) }
  '^minor$' { $new = [version]::new($cur.Major, $cur.Minor + 1, 0) }
  '^major$' { $new = [version]::new($cur.Major + 1, 0, 0) }
  '^\d+\.\d+\.\d+$' { $new = [version]$Bump }
  default { throw "Use: patch | minor | major | X.Y.Z" }
}

$code = $new.Major * 10000 + $new.Minor * 100 + $new.Build

git rev-parse "v$new" 2>$null
if ($LASTEXITCODE -eq 0) { throw "Tag v$new already exists." }

(Get-Content pubspec.yaml) -replace '^version:.*', "version: $new+$code" | Set-Content pubspec.yaml

git add pubspec.yaml
git commit -m "chore(release): v$new"
git tag "v$new"
git push origin main "v$new"

Write-Host "Released v$new. Watch the build: https://github.com/krut-tech/KishanSetu/actions"
