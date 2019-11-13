Function Get-PSRHistory
{
    [CmdletBinding()]
    [outputtype([string[]])]
    param(
        [parameter(Position = 1)]
        [string]$SimpleMatch
    )

    function Get-RawPSReadLineHistory
    {
        Get-Content (Get-PSReadLineOption).HistorySavePath
    }
    switch ([string]::IsNullOrEmpty($SimpleMatch))
    {
        $true
        {
            Get-RawPSReadLineHistory
        }
        $false
        {
            Get-RawPSReadLineHistory | Select-String -SimpleMatch $SimpleMatch
        }
    }
}
