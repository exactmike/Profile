# PowerShell Agent Coding Standards

*Derived from the PoshCode PowerShell Practice and Style guide [^1]. Apply these rules whenever generating, editing, or reviewing PowerShell code.*

---

## 1. Core Principles

- Write code that is **reusable, readable, and maintainable**.
- Prefer **native PowerShell** over .NET, COM, or external tools when possible.
- Use **approved PowerShell verbs** and **Verb-Noun** naming.
- Always use `[CmdletBinding()]` on scripts and functions.
- Keep functions small, focused, and pipeline-friendly.
- Document your reasoning, not just what the code does.

---

## 2. Naming and Capitalization

| Element | Convention | Example |
|---------|-----------|---------|
| Functions / cmdlets | `Verb-Noun`, PascalCase | `Get-Process`, `Start-AzureRmVM` |
| Parameters | PascalCase | `-ComputerName`, `-ServerInstance` |
| Modules, classes, enums, attributes | PascalCase | `MyModule`, `MyClass` |
| Global/script variables | Use scope prefix + PascalCase | `$Script:LogPath`, `$Global:DebugPreference` |
| Private variables | camelCase (optional) | `adComputer` |
| Two-letter acronyms | Both caps | `$PSBoundParameters`, `Get-PSDrive` |
| Keywords and operators | lowercase | `foreach`, `-eq`, `-match` |
| Comment-based help keywords | UPPERCASE | `.SYNOPSIS`, `.DESCRIPTION` |

- **Use full command names**, never aliases like `gps`, `ls`, `dir`, `gci`.
- **Use full parameter names**, never positional or abbreviated parameters.

```powershell
# BAD
gps Explorer
dir -r

# GOOD
Get-Process -Name Explorer
Get-ChildItem -Recurse
```

---

## 3. Code Layout and Formatting

### Brace style: One True Brace Style (OTBS)
- Opening brace on the **same line** as the statement.
- Closing brace on its **own line**.

```powershell
# GOOD
if ($this -gt $that) {
    Do-Something -With $that
}

foreach ($computer in $computers) {
    Do-This
    Get-Those
}

# BAD
if ($this -gt $that)
{
    Do-Something -With $that
}
```

### Indentation
- Use **4 spaces** per indentation level.
- Do not use tab characters.

### Line length
- Limit lines to **115 characters** when possible.
- Prefer **splatting** and natural line breaks inside `()`, `[]`, `{}` over backticks.
- **Avoid backticks** for line continuation.

```powershell
# BAD
Get-Process -Name Explorer -ComputerName Server01 -ErrorAction SilentlyContinue `
    -IncludeUserName

# GOOD
$processParams = @{
    Name         = 'Explorer'
    ComputerName = 'Server01'
    ErrorAction  = 'SilentlyContinue'
    IncludeUserName = $true
}
Get-Process @processParams
```

### Whitespace
- Use **single spaces** around operators and parameter names.
- Use **single spaces** after commas and semicolons.
- Use **single spaces inside** `$(...)` and `{...}` blocks.
- **No trailing whitespace**.
- Surround function/class definitions with **two blank lines**.
- Surround method definitions with **one blank line**.
- End each file with **one blank line**.

```powershell
# GOOD
$Result = ($ValueOne + $ValueTwo) - $ValueThree

# BAD
$Result=($ValueOne+$ValueTwo)-$ValueThree
```

### Semicolons
- **Do not use semicolons** as line terminators.

---

## 4. Function Structure

### Always start with this template

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Short description.

    .DESCRIPTION
        Longer description.

    .PARAMETER ParamName
        Description of parameter.

    .EXAMPLE
        Verb-Noun -ParamName 'Value'
    #>
    [CmdletBinding()]
    [OutputType([psobject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ParamName
    )

    begin {
        # Optional one-time setup
    }

    process {
        # Per-input-object processing
        # Output objects here
    }

    end {
        # Optional cleanup
    }
}
```

### Rules
- **Always use `[CmdletBinding()]`**.
- Use `param()`, `begin`, `process`, `end` in execution order.
- If any parameter accepts pipeline input, include a `process {}` block.
- Use **`[OutputType()]`** when the function returns objects.
- **Do not use `return`** to output objects; just place the object on its own line.
- Return objects inside `process {}`, not `begin {}` or `end {}`.
- If using `ParameterSetName`, set `DefaultParameterSetName` in `[CmdletBinding()]`.

### Parameter validation
- Prefer validation attributes over body validation.

```powershell
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ComputerName,

    [ValidateSet('Low', 'Average', 'High')]
    [string]$Detail = 'Average',

    [ValidateRange(1, 100)]
    [int]$RetryCount = 3
)
```

---

## 5. Documentation and Comments

### Comment-based help
- **Always write comment-based help** inside the function, at the top.
- Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE`.
- Put parameter help directly above each parameter in the `param` block.
- Keep language simple, clear, and concise.

```powershell
function Get-Example {
    <#
    .SYNOPSIS
        Gets example data.

    .DESCRIPTION
        Retrieves example data from the system.

    .PARAMETER Name
        The name to filter by.

    .EXAMPLE
        Get-Example -Name 'Test'
    #>
    param (
        # The name to filter by
        [string]$Name
    )
    ...
}
```

### Inline comments
- Explain **why**, not what.
- Keep comments in English, complete sentences.
- Separate inline comments from code by at least two spaces.
- Use block comments (`<# ... #>`) for long explanations.

```powershell
# BAD
# Increment Margin by 2
$Margin = $Margin + 2

# GOOD
# The rendering box obscures a couple of pixels.
$Margin = $Margin + 2
```

---

## 6. Tool vs. Controller Design

| Type | Purpose | Output |
|------|---------|--------|
| **Tool** | Reusable function/module | Raw objects to pipeline |
| **Controller** | Automates one business process | Formatted data, logs, screen |

- **Tools** accept input via parameters and output raw objects.
- **Controllers** may reformat data for a specific task.
- Use `.format.ps1xml` files in module manifests for default views of custom objects.

---

## 7. Output and Streams

| Stream | Use For |
|--------|---------|
| Pipeline | Primary output objects |
| `Write-Verbose` | Status and detail the user doesn't need |
| `Write-Debug` | Maintainer/debugging info |
| `Write-Progress` | Long-running progress |
| `Write-Warning` | Non-fatal issues |
| `Write-Error` | Non-terminating errors |
| `Write-Host` | Only interactive prompts, `Show-*`, or `Format-*` functions |

- **Do not use `Write-Host`** for normal output.
- **Do not use format commands inside functions**.
- Output only **one type of object** at a time from external functions.
- Use `[OutputType()]` to declare output types.

---

## 8. Error Handling

- Use `-ErrorAction Stop` when trapping cmdlet errors.
- Set `$ErrorActionPreference = 'Stop'` around non-cmdlet code, then restore it.
- Keep the failing operation focused on **one thing** at a time.
- Put the entire transaction inside the `try` block.
- **Do not use flags** to handle errors.
- **Do not use `$?`** for error checking.
- **Do not test for `$null` as a primary error condition**.
- In `catch`, immediately copy `$_` or `$Error[0]` into your own variable.

```powershell
try {
    $Result = Do-Something -ErrorAction Stop
    Set-That -Input $Result
    Get-Those
} catch {
    $ErrorRecord = $_
    Write-Error -ErrorRecord $ErrorRecord
}
```

---

## 9. Performance

- **If performance matters, measure it** with `Measure-Command`.
- Prefer language constructs over cmdlets when performance is critical.
- Use the pipeline to stream large datasets instead of buffering them in memory.
- Consider wrapping .NET code in PowerShell functions for reusable performance.
- Balance readability with performance; do not sacrifice readability for trivial gains.

```powershell
# Streaming large files
Get-Content -Path 'huge.txt' -ReadCount 1000 |
    ForEach-Object {
        # process batches
    }
```

---

## 10. Paths and File Operations

- Use **full, explicit paths** when possible.
- Base paths on `$PSScriptRoot` rather than relative paths.
- **Do not use `~`** for home directory; use `${Env:UserProfile}` or the file system provider's home.

```powershell
# BAD
$Path = '~\config.json'

# GOOD
$Path = Join-Path -Path ${Env:UserProfile} -ChildPath 'config.json'
```

---

## 11. Anti-Patterns to Avoid

| Avoid | Instead |
|-------|---------|
| Aliases | Full command names |
| Positional parameters | Named parameters |
| `return` keyword | Implicit output |
| Backticks for continuation | Splatting, natural line breaks |
| `Write-Host` for output | Pipeline output, `Write-Verbose` |
| Semicolons as terminators | New lines |
| `$?` for error checking | `try/catch` with `-ErrorAction Stop` |
| Flags for error handling | Transactional `try` blocks |
| `~` in paths | `${Env:UserProfile}`, `$PSScriptRoot` |
| Relative paths | `$PSScriptRoot`-based absolute paths |
| Mixing output types | Single output type per command |

---

## 12. When to Use This Guide

Apply these standards whenever you:
- Generate new PowerShell scripts, functions, or modules.
- Refactor or review existing PowerShell code.
- Design parameters, error handling, or output for a command.
- Choose between native PowerShell, .NET, or external tools.

When a project has its own style rules, follow those. Otherwise, default to this guide.

---

## How to Use This File

Save this as one of these names in your project root or `.ai/` directory:

- `CLAUDE.md` (Claude Code / Claude Desktop will auto-load it)
- `AGENT_GUIDE.md`
- `.ai/powershell-standards.md`

For other agents, include it in the system prompt or context window when working on PowerShell code.

**References**

[^1]: [About this Guide | PowerShell Practice and Style](https://poshcode.gitbook.io/powershell-practice-and-style) (100%)