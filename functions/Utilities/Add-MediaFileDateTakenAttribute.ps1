function Add-MediaFileDateTakenAttribute
{
    <#
    .SYNOPSIS
        Adds an attribute to the file(s) specified with the DateTaken information extracted from exif data in the file, if available.  If no DateTaken date is found DateTaken will be added with a NULL value.
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .NOTES
        Probably not supported in linux (uses ComObject Shell.Application)
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>


    [cmdletbinding()]
    param(
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [string[]]$FilePath
    )
    begin
    {
        $ShellExp = New-Object -ComObject Shell.Application
    }
    process
    {
        foreach ($i in $FilePath)
        {
            Write-Information -MessageData "Processing item $i"
            $item = Get-Item -Path $i
            Write-Information -MessageData "Processing item directory $($item.DirectoryName)"
            $itemdirectory = $ShellExp.NameSpace($item.DirectoryName)
            $itemfile = $itemdirectory.ParseName($item.name)
            $datetaken = $null
            Write-Information -MessageData "Processing item extention type $($item.Extension)"
            switch ($item.Extension)
            {
                '.mov'
                {
                    $datetakenstring = ($itemdirectory.GetDetailsOf($itemfile, 208) -replace "`u{200e}") -replace "`u{200f}"
                }
                '.avi'
                {
                    $datetakenstring = ($itemdirectory.GetDetailsOf($itemfile, 208) -replace "`u{200e}") -replace "`u{200f}"
                }
                '.jpg'
                {
                    $datetakenstring = ($itemdirectory.GetDetailsOf($itemfile, 12) -replace "`u{200e}") -replace "`u{200f}"
                }
            }

            if (-not [string]::IsNullOrEmpty($datetakenstring))
            {
                Write-Information -MessageData "Date Taken Value Identified: $datetakenstring"
                $dateTaken = $datetakenstring | Get-Date
            }
            Write-Information -MessageData "Adding DateTaken Attribute with value: $dateTaken"
            Add-Member -InputObject $item -NotePropertyName DateTaken -NotePropertyValue $Datetaken -PassThru
        }
    }
}