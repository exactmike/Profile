Function New-GenericList
{
    [CmdletBinding()]
    param(
        [parameter()]
        [string]$type
    )
    
    switch ($type)
    {
        string
        {
            $list = [System.Collections.Generic.List[string]]::new()
        }
        integer
        {
            $list = [System.Collections.Generic.List[integer]]::new()
        }
        byte
        {
            $list = [System.Collections.Generic.List[byte]]::new()
        }
        float
        {
            $list = [System.Collections.Generic.List[float]]::new()
        }
        double
        {
            $list = [System.Collections.Generic.List[double]]::new()
        }
        decimal
        {
            $list = [System.Collections.Generic.List[decimal]]::new()
        }
        hashtable
        {
            $list = [System.Collections.Generic.List[hashtable]]::new()
        }
        bool
        {
            $list = [System.Collections.Generic.List[bool]]::new()
        }
        default
        {
            $list = [System.Collections.Generic.List[psobject]]::new()
        }
    }
    
    # both of these output methods work to get the empty list to the caller
    # Write-Output is preferred by me since it clarifies that the generic list
    # is being sent and not a standard PowerShell array
    
    Write-output $list -NoEnumerate
    #,$list
}