function Convert-StringBoolToBool
{
    [CmdletBinding(DefaultParameterSetName = 'AllPropertiesOfObject')]
    param(
        [parameter(ValueFromPipeline, ParameterSetName = 'AllPropertiesOfObject')]
        [object]$Object
        ,
        [parameter(ParameterSetName = 'AllPropertiesOfObject')]
        [string[]]$IncludeProperty #use to include properties that might have an empty string. Sets them to $False.  Otherwise, this only converts string members with a TRUE or FALSE string value.
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

                    {[string]::IsNullOrEmpty($_) -and $sm -in $IncludeProperty}
                    {
                        $o.$sm = $false
                    }
                }
            }
        }
    }
}
