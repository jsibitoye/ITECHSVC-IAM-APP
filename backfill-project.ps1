param(
    [Parameter(Mandatory = $true)]
    [string]$repoPath,

    [Parameter(Mandatory = $true)]
    [string]$startDate,

    [Parameter(Mandatory = $true)]
    [string]$endDate,

    [ValidateRange(1, 50)]
    [int]$maxCommitsPerDay = 3,

    [string]$authorName = "J.s Ibitoye",
    [string]$authorEmail = "jsibitoye@outlook.com",

    [string[]]$excludeFiles = @("backfill-project.ps1")
)

$ErrorActionPreference = "Stop"

function New-CommitTimestamp {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$day
    )

    $hour = Get-Random -Minimum 8 -Maximum 21
    $minute = Get-Random -Minimum 0 -Maximum 60
    $second = Get-Random -Minimum 0 -Maximum 60

    return Get-Date -Year $day.Year -Month $day.Month -Day $day.Day `
        -Hour $hour -Minute $minute -Second $second
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$commandName
    )

    $cmd = Get-Command $commandName -ErrorAction SilentlyContinue
    return $null -ne $cmd
}

function Get-UntrackedFiles {
    $files = git ls-files --others --exclude-standard

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get untracked files from git."
    }

    if ($null -eq $files) {
        return @()
    }

    return @($files | Where-Object { $_ -and $_.Trim() -ne "" } | Sort-Object -Unique)
}

function Get-WorkingTreeState {
    $status = git status --porcelain

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to read git working tree state."
    }

    if ($null -eq $status) {
        return @()
    }

    return @($status)
}

function Clear-GitDateEnvironment {
    Remove-Item Env:\GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
    Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
}

function Build-CommitPlan {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$start,

        [Parameter(Mandatory = $true)]
        [datetime]$end,

        [Parameter(Mandatory = $true)]
        [int]$maxPerDay
    )

    $plan = @()

    for ($d = $start; $d -le $end; $d = $d.AddDays(1)) {
        $count = Get-Random -Minimum 1 -Maximum ($maxPerDay + 1)

        for ($i = 1; $i -le $count; $i++) {
            $plan += [PSCustomObject]@{
                Day = $d
                Number = $i
            }
        }
    }

    return @($plan)
}

if (-not (Test-CommandExists "git")) {
    throw "Git is not installed or not available in PATH."
}

if (-not (Test-Path $repoPath)) {
    throw "Path does not exist: $repoPath"
}

Set-Location $repoPath

if (-not (Test-Path ".git")) {
    throw "Git is not initialized in this folder. Run git init first."
}

try {
    $start = [datetime]::ParseExact($startDate, "yyyy-MM-dd", $null)
    $end = [datetime]::ParseExact($endDate, "yyyy-MM-dd", $null)
}
catch {
    throw "Dates must be in yyyy-MM-dd format."
}

if ($start -gt $end) {
    throw "startDate cannot be later than endDate."
}

$workingState = Get-WorkingTreeState

$dirtyTrackedChanges = @(
    $workingState | Where-Object {
        ($_ -match '^[ MARCUD][MARCUD] ') -or
        ($_ -match '^[MARCUD][ MARCUD] ')
    }
)

if ($dirtyTrackedChanges.Count -gt 0) {
    throw @"
This repo has tracked changes already staged or modified.
Commit, stash, or discard them first before running this backfill script.
Use: git status
"@
}

$allFiles = Get-UntrackedFiles

$allFiles = @(
    $allFiles | Where-Object {
        $file = $_
        -not ($excludeFiles -contains $file)
    }
)

if ($allFiles.Count -eq 0) {
    Write-Host ""
    Write-Host "No untracked files found."
    Write-Host "Nothing to backfill."
    Write-Host "This usually means the project has already been committed."
    Write-Host ""
    Write-Host "Use normal Git commands for updates:"
    Write-Host '  git add .'
    Write-Host '  git commit -m "Describe your changes"'
    Write-Host '  git push'
    exit 0
}

$commitPlan = Build-CommitPlan -start $start -end $end -maxPerDay $maxCommitsPerDay

if ($commitPlan.Count -eq 0) {
    throw "No commits were planned."
}

if ($commitPlan.Count -gt $allFiles.Count) {
    $commitPlan = @($commitPlan | Select-Object -First $allFiles.Count)
}

if ($commitPlan.Count -eq 0) {
    throw "Commit plan became empty after adjustment."
}

$filesPerCommit = [math]::Ceiling($allFiles.Count / $commitPlan.Count)

Write-Host "Total untracked git-trackable files: $($allFiles.Count)"
Write-Host "Planned commits: $($commitPlan.Count)"
Write-Host "Files per commit: $filesPerCommit"
Write-Host ""

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

try {
    foreach ($plan in $commitPlan) {
        if ($fileIndex -ge $allFiles.Count) {
            break
        }

        $batchNumber++
        $batch = @($allFiles | Select-Object -Skip $fileIndex -First $filesPerCommit)

        if ($batch.Count -eq 0) {
            Write-Warning "Batch $batchNumber had no files. Skipping."
            continue
        }

        foreach ($file in $batch) {
            git add -- $file
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to add file: $file"
            }
        }

        $hasStaged = @(git diff --cached --name-only)
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to inspect staged files."
        }

        if ($hasStaged.Count -eq 0) {
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
}
finally {
    Clear-GitDateEnvironment
}

Write-Host ""
Write-Host "Backfill complete."
Write-Host "Now add remote and push."