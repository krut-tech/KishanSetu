# KisanSetu one-command release helper for Windows PowerShell 5.1+
# Run from the repository root: powershell -ExecutionPolicy Bypass -File .\release.ps1
$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
}

$pubspecPath = $null
$originalPubspec = $null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$releaseVersionWritten = $false
$releaseCommitCreated = $false

try {
    $repoRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
    Set-Location -LiteralPath $repoRoot

    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot '.git'))) {
        throw 'Place release.ps1 in the root of the Git repository.'
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git was not found. Install Git for Windows first.'
    }

    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not determine the current Git branch.' }
    if ($branch -ne 'main') {
        throw "You are on branch '$branch'. Switch to main before releasing. No files were changed by this script."
    }

    Write-Host 'Fetching latest main and tags...' -ForegroundColor Cyan
    Invoke-Git -GitArgs @('fetch', 'origin', '--tags')

    $statusBeforePull = @(& git status --porcelain)
    if ($LASTEXITCODE -ne 0) { throw 'Could not read Git status.' }
    $remoteMain = (& git rev-parse origin/main).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not find origin/main.' }
    $localHead = (& git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not read local HEAD.' }

    if ($localHead -ne $remoteMain) {
        if ($statusBeforePull.Count -gt 0) {
            throw "Your local main and GitHub main differ, and you have local changes. To avoid overwriting anything, sync/resolve them first, then rerun .\release.ps1."
        }
        Invoke-Git -GitArgs @('pull', '--ff-only', 'origin', 'main')
    }

    # Do not silently absorb any changes already staged by the user.
    $preStagedPaths = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect pre-staged changes.' }
    if ($preStagedPaths.Count -gt 0) {
        Write-Host 'Already-staged files were found:' -ForegroundColor Yellow
        $preStagedPaths | ForEach-Object { Write-Host "  $_" }
        throw 'Commit or unstage these files yourself before releasing. The release script will not touch pre-staged changes.'
    }

    $pubspecPath = Join-Path $repoRoot 'pubspec.yaml'
    if (-not (Test-Path -LiteralPath $pubspecPath)) { throw 'pubspec.yaml was not found.' }
    $originalPubspec = [System.IO.File]::ReadAllText($pubspecPath)
    $versionMatch = [regex]::Match($originalPubspec, '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$')
    if (-not $versionMatch.Success) {
        throw 'Could not parse pubspec.yaml version. Expected format: version: 1.2.3+4'
    }
    $currentMajor = [int]$versionMatch.Groups[1].Value
    $currentMinor = [int]$versionMatch.Groups[2].Value
    $currentPatch = [int]$versionMatch.Groups[3].Value
    $currentBuild = [int]$versionMatch.Groups[4].Value

    $tagRows = @()
    $allTags = @(& git tag --list 'v[0-9]*')
    if ($LASTEXITCODE -ne 0) { throw 'Could not list Git tags.' }
    foreach ($tag in $allTags) {
        if ($tag -match '^v(\d+)\.(\d+)\.(\d+)$') {
            $tagRows += [pscustomobject]@{
                Tag = $tag
                Major = [int]$Matches[1]
                Minor = [int]$Matches[2]
                Patch = [int]$Matches[3]
            }
        }
    }
    if ($tagRows.Count -eq 0) {
        throw 'No release tags like v1.0.0 were found. Create the initial release tag manually once.'
    }

    $latestTag = $tagRows | Sort-Object Major, Minor, Patch -Descending | Select-Object -First 1
    $nextPatch = $latestTag.Patch + 1
    $nextVersion = "$($latestTag.Major).$($latestTag.Minor).$nextPatch"
    $nextTag = "v$nextVersion"
    if ("$currentMajor.$currentMinor.$currentPatch" -eq $nextVersion -and $currentBuild -ge ($latestTag.Patch + 1)) {
        $nextBuild = $currentBuild
    } else {
        $nextBuild = [Math]::Max($currentBuild, $latestTag.Patch) + 1
    }

    $existingNextTag = @(& git tag --list $nextTag)
    if ($LASTEXITCODE -ne 0) { throw 'Could not check whether the next tag already exists.' }
    if ($existingNextTag.Count -gt 0) {
        throw "Tag $nextTag already exists locally. Fetch tags and rerun; the script will choose the next unused version."
    }

    Write-Host ''
    Write-Host "Next release: $nextTag (app version $nextVersion+$nextBuild)" -ForegroundColor Green
    Write-Host 'Choose what to publish:' -ForegroundColor Cyan
    Write-Host '  1. Only code already committed on GitHub + the automatic version bump (recommended for this release).' -ForegroundColor White
    Write-Host '  2. Include all safe local code changes as well (only choose when all local edits are ready).' -ForegroundColor White
    Write-Host '    Secrets, Supabase temp files, local.properties, keystores and generated build/cache folders are excluded.' -ForegroundColor DarkGray
    $releaseMode = Read-Host 'Type 1 or 2'
    if ($releaseMode -cne '1' -and $releaseMode -cne '2') {
        throw 'Invalid choice. Type 1 or 2. No release was made.'
    }

    $updatedPubspec = [regex]::Replace(
        $originalPubspec,
        '(?m)^version:\s*.*$',
        "version: $nextVersion+$nextBuild",
        1
    )
    [System.IO.File]::WriteAllText($pubspecPath, $updatedPubspec, $utf8NoBom)
    $releaseVersionWritten = $true

    if ($releaseMode -ceq '1') {
        # For the current release: release only the latest code already on GitHub.
        Invoke-Git -GitArgs @('add', '--', 'pubspec.yaml')
    } else {
        # Stage tracked modifications/deletions safely while excluding secrets/cache paths.
        Invoke-Git -GitArgs @(
            'add', '-u', '--', '.',
            ':(exclude).env',
            ':(exclude,glob)**/.env',
            ':(exclude,glob)**/.env.*',
            ':(exclude)supabase/.temp/**',
            ':(exclude)android/local.properties',
            ':(exclude,glob)**/*.jks',
            ':(exclude,glob)**/*.keystore',
            ':(exclude,glob)**/build/**',
            ':(exclude,glob)**/.dart_tool/**',
            ':(exclude,glob)**/.gradle/**',
            ':(exclude,glob)**/release.ps1'
        )

        $untrackedPaths = @(& git ls-files --others --exclude-standard)
        if ($LASTEXITCODE -ne 0) { throw 'Could not list untracked files.' }
        $safeUntrackedPaths = @()
        foreach ($path in $untrackedPaths) {
            $normalizedPath = $path -replace '\\', '/'
            $isSensitiveOrGenerated = $false
            if ($normalizedPath -match '(^|/)\.env($|\.)' -and $normalizedPath -notmatch '(^|/)\.env\.(example|sample|template)$') { $isSensitiveOrGenerated = $true }
            if ($normalizedPath -eq 'android/local.properties') { $isSensitiveOrGenerated = $true }
            if ($normalizedPath -match '^supabase/\.temp(/|$)') { $isSensitiveOrGenerated = $true }
            if ($normalizedPath -match '(^|/)[^/]+\.(jks|keystore)$') { $isSensitiveOrGenerated = $true }
            if ($normalizedPath -match '(^|/)(build|\.dart_tool|\.gradle)(/|$)') { $isSensitiveOrGenerated = $true }
            if ($normalizedPath -match '(^|/)release\.ps1$') { $isSensitiveOrGenerated = $true }
            if (-not $isSensitiveOrGenerated) { $safeUntrackedPaths += $path }
        }
        if ($safeUntrackedPaths.Count -gt 0) {
            $addUntrackedArgs = @('add', '-A', '--') + $safeUntrackedPaths
            Invoke-Git -GitArgs $addUntrackedArgs
        }
    }

    & git diff --cached --quiet
    $hasStagedChanges = ($LASTEXITCODE -ne 0)
    if ($LASTEXITCODE -gt 1) { throw 'Could not inspect staged changes.' }
    if (-not $hasStagedChanges) {
        throw 'There are no staged project changes to release. Make/save your app code changes, then rerun.'
    }

    Write-Host ''
    Write-Host 'Files to be committed:' -ForegroundColor Cyan
    Invoke-Git -GitArgs @('diff', '--cached', '--name-only')
    if ($releaseMode -ceq '1') {
        Write-Host 'All other local edits will remain on your PC and will NOT be included in this release.' -ForegroundColor Yellow
    }
    $confirmation = Read-Host "Commit, push and publish $nextTag? Type YES to continue"
    if ($confirmation -cne 'YES') {
        & git reset --quiet
        [System.IO.File]::WriteAllText($pubspecPath, $originalPubspec, $utf8NoBom)
        Write-Host 'Cancelled. No release was pushed. The original pubspec.yaml was restored; other working files were not discarded.' -ForegroundColor Yellow
        exit 0
    }

    Invoke-Git -GitArgs @('commit', '-m', "Release $nextTag")
    $releaseCommitCreated = $true
    Invoke-Git -GitArgs @('push', 'origin', 'main')
    Invoke-Git -GitArgs @('tag', '-a', $nextTag, '-m', "KisanSetu $nextTag")
    Invoke-Git -GitArgs @('push', 'origin', $nextTag)

    Write-Host ''
    Write-Host "Release trigger sent: $nextTag" -ForegroundColor Green
    Write-Host 'GitHub Actions will build the signed APK and publish the GitHub Release automatically.' -ForegroundColor Green
    Write-Host 'The app updater will offer it after publication; Android still requires user approval to install.' -ForegroundColor Green
    Start-Process 'https://github.com/krut-tech/KishanSetu/actions'
}
catch {
    if ($releaseVersionWritten -and -not $releaseCommitCreated -and $pubspecPath -and $originalPubspec -ne $null) {
        try {
            & git reset --quiet
            [System.IO.File]::WriteAllText($pubspecPath, $originalPubspec, $utf8NoBom)
        } catch {}
    }
    Write-Host "`nRELEASE STOPPED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'No force push or destructive cleanup was performed.' -ForegroundColor Yellow
    exit 1
}
