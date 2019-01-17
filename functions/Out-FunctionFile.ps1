function Out-FunctionFile
{
    [CmdletBinding()]
    param(
        $Function,
        $Path
    )

    $FileName = $Function.Name + '.ps1'
    $Contents = @"
    Function $($Function.Name)
    {
        $($Function.Scriptblock)
    }

"@
    $outpath = Join-Path -Path $Path -ChildPath $FileName
    $Contents | Out-File -FilePath $outpath -Encoding utf8
}