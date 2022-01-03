Function Get-RandomFileName
{
    [cmdletbinding(DefaultParameterSetName = 'WithExtension')]
    param (
        [parameter(Mandatory, ParameterSetName = 'SpecifiedExtension')]
        [string]$extension
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'WithExtension'
        {
            ([IO.Path]::GetRandomFileName())
        }
        'SpecifiedExtension'
        {
            "$([io.path]::GetFileNameWithoutExtension([IO.Path]::GetRandomFileName())).$extension"
        }
    }
}
