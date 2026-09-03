#requires -Version 7.0

function Export-Json {
    <#
    .SYNOPSIS
        Converts an object to JSON and writes it to a file.
    .DESCRIPTION
        A proxy wrapper around ConvertTo-Json that adds file output. Every ConvertTo-Json
        parameter (Depth, Compress, EnumsAsStrings, AsArray, EscapeHandling) is forwarded
        transparently; -FilePath and -Encoding control where and how the JSON is written.
    .PARAMETER FilePath
        Path of the file to write the JSON output to.
    .PARAMETER Encoding
        Character encoding to use when writing the file. Accepts the same values as Out-File
        (e.g. utf8, utf8NoBOM, ascii, unicode). Defaults to Out-File's own default when omitted.
    .PARAMETER InputObject
        Object(s) to convert to JSON. Multiple pipeline objects are collected into a single
        JSON array, matching ConvertTo-Json's own aggregation behavior.
    .PARAMETER Depth
        Passed through to ConvertTo-Json.
    .PARAMETER Compress
        Passed through to ConvertTo-Json.
    .PARAMETER EnumsAsStrings
        Passed through to ConvertTo-Json.
    .PARAMETER AsArray
        Passed through to ConvertTo-Json.
    .PARAMETER EscapeHandling
        Passed through to ConvertTo-Json.
    .EXAMPLE
        Get-Process | Export-Json -FilePath .\procs.json -Depth 3 -Compress

        Converts running processes to compressed JSON and writes them to procs.json.
    .EXAMPLE
        Export-Json -InputObject $Config -FilePath .\config.json -Encoding utf8NoBOM

        Writes $Config to config.json as UTF-8 without a byte-order mark.
    .INPUTS
        System.Object. Objects to convert to JSON.
    .OUTPUTS
        None.
    .LINK
        ConvertTo-Json
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('PSPath', 'FullName')]
        [string]$FilePath
        ,
        [string]$Encoding
        ,
        [Parameter(ValueFromPipeline)]
        [psobject]$InputObject
        ,
        [int]$Depth
        ,
        [switch]$Compress
        ,
        [switch]$EnumsAsStrings
        ,
        [switch]$AsArray
        ,
        [Newtonsoft.Json.StringEscapeHandling]$EscapeHandling
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        try {
            $encodingBound = $PSBoundParameters.ContainsKey('Encoding')

            $null = $PSBoundParameters.Remove('FilePath')
            $null = $PSBoundParameters.Remove('Encoding')
            # ConvertTo-Json has no SupportsShouldProcess, so it doesn't accept -WhatIf/-Confirm
            # even though our own SupportsShouldProcess adds them to $PSBoundParameters.
            $null = $PSBoundParameters.Remove('WhatIf')
            $null = $PSBoundParameters.Remove('Confirm')

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('ConvertTo-Json', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
            # Begin(bool), not Begin($PSCmdlet): we need to capture ConvertTo-Json's JSON text
            # ourselves (to write it to a file) rather than let it stream straight through as
            # this function's own pipeline output.
            $steppablePipeline.Begin($true)
        }
        catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        try {
            $json = $steppablePipeline.End()

            $outFileParams = @{ FilePath = $FilePath }
            if ($encodingBound) {
                $outFileParams.Encoding = $Encoding
            }

            if ($PSCmdlet.ShouldProcess($FilePath, 'Export JSON')) {
                $json | Out-File @outFileParams -ErrorAction Stop
            }
        }
        catch {
            throw
        }
    }
}
