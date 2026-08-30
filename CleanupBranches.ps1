param (
    [switch]$Force
)

$repoDir = $PSScriptRoot

$gitRoot = git -C $repoDir rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Not a Git repository: $repoDir"
}

$resolvedRepoDir = (Resolve-Path -LiteralPath $repoDir).Path.TrimEnd('\')
$resolvedGitRoot = (Resolve-Path -LiteralPath $gitRoot).Path.TrimEnd('\')
if ($resolvedRepoDir -ne $resolvedGitRoot) {
    throw "Run this script from the repository root: $resolvedGitRoot"
}

$changes = @(
    git -C $repoDir status --porcelain=v1 --untracked-files=all |
        Where-Object { $_ -ne "?? CleanupBranches.ps1" }
)
if ($LASTEXITCODE -ne 0) {
    throw "Failed to inspect the Git worktree."
}
if ($changes.Count -gt 0) {
    Write-Output "Uncommitted changes:"
    $changes | ForEach-Object { Write-Output "  $_" }
    throw "Commit or stash these changes before deleting branches."
}

git -C $repoDir switch main
if ($LASTEXITCODE -ne 0) {
    throw "Failed to switch to the main branch."
}

$branches = @(
    git -C $repoDir for-each-ref --format="%(refname:short)" refs/heads |
        Where-Object { $_ -and $_ -ne "main" }
)
if ($LASTEXITCODE -ne 0) {
    throw "Failed to list local branches."
}

if ($branches.Count -eq 0) {
    Write-Output "No local branches to delete."
    exit 0
}

Write-Output "The following local branches will be force-deleted:"
$branches | ForEach-Object { Write-Output "  $_" }

if (-not $Force) {
    $confirmation = Read-Host "Delete all $($branches.Count) local branches listed above? [y/N]"
    if ($confirmation -notmatch '^(?i:y|yes)$') {
        Write-Output "Cancelled."
        exit 0
    }
}

foreach ($branch in $branches) {
    git -C $repoDir branch -D -- $branch
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to delete local branch: $branch"
    }
}

Write-Output "Deleted $($branches.Count) local branches. The current branch is main."
