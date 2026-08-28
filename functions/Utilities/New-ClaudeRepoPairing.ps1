#requires -Version 7.0

function New-ClaudeRepoPairing {
    <#
    .SYNOPSIS
        Sets up a "local_<repo>" companion directory next to an existing git
        repository clone, wired up for Claude Code.

    .DESCRIPTION
        Given the path to an existing cloned repository (e.g. C:\dev\InstallManager),
        this creates a sibling directory (e.g. C:\dev\local_InstallManager) with
        subfolders for agent instructions, session logs, plans, PR descriptions,
        and checklists. It then:

          - Writes .claude/settings.local.json in BOTH directories so Claude Code
            can read/write across the pairing without prompting (additionalDirectories),
            and gitignores that file in the code repo so it never leaves your machine.
          - Writes local_<repo>/CLAUDE.md describing the pairing (the source of truth).
          - Writes <repo>/CLAUDE.local.md that imports the above via @../local_<repo>/CLAUDE.md,
            so the code repo never gets the local-workflow content committed to it.
          - Creates a VS Code multi-root workspace file, <repo>.code-workspace, inside
            the local companion repo, containing both folders and a custom window title.
          - Optionally runs `git init` in the local companion directory.

        Safe to re-run: existing folders/files are left alone unless -Force is passed.
        To add more folders later, either re-run with an expanded -LocalFolders list,
        or just create the directory yourself inside local_<repo> - additionalDirectories
        already grants Claude access to the whole tree, so a new subfolder needs no
        extra wiring.

    .PARAMETER RepoPath
        Path to the existing repository clone (relative or absolute).

    .PARAMETER LocalFolders
        Subfolders to create inside the local companion repo.

    .PARAMETER LocalPrefix
        Prefix used to name the companion directory. Default: "local_".

    .PARAMETER InitLocalGit
        Initialize the companion directory as its own git repository. Default: $true.

    .PARAMETER Force
        Overwrite existing generated files (CLAUDE.md, CLAUDE.local.md,
        settings.local.json, the .code-workspace file) if present. Folders are
        always created if missing, regardless of -Force.

    .EXAMPLE
        New-ClaudeRepoPairing -RepoPath C:\dev\InstallManager

    .EXAMPLE
        New-ClaudeRepoPairing -RepoPath ~/dev/InstallManager -Force `
            -LocalFolders agent-instructions, sessions, plans, pull-requests, checklists, research

    .OUTPUTS
        PSCustomObject with RepoPath, LocalPath, and WorkspaceFile.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RepoPath,

        [string[]]$LocalFolders = @('agent-instructions', 'sessions', 'plans', 'pull-requests', 'checklists','briefings', 'issues'),

        [string]$LocalPrefix = 'local_',

        [bool]$InitLocalGit = $true,

        [switch]$Force
    )

    # --- Resolve and validate the source repo ---
    $repoPath = (Resolve-Path -Path $RepoPath -ErrorAction Stop).Path.TrimEnd('\', '/')
    $repoName = Split-Path -Path $repoPath -Leaf
    $parentDir = Split-Path -Path $repoPath -Parent
    $localName = "$LocalPrefix$repoName"
    $localPath = Join-Path $parentDir $localName

    if (-not (Test-Path (Join-Path $repoPath '.git'))) {
        Write-Warning "'$repoPath' does not look like a git repository root (no .git found). Continuing anyway."
    }

    Write-Host "Repo:  $repoPath"
    Write-Host "Local: $localPath"

    if (-not $PSCmdlet.ShouldProcess($localPath, 'Create Claude Code repo pairing')) {
        return
    }

    # --- Directory structure ---
    New-Item -ItemType Directory -Path $localPath, (Join-Path $localPath '.claude'), (Join-Path $repoPath '.claude') -Force | Out-Null

    foreach ($folder in $LocalFolders) {
        $folderPath = Join-Path $localPath $folder
        if (-not (Test-Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $folderPath '.gitkeep') -Force | Out-Null   # keep otherwise-empty folders trackable in git
        }
    }

    # --- local_<repo>/CLAUDE.md : the shared source of truth ---
    $localClaudeMdPath = Join-Path $localPath 'CLAUDE.md'
    if ($Force -or -not (Test-Path $localClaudeMdPath)) {
        $folderBullets = ($LocalFolders | ForEach-Object { "- ``./$_/``" }) -join "`n"
        @"
# $localName

This repo pairs 1:1 with the sibling code repo ``../$repoName``. When you work
in either directory, both are relevant:

- ``../$repoName`` - the actual cloned repository (origin or fork). Code
  changes, commits, and PRs happen there.
$folderBullets

When asked to write or edit code, do it in ``../$repoName``, not here. This
repo is for the artifacts *around* the work, not the work itself.

Add new subfolders here as needed - there's nothing special about the ones
listed above beyond being a reasonable starting set. Claude already has
access to this whole directory tree from the ``../$repoName`` side, so a new
folder needs no extra configuration.
"@ | Set-Content -Path $localClaudeMdPath -Encoding utf8
    }

    # --- <repo>/CLAUDE.local.md : personal, untracked, imports the above ---
    $repoClaudeLocalMdPath = Join-Path $repoPath 'CLAUDE.local.md'
    if ($Force -or -not (Test-Path $repoClaudeLocalMdPath)) {
        @"
@../$localName/CLAUDE.md

## Notes specific to this repo
- (add build/test commands, branch conventions, etc. here)
"@ | Set-Content -Path $repoClaudeLocalMdPath -Encoding utf8
    }

    # --- .claude/settings.local.json in both repos ---
    $repoSettingsPath = Join-Path $repoPath '.claude' 'settings.local.json'
    $localSettingsPath = Join-Path $localPath '.claude' 'settings.local.json'

    if ($Force -or -not (Test-Path $repoSettingsPath)) {
        [ordered]@{ permissions = [ordered]@{ additionalDirectories = @("../$localName") } } |
            ConvertTo-Json -Depth 5 | Set-Content -Path $repoSettingsPath -Encoding utf8
    }
    if ($Force -or -not (Test-Path $localSettingsPath)) {
        [ordered]@{ permissions = [ordered]@{ additionalDirectories = @("../$repoName") } } |
            ConvertTo-Json -Depth 5 | Set-Content -Path $localSettingsPath -Encoding utf8
    }

    # --- gitignore settings.local.json in the code repo (belt-and-suspenders; ---
    # --- Claude Code also does this itself the first time it writes the file) ---
    $ignoreLines = @(
        '.claude/settings.local.json'
        'CLAUDE.local.md'
        )
    $repoGitignore = Join-Path $repoPath '.gitignore'
    foreach ($il in $ignoreLines)
    {
        if (Test-Path $repoGitignore) {
            if ((Get-Content $repoGitignore -Raw) -notmatch [regex]::Escape($il)) {
                Add-Content -Path $repoGitignore -Value "`n$il"
            }
        } else {
            Set-Content -Path $repoGitignore -Value $il -Encoding utf8
        }
    }

    # --- VS Code multi-root workspace file, inside the local companion repo ---
    $workspacePath = Join-Path $localPath "$repoName.code-workspace"
    if ($Force -or -not (Test-Path $workspacePath)) {
        [ordered]@{
            folders  = @(
                [ordered]@{ path = "../$repoName"; name = $repoName }
                [ordered]@{ path = '.'; name = $localName }
            )
            settings = [ordered]@{ 'window.title' = "$repoName Workspace" }
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $workspacePath -Encoding utf8
    }

    # --- init git in the local companion repo ---
    if ($InitLocalGit -and -not (Test-Path (Join-Path $localPath '.git'))) {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            git -C $localPath init | Out-Null
            $localGitignore = Join-Path $localPath '.gitignore'
            if (-not (Test-Path $localGitignore)) {
                Set-Content -Path $localGitignore -Value $ignoreLine -Encoding utf8
            }
            Write-Host "Initialized git repo in $localPath"
        } else {
            Write-Warning "git not found on PATH; skipped 'git init' in $localPath"
        }
    }

    Write-Host "`nDone. Created/verified:"
    Write-Host "  $repoPath/.gitignore                       (ensured $ignoreLine)"
    Write-Host "  $repoPath/.claude/settings.local.json"
    Write-Host "  $repoPath/CLAUDE.local.md"
    Write-Host "  $localPath/CLAUDE.md"
    Write-Host "  $localPath/.claude/settings.local.json"
    Write-Host "  $localPath/$repoName.code-workspace"
    $LocalFolders | ForEach-Object { Write-Host "  $localPath/$_/" }

    [PSCustomObject]@{
        RepoPath      = $repoPath
        LocalPath     = $localPath
        WorkspaceFile = $workspacePath
    }
}
