Function Group-Join
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject]
        ${InputObject},

        [Parameter(ParameterSetName='DefaultParameter', Position=0)]
        [System.Object[]]
        #Property by which to group objects
        ${Property},

        [Parameter(ParameterSetName='DefaultParameter', Mandatory)]
        [string[]]
        ${JoinProperty},

        [Parameter(ParameterSetName='DefaultParameter', Mandatory)]
        [string]
        ${JoinDelimeter}
    )
    begin
    {
        $collection = [System.Collections.Generic.List[psobject]]::new()
    }

    process
    {
        $collection.Add($InputObject)
    }

    end
    {
        $GroupedCollection = @($collection | Select-Object -Property * | Group-Object -Property $Property)
        $GroupedCollection.foreach({
                $group = $_
                switch ($group.count)
                {
                    1
                    {$group.group}
                    {$_ -ge 2}
                    {
                        $JPHash = [ordered]@{}
                        $JoinProperty.foreach({
                                $JPHash.$_ = @($group.group.$_ | Sort-Object -Unique) -join $JoinDelimeter
                            })
                        $JPHash.Keys.foreach({
                                $group.group[0].$_ = $JPHash.$_
                            })
                        $group.group[0]
                    }
                }
            })
    }
}
