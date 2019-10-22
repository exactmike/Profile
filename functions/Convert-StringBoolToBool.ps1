function Convert-StringBoolToBool
{
    [CmdletBinding(DefaultParameterSetName = 'Object')]
    param(
        [parameter(ValueFromPipeline, ParameterSetName = 'Object')]
        [object]$Object
    )
    process
    {
        foreach ($o in $Object)
        {
            $stringMembers = @((Get-Member -InputObject $o -MemberType Properties).where( { $_.Definition -like 'string*' }).foreach( { $_.Name }))
            foreach ($sm in $stringMembers)
            {
                switch ($o.$sm)
                {
                    'TRUE'
                    { $o.$sm = $true }
                    'FALSE'
                    { $o.$sm = $false }
                }
            }
        }
    }
}
