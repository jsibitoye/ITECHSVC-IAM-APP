param(
    [Parameter(Mandatory = $true)]
    [string]$repoPath,

    [Parameter(Mandatory = $true)]
    [string]$startDate,

    [Parameter(Mandatory = $true)]
    [string]$endDate,

    [int]$maxCommitsPerDay = 3,

    [string]$authorName = "J.s Ibitoye",
    [string]$authorEmail = "jsibitoye@outlook.com"
)

$ErrorActionPreference = "Stop"

function New-CommitTimestamp {
    param([datetime]$day)

    $hour = Get-Random -Minimum 8 -Maximum 21
    $minute = Get-Random -Minimum 0 -Maximum 60
    $second = Get-Random -Minimum 0 -Maximum 60

    return (Get-Date -Year $day.Year -Month $day.Month -Day $day.Day `
        -Hour $hour -Minute $minute -Second $second)
}

if (!(Test-Path $repoPath)) {
    throw "Path does not exist: $repoPath"
}

Set-Location $repoPath

if (!(Test-Path ".git")) {
    throw "Git is not initialized in this folder. Run git init first."
}

try {
    $start = [datetime]::ParseExact($startDate, "yyyy-MM-dd", $null)
    $end   = [datetime]::ParseExact($endDate, "yyyy-MM-dd", $null)
}
catch {
    throw "Dates must be in yyyy-MM-dd format."
}

if ($start -gt $end) {
    throw "startDate cannot be later than endDate."
}

# Build a git-aware list of trackable files only
$allFiles = git ls-files --others --exclude-standard

if ($LASTEXITCODE -ne 0) {
    throw "Failed to get git-trackable file list."
}

$allFiles = $allFiles |
    Where-Object {
        $_ -and
        $_ -ne "backfill-project.ps1"
    } |
    Sort-Object -Unique

if (!$allFiles -or $allFiles.Count -eq 0) {
    throw "No git-trackable files found to commit."
}

# Build commit plan
$commitPlan = @()
for ($d = $start; $d -le $end; $d = $d.AddDays(1)) {
    $count = Get-Random -Minimum 1 -Maximum ($maxCommitsPerDay + 1)
    for ($i = 1; $i -le $count; $i++) {
        $commitPlan += [PSCustomObject]@{
            Day = $d
            Number = $i
        }
    }
}

if ($commitPlan.Count -eq 0) {
    throw "No commits were planned."
}

# Never plan more commits than files
if ($commitPlan.Count -gt $allFiles.Count) {
    $commitPlan = $commitPlan | Select-Object -First $allFiles.Count
}

$filesPerCommit = [math]::Ceiling($allFiles.Count / $commitPlan.Count)

Write-Host "Total git-trackable files: $($allFiles.Count)"
Write-Host "Planned commits: $($commitPlan.Count)"
Write-Host "Files per commit: $filesPerCommit"

$fileIndex = 0
$batchNumber = 0

$messages = @(
    "Add project structure",
    "Add core application files",
    "Add security configuration",
    "Add controller and routing logic",
    "Add Thymeleaf templates",
    "Add resource configuration",
    "Add Maven build files",
    "Add application settings",
    "Add tests and cleanup",
    "Add supporting project files"
)

foreach ($plan in $commitPlan) {
    if ($fileIndex -ge $allFiles.Count) {
        break
    }

    $batchNumber++
    $batch = $allFiles | Select-Object -Skip $fileIndex -First $filesPerCommit

    foreach ($file in $batch) {
        git add -- $file
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add file: $file"
        }
    }

    $hasStaged = git diff --cached --name-only
    if (-not $hasStaged) {
        Write-Warning "No staged files in batch $batchNumber. Skipping."
        $fileIndex += $batch.Count
        continue
    }

    $commitTime = New-CommitTimestamp -day $plan.Day
    $isoDate = $commitTime.ToString("yyyy-MM-ddTHH:mm:ss")

    $env:GIT_AUTHOR_DATE = $isoDate
    $env:GIT_COMMITTER_DATE = $isoDate

    $msg = ($messages | Get-Random) + " [$batchNumber]"
    git commit --author="$authorName <$authorEmail>" -m $msg

    if ($LASTEXITCODE -ne 0) {
        throw "Commit failed at batch $batchNumber"
    }

    Write-Host "Committed batch $batchNumber on $isoDate"

    $fileIndex += $batch.Count
}

Remove-Item Env:\GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Backfill complete."
Write-Host "Now add remote and push."