Function Get-EmptyDirectory
{
    [cmdletbinding()]
    param(
        # Path to the parent directory to check for empty directory(ies)
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -PathType Container -Path $_})]
        [string[]]$Path
        ,
        # Use Recursion
        [Parameter()]
        [switch]
        $Recurse
    )

    begin
    {
        $Empty = [system.collections.generic.List[PSObject]]::new()
    }
    process
    {
        foreach ($p in $Path)
        {
            $gciParams = @{
                Path      = $p
                Recurse   = $Recurse
                Directory = $true
            }

            $Directories = Get-ChildItem @gciParams

            $Directories.where({
                    @($_.GetFileSystemInfos()).count -eq 0
                }).foreach({$Empty.Add($_)})
        }
    }
    end
    {
        if ($Empty.count -ge 1)
        {
            $Empty
        }
    }
}