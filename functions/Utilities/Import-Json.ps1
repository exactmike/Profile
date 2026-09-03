#requires -Version 7.0

function Import-Json {
    <#
    .SYNOPSIS
        Reads one or more JSON files and converts their content to objects.
    .DESCRIPTION
        A proxy wrapper around ConvertFrom-Json that adds file input. Every ConvertFrom-Json
        parameter (AsHashtable, Depth, NoEnumerate, DateKind) is forwarded transparently;
        -FilePath and -Encoding control which file(s) to read and how.
    .PARAMETER FilePath
        Path(s) of the JSON file(s) to read.
    .PARAMETER Encoding
        Character encoding to use when reading the file. Accepts the same values as Get-Content.
    .PARAMETER AsHashtable
        Passed through to ConvertFrom-Json.
    .PARAMETER Depth
        Passed through to ConvertFrom-Json.
    .PARAMETER NoEnumerate
        Passed through to ConvertFrom-Json.
    .PARAMETER DateKind
        Passed through to ConvertFrom-Json.
    .EXAMPLE
        Import-Json -FilePath .\procs.json -AsHashtable

        Reads procs.json and returns its content as a hashtable.
    .EXAMPLE
        'a.json', 'b.json' | Import-Json

        Reads and converts both files; a file that is missing or empty reports a non-terminating
        error for that file and processing continues with the rest.
    .INPUTS
        System.String. Path(s) of the JSON file(s) to read.
    .OUTPUTS
        System.Object. The deserialized content of each file.
    .LINK
        ConvertFrom-Json
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PSPath', 'FullName')]
        [ValidateScript({ Test-Path -Path $_ })]
        [string[]]$FilePath
        ,
        [System.Text.Encoding]$Encoding
        ,
        [switch]$AsHashtable
        ,
        [int]$Depth
        ,
        [switch]$NoEnumerate
        ,
        [Microsoft.PowerShell.Commands.JsonDateKind]$DateKind
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        try {
            $encodingBound = $PSBoundParameters.ContainsKey('Encoding')
            $null = $PSBoundParameters.Remove('FilePath')
            $null = $PSBoundParameters.Remove('Encoding')

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('ConvertFrom-Json', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
            # Begin(bool), not Begin($PSCmdlet): ConvertFrom-Json's InputObject is mandatory, and
            # Begin($PSCmdlet) validates mandatory parameters immediately instead of deferring to
            # the per-item Process() calls below.
            $steppablePipeline.Begin($true)
        }
        catch {
            throw
        }
    }

    process {
        foreach ($f in $FilePath) {
            Write-Verbose -Message "Processing path [$f]"

            $getContentParams = @{ Path = $f; Raw = $true }
            if ($encodingBound) {
                $getContentParams.Encoding = $Encoding
            }

            try {
                $content = Get-Content @getContentParams -ErrorAction Stop
            }
            catch {
                Write-Error -ErrorRecord $_
                continue
            }

            if ([string]::IsNullOrWhiteSpace($content)) {
                Write-Error -Message "No content found in file [$f]"
                continue
            }

            try {
                $steppablePipeline.Process($content)
            }
            catch {
                throw
            }
        }
    }

    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }
}
