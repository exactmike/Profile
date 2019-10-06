function Out-FunctionFile
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.FunctionInfo]$FunctionInfo
        ,
        [Parameter(Mandatory)]
        [string]$Path
    )
    process
    {
        foreach ($Function in $FunctionInfo)
        {
            $FileName = $Function.Name + '.ps1'
            $Contents =
            @"
Function $($Function.Name)
{
    $($Function.Scriptblock)
}

"@
            $outpath = Join-Path -Path $Path -ChildPath $FileName
            $Contents | Out-File -FilePath $outpath -Encoding utf8
        }
    }
}