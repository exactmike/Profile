#requires -Version 7.0

function New-RepoPair {
    <#
    .SYNOPSIS
        Sets up a "local_<repo>" companion directory next to an existing git repository clone, wired up so
        that Claude Code, Codex, and Antigravity all read one shared instruction set and record their work
        in the companion repo.

    .DESCRIPTION
        Given the path to an existing cloned repository (e.g. C:\dev\InstallManager), this creates a sibling
        directory (e.g. C:\dev\local_InstallManager) for the records *around* the work: session logs,
        decisions, plans, issue and PR drafts, memory, tools, and secrets. It then configures each supported
        coding agent to use it:

        In local_<repo> (the source of truth):
          - AGENTS.md         Shared instructions for every agent, including the record-keeping rules.
          - CLAUDE.md         "@AGENTS.md" import stub for Claude Code.
          - templates/        Session, decision, issue, pull-request, and plan templates.
          - tools/hooks/      Invoke-PairSessionHook.ps1, called by Claude Code and Codex session hooks.
          - .claude/settings.local.json, .codex/config.toml, .codex/hooks.json pointing back at the code repo.
          - <repo>.code-workspace multi-root workspace (VS Code and Antigravity).

        In the code repo (all untracked and hidden through .git/info/exclude, so nothing is committed and the
        tracked .gitignore is not changed):
          - CLAUDE.local.md   Imports ../local_<repo>/AGENTS.md (and ./AGENTS.md if upstream has one).
          - AGENTS.md         Pair contract for Codex and Antigravity, or AGENTS.override.md when the
                              upstream repo already has its own AGENTS.md (which is never modified).
          - .agents/rules/repo-pair.md   Always-on Antigravity rule with the pair contract.
          - .claude/settings.local.json  additionalDirectories, autoMemoryDirectory and plansDirectory
                                         redirected into local_<repo>, and session hooks. Merged into any
                                         existing file.
          - .codex/config.toml, .codex/hooks.json   "repo-pair" permission profile (write access to both
                                                    repos), memories off, hooks on.

        Steps that cannot be automated (trusting a project in Codex, approving an import in Claude Code,
        opening the workspace in Antigravity, and so on) are printed at the end and returned in NextSteps.

        Safe to re-run: existing files are left alone unless -Force is passed. When -Force overwrites a file
        whose content changed, the old file is kept as <file>.bak-<timestamp>. Files that are tracked by git
        in the code repo are never written; they are reported in NextSteps instead.

    .EXAMPLE
        New-RepoPair -RepoPath C:\dev\InstallManager

        Creates C:\dev\local_InstallManager and configures the pair for all three agents.

    .EXAMPLE
        New-RepoPair -RepoPath ~/dev/InstallManager -Force -LocalFolders sessions, plans, decisions, memory, research

        Regenerates the generated files (keeping .bak copies) with a custom folder list.

    .EXAMPLE
        (New-RepoPair -RepoPath . -WhatIf)

        Shows the code and local paths that would be used, without changing anything.

    .OUTPUTS
        PSCustomObject with RepoPath, LocalPath, WorkspaceFile, FilesWritten, and NextSteps.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive setup report for a person; the returned object carries the same data.')]
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        # Path to the existing repository clone (relative or absolute).
        [Parameter(Mandatory, Position = 0)]
        [string]$RepoPath,

        # Subfolders to create inside the local companion repo. 'sessions', 'decisions', 'plans', 'issues',
        # 'pull-requests', 'memory', 'templates', and 'tools' are referenced by the generated instructions.
        [string[]]$LocalFolders = @(
            'agent-instructions', 'sessions', 'decisions', 'plans', 'pull-requests', 'checklists', 'briefings',
            'issues', 'memory', 'templates', 'artifacts', 'captures', 'secrets', 'tools'
        ),

        # Prefix used to name the companion directory.
        [string]$LocalPrefix = 'local_',

        # Initialize the companion directory as its own git repository.
        [bool]$InitLocalGit = $true,

        # Overwrite existing generated files. Changed files are backed up as <file>.bak-<timestamp> first.
        # Folders are always created if missing, and JSON settings files are always merged, regardless of -Force.
        [switch]$Force
    )

    # --- Private helpers -------------------------------------------------------------------------------

    function ConvertTo-ForwardSlashPath {
        param([string]$Path)
        $Path -replace '\\', '/'
    }

    function Expand-PairTemplate {
        # Reads a template from RepoPairTemplates and replaces {{Token}} placeholders literally.
        param([string]$Name, [hashtable]$Tokens)
        $text = Get-Content -Path (Join-Path -Path $templateRoot -ChildPath $Name) -Raw -ErrorAction Stop
        foreach ($key in $Tokens.Keys) {
            $text = $text.Replace("{{$key}}", [string]$Tokens[$key])
        }
        $text
    }

    function Write-PairFile {
        # Writes a file when it is missing, or when -Force is set. Backs up changed content first.
        # Returns $true when the file was written.
        param([string]$Path, [string]$Content, [switch]$Overwrite)
        $exists = Test-Path -Path $Path
        if ($exists -and -not $Overwrite) {
            $false
            return
        }
        if ($exists) {
            $current = Get-Content -Path $Path -Raw
            if ($current -eq $Content) {
                $false
                return
            }
            Copy-Item -Path $Path -Destination "$Path.bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
        }
        New-Item -ItemType Directory -Path (Split-Path -Path $Path -Parent) -Force | Out-Null
        Set-Content -Path $Path -Value $Content -Encoding utf8NoBOM -NoNewline
        $filesWritten.Add($Path)
        $true
    }

    function Test-GitTracked {
        # True when the path (relative to the code repo root) is tracked by git.
        param([string]$RelativePath)
        if (-not $repoIsGit) {
            $false
            return
        }
        git -C $repoPath ls-files --error-unmatch -- $RelativePath 2>$null | Out-Null
        $LASTEXITCODE -eq 0
    }

    function Add-NextStep {
        param([string]$Agent, [string]$Step)
        $nextSteps.Add([PSCustomObject]@{ Agent = $Agent; Step = $Step })
    }

    function Write-CodeRepoFile {
        # Writes a pointer file into the code repo unless git tracks it, and records it for .git/info/exclude.
        param([string]$RelativePath, [string]$Content, [switch]$Overwrite)
        if (Test-GitTracked -RelativePath $RelativePath) {
            Add-NextStep -Agent 'General' -Step ("Skipped '$RelativePath' in $repoName because git tracks it. " +
                'Configure that agent by hand, or ask the upstream maintainers before changing the file.')
            return
        }
        $excludeEntries.Add('/' + (ConvertTo-ForwardSlashPath -Path $RelativePath))
        # Backups made by -Force or by an upgrade sit next to the file and must stay out of git too.
        $excludeEntries.Add('/' + (ConvertTo-ForwardSlashPath -Path $RelativePath) + '.bak-*')
        Write-PairFile -Path (Join-Path -Path $repoPath -ChildPath $RelativePath) -Content $Content -Overwrite:$Overwrite |
            Out-Null
    }

    function Merge-ClaudeSetting {
        # Merges the pair keys into a .claude/settings.local.json file, keeping everything else in it.
        param([string]$Path, [string]$OtherDirectory)
        $settings = [ordered]@{}
        if (Test-Path -Path $Path) {
            $settings = Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        }
        $before = $settings | ConvertTo-Json -Depth 20

        if (-not $settings.Contains('permissions')) { $settings['permissions'] = [ordered]@{} }
        $dirs = [System.Collections.Generic.List[string]]::new()
        foreach ($d in @($settings['permissions']['additionalDirectories'])) {
            if ($d) { $dirs.Add($d) }
        }
        if ($OtherDirectory -notin $dirs) { $dirs.Add($OtherDirectory) }
        $settings['permissions']['additionalDirectories'] = $dirs.ToArray()

        $settings['autoMemoryDirectory'] = "$localPathFwd/memory"
        $settings['plansDirectory'] = "$localPathFwd/plans"

        if (-not $settings.Contains('hooks')) { $settings['hooks'] = [ordered]@{} }
        foreach ($hookEvent in 'SessionStart', 'Stop') {
            $entries = [System.Collections.Generic.List[object]]::new()
            foreach ($e in @($settings['hooks'][$hookEvent])) {
                if ($e) { $entries.Add($e) }
            }
            if (-not (($entries | ConvertTo-Json -Depth 20) -match 'Invoke-PairSessionHook')) {
                $entries.Add([ordered]@{
                        hooks = @([ordered]@{ type = 'command'; command = (Get-HookCommand -HookEvent $hookEvent -Agent 'claude') })
                    })
            }
            $settings['hooks'][$hookEvent] = $entries.ToArray()
        }

        $after = $settings | ConvertTo-Json -Depth 20
        if ($before -ne $after -or -not (Test-Path -Path $Path)) {
            New-Item -ItemType Directory -Path (Split-Path -Path $Path -Parent) -Force | Out-Null
            Set-Content -Path $Path -Value $after -Encoding utf8NoBOM
            $filesWritten.Add($Path)
        }
    }

    function Get-HookCommand {
        param([string]$HookEvent, [string]$Agent)
        "pwsh -NoProfile -File `"$hookScriptFwd`" -Event $HookEvent -Agent $Agent"
    }

    function Get-CodexConfig {
        # Permission profile that extends the built-in :workspace profile with the other half of the pair.
        # The filesystem table restores the read-only protection of .git, .codex, and .agents that :workspace
        # applies, for both roots. Verified against codex-cli 0.165.0 with 'codex debug prompt-input'.
        param([string]$OtherRoot)
        @"
# Generated by New-RepoPair. Codex loads this project config only when the project is trusted
# (see ~/.codex/config.toml [projects]).

default_permissions = "repo-pair"

[permissions.repo-pair]
description = "Workspace access plus the other repo of the pair"
extends = ":workspace"

[permissions.repo-pair.workspace_roots]
'$OtherRoot' = true

[permissions.repo-pair.filesystem.":workspace_roots"]
"." = "write"
".git" = "read"
".codex" = "read"
".agents" = "read"

[features]
hooks = true
memories = false

"@
    }

    function Test-StaleCodexConfig {
        # True for a .codex/config.toml written by an earlier New-RepoPair (sandbox_workspace_write format).
        param([string]$Path)
        (Test-Path -Path $Path) -and ((Get-Content -Path $Path -Raw) -match 'Generated by New-RepoPair') -and
            ((Get-Content -Path $Path -Raw) -notmatch 'default_permissions')
    }

    function Get-CodexHookConfig {
        [ordered]@{
            hooks = [ordered]@{
                SessionStart = @([ordered]@{
                        hooks = @([ordered]@{ type = 'command'; command = (Get-HookCommand -HookEvent 'SessionStart' -Agent 'codex') })
                    })
                Stop         = @([ordered]@{
                        hooks = @([ordered]@{ type = 'command'; command = (Get-HookCommand -HookEvent 'Stop' -Agent 'codex') })
                    })
            }
        } | ConvertTo-Json -Depth 10
    }

    # --- Resolve and validate the source repo ---------------------------------------------------------
    $repoPath = (Resolve-Path -Path $RepoPath -ErrorAction Stop).Path.TrimEnd('\', '/')
    $repoName = Split-Path -Path $repoPath -Leaf
    $parentDir = Split-Path -Path $repoPath -Parent
    $localName = "$LocalPrefix$repoName"
    $localPath = Join-Path -Path $parentDir -ChildPath $localName
    $localPathFwd = ConvertTo-ForwardSlashPath -Path $localPath
    $repoPathFwd = ConvertTo-ForwardSlashPath -Path $repoPath
    $templateRoot = Join-Path -Path $PSScriptRoot -ChildPath 'RepoPairTemplates'
    $hookScriptPath = Join-Path -Path $localPath -ChildPath 'tools' -AdditionalChildPath 'hooks', 'Invoke-PairSessionHook.ps1'
    $hookScriptFwd = ConvertTo-ForwardSlashPath -Path $hookScriptPath

    $hasGit = [bool](Get-Command -Name git -ErrorAction SilentlyContinue)
    $repoIsGit = $false
    if ($hasGit) {
        git -C $repoPath rev-parse --show-toplevel 2>$null | Out-Null
        $repoIsGit = $LASTEXITCODE -eq 0
    }
    if (-not $repoIsGit) {
        Write-Warning ("'$repoPath' is not a git repository (or git is not on PATH). Continuing, but pointer " +
            'files in it cannot be hidden with .git/info/exclude.')
    }

    Write-Host "Repo:  $repoPath"
    Write-Host "Local: $localPath"

    if (-not $PSCmdlet.ShouldProcess($localPath, 'Create agent repo pair (Claude Code, Codex, Antigravity)')) {
        return
    }

    $filesWritten = [System.Collections.Generic.List[string]]::new()
    $nextSteps = [System.Collections.Generic.List[PSCustomObject]]::new()
    $excludeEntries = [System.Collections.Generic.List[string]]::new()

    # --- Directory structure --------------------------------------------------------------------------
    New-Item -ItemType Directory -Path $localPath -Force | Out-Null
    foreach ($folder in $LocalFolders) {
        $folderPath = Join-Path -Path $localPath -ChildPath $folder
        if (-not (Test-Path -Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            # Keep otherwise-empty folders trackable in git.
            New-Item -ItemType File -Path (Join-Path -Path $folderPath -ChildPath '.gitkeep') -Force | Out-Null
        }
    }

    # --- Folder descriptions used in the generated instructions ---------------------------------------
    $folderDescriptions = @{
        'agent-instructions' = 'Extra instruction files for agents (task-specific guides, prompts).'
        'sessions'           = 'One log per agent session: `YYYY-MM-DD-<agent>-<topic>.md`.'
        'decisions'          = 'Numbered decision records: `NNNN-<short-title>.md`.'
        'plans'              = 'Implementation plans: `YYYY-MM-DD-<topic>.md`.'
        'pull-requests'      = 'PR title and description drafts: `<branch-name>.md`.'
        'checklists'         = 'Reusable checklists (release, review, setup).'
        'briefings'          = 'Orientation notes and summaries for people or agents new to the work.'
        'issues'             = 'Bugs, gaps, and follow-ups not yet fixed: `<short-title>.md`.'
        'memory'             = 'Durable facts every agent should know, one topic per file. Use this instead of tool memory.'
        'templates'          = 'Templates for session, decision, issue, pull-request, and plan records.'
        'artifacts'          = 'Generated output: reports, exports, diagrams.'
        'captures'           = 'Screenshots, logs, and other raw captures.'
        'secrets'            = 'Local secrets. Gitignored. Never copy them into the code repo or into a record.'
        'tools'              = 'Local scripts and tools for this pair (tools/hooks holds the session hook).'
    }
    $folderList = ($LocalFolders | ForEach-Object -Process {
            $description = $folderDescriptions[$_] ?? '(add a description)'
            "- ``./$_/`` - $description"
        }) -join "`n"
    $recordFolders = 'sessions', 'decisions', 'plans', 'issues', 'pull-requests', 'memory'
    $contractFolderList = ($recordFolders | Where-Object -FilterScript { $_ -in $LocalFolders } |
            ForEach-Object -Process { "  - ``../$localName/$_/`` - $($folderDescriptions[$_])" }) -join "`n"

    $tokens = @{
        RepoName     = $repoName
        LocalName    = $localName
        RepoPath     = $repoPathFwd
        LocalPath    = $localPathFwd
        FolderList         = $folderList
        ContractFolderList = $contractFolderList
        UpstreamNote       = ''
    }

    # --- local_<repo>: shared instructions, Claude stub, templates, hook script ------------------------
    $localAgentsPath = Join-Path -Path $localPath -ChildPath 'AGENTS.md'
    Write-PairFile -Path $localAgentsPath -Content (Expand-PairTemplate -Name 'local-AGENTS.md' -Tokens $tokens) -Overwrite:$Force |
        Out-Null
    if ((Get-Content -Path $localAgentsPath -Raw) -notmatch 'repo-pair:v2') {
        Add-NextStep -Agent 'General' -Step ("$localAgentsPath was written by an older version and has no record-keeping " +
            "rules. Re-run with -Force (a .bak copy is kept) or merge in $templateRoot\local-AGENTS.md by hand.")
    }

    $claudeStub = "@AGENTS.md`n"
    $localClaudeMdPath = Join-Path -Path $localPath -ChildPath 'CLAUDE.md'
    if ((Test-Path -Path $localClaudeMdPath) -and -not $Force -and
        (Get-Content -Path $localClaudeMdPath -Raw).Trim() -ne $claudeStub.Trim()) {
        Add-NextStep -Agent 'Claude Code' -Step ("$localClaudeMdPath has its own content, so Claude Code reads it instead of " +
            'AGENTS.md. Move anything still useful into AGENTS.md, then re-run with -Force to replace CLAUDE.md with ' +
            'the "@AGENTS.md" stub (a .bak copy is kept).')
    }
    Write-PairFile -Path $localClaudeMdPath -Content $claudeStub -Overwrite:$Force | Out-Null

    foreach ($template in Get-ChildItem -Path (Join-Path -Path $templateRoot -ChildPath 'records') -File) {
        $target = Join-Path -Path $localPath -ChildPath 'templates' -AdditionalChildPath $template.Name
        Write-PairFile -Path $target -Content (Get-Content -Path $template.FullName -Raw) -Overwrite:$Force | Out-Null
    }

    # The hook script is a .template file so the Profile module does not dot-source it. It is always
    # refreshed, because it has no user content.
    Write-PairFile -Path $hookScriptPath -Overwrite `
        -Content (Get-Content -Path (Join-Path -Path $templateRoot -ChildPath 'Invoke-PairSessionHook.ps1.template') -Raw) |
        Out-Null

    # --- Code repo: pointer files for each agent -------------------------------------------------------
    $upstreamAgentsMd = $false
    $codeAgentsPath = Join-Path -Path $repoPath -ChildPath 'AGENTS.md'
    if (Test-Path -Path $codeAgentsPath) {
        # An AGENTS.md is ours only when it is untracked and carries our marker.
        $upstreamAgentsMd = (Test-GitTracked -RelativePath 'AGENTS.md') -or
            ((Get-Content -Path $codeAgentsPath -Raw) -notmatch 'repo-pair:v2')
    }

    if ($upstreamAgentsMd) {
        $tokens.UpstreamNote = "`nThis repo also has its own upstream ``AGENTS.md``. **Read ``./AGENTS.md`` in full as well.** " +
            "It holds the project's own instructions. Where the two conflict on code style or build steps, the upstream " +
            "file wins. Where they conflict on where to keep records, this file wins.`n"
        Write-CodeRepoFile -RelativePath 'AGENTS.override.md' -Content (Expand-PairTemplate -Name 'pair-contract.md' -Tokens $tokens) `
            -Overwrite:$Force
        Add-NextStep -Agent 'Codex' -Step ("$repoName has an upstream AGENTS.md, so the pair contract was written to " +
            'AGENTS.override.md. Codex reads the override instead of AGENTS.md, and the override tells it to read ' +
            'AGENTS.md too. Check in a Codex session that it follows both.')
    } else {
        Write-CodeRepoFile -RelativePath 'AGENTS.md' -Content (Expand-PairTemplate -Name 'pair-contract.md' -Tokens $tokens) `
            -Overwrite:$Force
    }
    $tokens.UpstreamNote = ''

    # Antigravity: always-on workspace rule. Works alongside any upstream AGENTS.md or GEMINI.md.
    $antigravityRule = "---`ntrigger: always_on`ndescription: Repo pair contract for $repoName + $localName`n---`n`n" +
        (Expand-PairTemplate -Name 'pair-contract.md' -Tokens $tokens)
    Write-CodeRepoFile -RelativePath '.agents/rules/repo-pair.md' -Content $antigravityRule -Overwrite:$Force

    # Claude Code: CLAUDE.local.md stops Claude from auto-reading AGENTS.md, so import an upstream one explicitly.
    $claudeLocalLines = [System.Collections.Generic.List[string]]::new()
    $claudeLocalLines.Add("@../$localName/AGENTS.md")
    if ($upstreamAgentsMd) { $claudeLocalLines.Add('@AGENTS.md') }
    $claudeLocalLines.Add('')
    $claudeLocalLines.Add("<!-- repo-pair:v2 - local only, excluded via .git/info/exclude. If the import above did not load, " +
        "read ../$localName/AGENTS.md before you start. -->")
    $claudeLocalLines.Add('')
    $claudeLocalLines.Add('## Notes specific to this repo')
    $claudeLocalLines.Add('- (add build/test commands, branch conventions, etc. here)')
    $claudeLocalPath = Join-Path -Path $repoPath -ChildPath 'CLAUDE.local.md'
    if ((Test-Path -Path $claudeLocalPath) -and -not $Force) {
        $claudeLocalText = Get-Content -Path $claudeLocalPath -Raw
        if ($claudeLocalText -notmatch [regex]::Escape("@../$localName/AGENTS.md")) {
            Add-NextStep -Agent 'Claude Code' -Step "Add the line '@../$localName/AGENTS.md' to $claudeLocalPath (or re-run with -Force)."
        }
        if ($upstreamAgentsMd -and $claudeLocalText -notmatch '(?m)^@AGENTS\.md') {
            Add-NextStep -Agent 'Claude Code' -Step ("Add the line '@AGENTS.md' to $claudeLocalPath. Without it, Claude Code " +
                "skips the upstream AGENTS.md because CLAUDE.local.md exists.")
        }
    }
    Write-CodeRepoFile -RelativePath 'CLAUDE.local.md' -Content (($claudeLocalLines -join "`n") + "`n") -Overwrite:$Force

    # Claude Code settings in both repos: always merged, so -Force is not needed.
    foreach ($side in @(
            @{ Root = $repoPath; Other = "../$localName"; IsCode = $true }
            @{ Root = $localPath; Other = "../$repoName"; IsCode = $false }
        )) {
        $relative = '.claude/settings.local.json'
        if ($side.IsCode) {
            if (Test-GitTracked -RelativePath $relative) {
                Add-NextStep -Agent 'Claude Code' -Step "Skipped $relative in $repoName because git tracks it."
                continue
            }
            $excludeEntries.Add("/$relative")
        }
        Merge-ClaudeSetting -Path (Join-Path -Path $side.Root -ChildPath $relative) -OtherDirectory $side.Other
    }

    # Codex project config and hooks in both repos. A config from an earlier New-RepoPair is upgraded in place.
    $codexConfigCode = Join-Path -Path $repoPath -ChildPath '.codex' -AdditionalChildPath 'config.toml'
    $codexConfigLocal = Join-Path -Path $localPath -ChildPath '.codex' -AdditionalChildPath 'config.toml'
    Write-CodeRepoFile -RelativePath '.codex/config.toml' -Content (Get-CodexConfig -OtherRoot $localPathFwd) `
        -Overwrite:($Force -or (Test-StaleCodexConfig -Path $codexConfigCode))
    Write-CodeRepoFile -RelativePath '.codex/hooks.json' -Content ((Get-CodexHookConfig) + "`n") -Overwrite:$Force
    Write-PairFile -Path $codexConfigLocal -Content (Get-CodexConfig -OtherRoot $repoPathFwd) `
        -Overwrite:($Force -or (Test-StaleCodexConfig -Path $codexConfigLocal)) | Out-Null
    Write-PairFile -Path (Join-Path -Path $localPath -ChildPath '.codex' -AdditionalChildPath 'hooks.json') `
        -Content ((Get-CodexHookConfig) + "`n") -Overwrite:$Force | Out-Null

    # --- Hide the code-repo pointer files with .git/info/exclude ----------------------------------------
    if ($repoIsGit -and $excludeEntries.Count -gt 0) {
        $excludePath = git -C $repoPath rev-parse --git-path info/exclude
        if (-not [System.IO.Path]::IsPathRooted($excludePath)) {
            $excludePath = Join-Path -Path $repoPath -ChildPath $excludePath
        }
        $existingExclude = if (Test-Path -Path $excludePath) { @(Get-Content -Path $excludePath) } else { @() }
        $missing = @($excludeEntries | Select-Object -Unique | Where-Object -FilterScript { $_ -notin $existingExclude })
        if ($missing.Count -gt 0) {
            New-Item -ItemType Directory -Path (Split-Path -Path $excludePath -Parent) -Force | Out-Null
            $block = @('', '# repo pair files (New-RepoPair)') + $missing
            Add-Content -Path $excludePath -Value $block -Encoding utf8NoBOM
            $filesWritten.Add($excludePath)
        }
    }

    # Entries that earlier versions of this function added to the tracked .gitignore.
    $repoGitignore = Join-Path -Path $repoPath -ChildPath '.gitignore'
    if (Test-Path -Path $repoGitignore) {
        $legacy = @(Get-Content -Path $repoGitignore | Where-Object -FilterScript {
                $_.Trim() -in '.claude/settings.local.json', 'CLAUDE.local.md'
            })
        if ($legacy.Count -gt 0) {
            Add-NextStep -Agent 'General' -Step ("$repoGitignore still has entries from an older New-RepoPair ($($legacy -join ', ')). " +
                'They are now covered by .git/info/exclude. You can remove them from .gitignore, but that is a tracked ' +
                'change, so keep it out of upstream PRs.')
        }
    }

    # --- VS Code / Antigravity multi-root workspace file, inside the local companion repo ---------------
    $workspacePath = Join-Path -Path $localPath -ChildPath "$repoName.code-workspace"
    $workspaceJson = [ordered]@{
        folders  = @(
            [ordered]@{ path = "../$repoName"; name = $repoName }
            [ordered]@{ path = '.'; name = $localName }
        )
        settings = [ordered]@{ 'window.title' = "$repoName Workspace" }
    } | ConvertTo-Json -Depth 5
    Write-PairFile -Path $workspacePath -Content $workspaceJson -Overwrite:$Force | Out-Null

    # --- git in the local companion repo -----------------------------------------------------------------
    $localGitignore = Join-Path -Path $localPath -ChildPath '.gitignore'
    $localIgnoreLines = @(
        '# machine-specific settings (absolute paths)'
        '.claude/settings.local.json'
        '.codex/'
        '*.bak-*'
        ''
        '# local secrets'
        'secrets/*'
        '!secrets/.gitkeep'
    )
    $currentIgnore = if (Test-Path -Path $localGitignore) { @(Get-Content -Path $localGitignore) } else { @() }
    $missingIgnore = @($localIgnoreLines | Where-Object -FilterScript {
            $_ -and -not $_.StartsWith('#') -and $_ -notin $currentIgnore
        })
    if ($missingIgnore.Count -gt 0) {
        $toAdd = if ($currentIgnore.Count -eq 0) { $localIgnoreLines } else { @('') + $missingIgnore }
        Add-Content -Path $localGitignore -Value $toAdd -Encoding utf8NoBOM
        $filesWritten.Add($localGitignore)
    }

    if ($InitLocalGit -and -not (Test-Path -Path (Join-Path -Path $localPath -ChildPath '.git'))) {
        if ($hasGit) {
            git -C $localPath init | Out-Null
            Write-Host "Initialized git repo in $localPath"
        } else {
            Write-Warning "git not found on PATH; skipped 'git init' in $localPath"
        }
    }
    if ($hasGit -and (Test-Path -Path (Join-Path -Path $localPath -ChildPath '.git'))) {
        $trackedLocal = @(git -C $localPath ls-files -- '.claude/settings.local.json' '.codex' 2>$null)
        if ($trackedLocal.Count -gt 0) {
            Add-NextStep -Agent 'General' -Step ("$localName tracks machine-specific files ($($trackedLocal -join ', ')). Run " +
                "'git -C `"$localPath`" rm --cached $($trackedLocal -join ' ')' and commit, so .gitignore applies to them.")
        }
    }

    # --- Next steps that need a person -------------------------------------------------------------------
    $userHome = [Environment]::GetFolderPath('UserProfile')

    # Claude Code
    if (Get-Command -Name claude -ErrorAction SilentlyContinue) {
        Add-NextStep -Agent 'Claude Code' -Step ("Start 'claude' in $repoPath. When it asks to approve external imports " +
            "(../$localName/AGENTS.md), choose Yes. If you decline, Claude Code does not ask again and the import stays off.")
        Add-NextStep -Agent 'Claude Code' -Step ("In that session, run /memory and confirm that the auto memory folder is " +
            "$localPathFwd/memory, and /context to confirm that AGENTS.md loaded. At session start the hook shows a " +
            "one-line '[repo pair] Instructions: ...' notice; the full reminder goes to the model, not the screen.")
        foreach ($side in $repoPath, $localPath) {
            $oldMemory = Join-Path -Path $userHome -ChildPath '.claude' -AdditionalChildPath 'projects',
                ($side -replace '[^A-Za-z0-9]', '-'), 'memory'
            if (@(Get-ChildItem -Path $oldMemory -File -ErrorAction SilentlyContinue).Count -gt 0) {
                Add-NextStep -Agent 'Claude Code' -Step ("Claude has older auto memory for this pair in $oldMemory. Copy what " +
                    "is still useful into $localPath\memory, for example: Copy-Item '$oldMemory\*' '$localPath\memory\'")
            }
        }
    } else {
        Add-NextStep -Agent 'Claude Code' -Step 'claude is not on PATH. The files are in place; they apply when you install Claude Code.'
    }

    # Codex
    $codexConfigPath = Join-Path -Path $userHome -ChildPath '.codex' -AdditionalChildPath 'config.toml'
    if ((Get-Command -Name codex -ErrorAction SilentlyContinue) -or (Test-Path -Path $codexConfigPath)) {
        $codexConfigText = if (Test-Path -Path $codexConfigPath) { Get-Content -Path $codexConfigPath -Raw } else { '' }
        foreach ($side in $repoPath, $localPath) {
            # Codex matches project keys by the Windows (backslash) path, case-insensitively. A forward-slash key
            # is silently ignored (verified with codex-cli 0.165.0).
            $winSide = $side -replace '/', '\'
            $trusted = "(?ms)^\[projects\.['`"]$([regex]::Escape($winSide))['`"]\]\s*\r?\n\s*trust_level\s*=\s*`"trusted`""
            if ($codexConfigText -notmatch $trusted) {
                Add-NextStep -Agent 'Codex' -Step ("Trust $winSide so Codex loads its .codex/config.toml and hooks.json: " +
                    "start 'codex' in that folder and accept the trust prompt, or add this to ${codexConfigPath} " +
                    "(use backslashes; a forward-slash path is ignored):`n" +
                    "        [projects.'$winSide']`n        trust_level = `"trusted`"")
            }
        }
        Add-NextStep -Agent 'Codex' -Step ("In a Codex session in $repoName, run /hooks and trust the SessionStart and Stop " +
            'hooks. Codex skips project hooks until you review them, and asks again whenever a hook definition changes ' +
            '(for example after New-RepoPair -Force).')
        Add-NextStep -Agent 'Codex' -Step ("Verify file access without a model call: run 'codex debug prompt-input hi' in " +
            "$repoPath. The <filesystem> section must list write access to $localName (and read-only .git, .codex, " +
            '.agents). If it shows only read access to :root, the project is not trusted yet.')
        Add-NextStep -Agent 'Codex' -Step ("Start a new Codex session in $repoName (hooks trusted mid-session apply only to " +
            "new sessions) and send a first message. Codex shows a '[repo pair] Instructions: ...' warning line when the " +
            "SessionStart hook runs. Ask what the repo pair instructions say about session logs: the answer should name " +
            "$localName/sessions/ and today's file name.")
    } else {
        Add-NextStep -Agent 'Codex' -Step ('Codex is not installed (no codex on PATH, no ~/.codex). The project files are in place. ' +
            'After you install it, re-run New-RepoPair without -Force to get the trust steps.')
    }

    # Antigravity
    $antigravityHome = Join-Path -Path $userHome -ChildPath '.gemini' -AdditionalChildPath 'antigravity'
    if ((Get-Command -Name antigravity -ErrorAction SilentlyContinue) -or (Test-Path -Path $antigravityHome)) {
        Add-NextStep -Agent 'Antigravity' -Step ("Open $workspacePath with File > Open Workspace from File, not the single " +
            "folder. Both repos are then workspace roots, so the agent can read and write $localName without prompts.")
        Add-NextStep -Agent 'Antigravity' -Step ("Open Customizations > Rules and confirm that 'repo-pair' (from " +
            "$repoName/.agents/rules/repo-pair.md) is listed as Always On.")
        Add-NextStep -Agent 'Antigravity' -Step ("Antigravity keeps its own Knowledge Items in " +
            "$antigravityHome\knowledge, and has no per-project switch for them. The rules tell the agent to write to " +
            "$localName/memory instead. If new Knowledge Items about this repo appear there, move the useful content " +
            "to $localPath\memory.")
        Add-NextStep -Agent 'Antigravity' -Step 'Antigravity has no session hooks; the always-on rule is the only reminder to write a session log.'
    } else {
        Add-NextStep -Agent 'Antigravity' -Step 'Antigravity was not found (~/.gemini/antigravity). The rule files apply when you install it.'
    }

    # --- Report ------------------------------------------------------------------------------------------
    Write-Host "`nFiles written ($($filesWritten.Count)):"
    $filesWritten | ForEach-Object -Process { Write-Host "  $_" }
    if ($filesWritten.Count -eq 0) { Write-Host '  (none - everything was already in place; use -Force to regenerate)' }

    Write-Host "`nNext steps:"
    foreach ($group in $nextSteps | Group-Object -Property Agent) {
        Write-Host "`n  [$($group.Name)]" -ForegroundColor Cyan
        $i = 1
        foreach ($s in $group.Group) {
            Write-Host "  $i. $($s.Step)"
            $i++
        }
    }

    [PSCustomObject]@{
        RepoPath      = $repoPath
        LocalPath     = $localPath
        WorkspaceFile = $workspacePath
        FilesWritten  = $filesWritten.ToArray()
        NextSteps     = $nextSteps.ToArray()
    }
}
