function Search-FileIndex
{
    <#
    .PARAMETER Path
    Absoloute or relative path. Has to be in the Search Index for results to be presented.
    .PARAMETER Pattern
    File name or pattern to search for. Defaults to *.*. Aliased to Filter to ergonomically match Get-ChildItem.
    .PARAMETER Text
    Free text to search for in the files defined by the pattern.
    .PARAMETER Recurse
    Add the parameter to perform a recursive search. Default is false.
    .PARAMETER AsFSInfo
    Add the parameter to return System.IO.FileSystemInfo objects instead of String objects.
    .SYNOPSIS
    Uses the Windows Search index to search for files.
    .DESCRIPTION
    Uses the Windows Search index to search for files.
    SQL Syntax documented at https://msdn.microsoft.com/en-us/library/windows/desktop/bb231256(v=vs.85).aspx
    Based on https://blogs.msdn.microsoft.com/mediaandmicrocode/2008/07/13/microcode-windows-powershell-windows-desktop-search-problem-solving/
    From: https://gist.github.com/arebee/1928da03047aee4167fabee0f501c72d
    .OUTPUTS
    By default one string per file found with full path.
    If the AsFSInfo switch is set, one System.IO.FileSystemInfo object per file found is returned.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false, ParameterSetName = "FullText")]
        [Parameter(Mandatory = $false)]
        [alias("Filter")]
        [string]$Pattern = "*.*",
        [Parameter(Mandatory = $false, ParameterSetName = "FullText")]
        [string]$Text = $null,
        [Parameter(Mandatory = $false)]
        [switch]$Recurse = $false,
        [Parameter(Mandatory = $false)]
        [switch]$AsFSInfo = $false
    )
    if ($Path -eq "")
    {
        $Path = $PWD;
    }

    $path = (Resolve-Path -Path $path).Path

    $pattern = $pattern -replace "\*", "%"
    $path = $path.Replace('\', '/')

    if ((Test-Path -Path Variable:fsSearchCon) -eq $false)
    {
        $global:fsSearchCon = New-Object -ComObject ADODB.Connection
        $global:fsSearchRs = New-Object -ComObject ADODB.Recordset
    }

    $fsSearchCon.Open("Provider=Search.CollatorDSO;Extended Properties='Application=Windows';")

    [string]$queryString = "SELECT System.ItemPathDisplay FROM SYSTEMINDEX WHERE System.FileName LIKE '" + $pattern + "' "
    if ([System.String]::IsNullOrEmpty($Text) -eq $false)
    {
        $queryString += "AND FREETEXT('" + $Text + "') "
    }

    if ($Recurse)
    {
        $queryString += "AND SCOPE='file:" + $path + "' ORDER BY System.ItemPathDisplay"
    }
    else
    {
        $queryString += "AND DIRECTORY='file:" + $path + "' ORDER BY System.ItemPathDisplay"
    }
    $fsSearchRs.Open($queryString, $fsSearchCon)
    # return
    While (-Not $fsSearchRs.EOF)
    {
        if ($AsFSInfo)
        {
            # Return a FileSystemInfo object
            [System.IO.FileSystemInfo]$(Get-Item -LiteralPath ($fsSearchRs.Fields.Item("System.ItemPathDisplay").Value) -Force)
        }
        else
        {
            $fsSearchRs.Fields.Item("System.ItemPathDisplay").Value
        }
        $fsSearchRs.MoveNext()
    }
    $fsSearchRs.Close()
    $fsSearchCon.Close()
}