    Function Get-StrictMode {
        
<#
.SYNOPSIS
Gets the current 'StrictMode' setting. See Set-StrictMode for how to set this.

.DESCRIPTION
While my version is significantly different, this is based off of a function
written by someone else that I found here: http://powershell.cz/2013/02/25/get-strictmode/

I would like to thank the original author for his work.

Get-StrictMode will return either the effective 'StrictMode' setting, or the 'StrictMode'
setting for all scopes.

If Set-StrictMode has never been called in a scope, the function will return $null for that
scope. If it has been set (even if it was called to turn StrictMode off), the function will
return a [version] object for that scope.

.NOTES
When -ShowAllScopes has been passed, the properties of the objects might not be ordered
properly. If you're using PSv3 or higher, you can make the hash table where the properties
are defined [ordered], or you can use the [PSCustomObject] accelerator.

.EXAMPLE
# First, open a fresh PowerShell window and import the function.
PS> (Get-StrictMode) -eq $null
True

PS> Set-StrictMode -Version 2
PS> (Get-StrictMode) -eq $null
False

PS> Get-StrictMode

Major  Minor  Build  Revision
-----  -----  -----  --------
2      0      -1     -1


This example shows how the function behaves if Set-StrictMode has never been used, and then
what happens after it is used.

.EXAMPLE
# First, open a fresh PowerShell window and import the function.
PS> & { Set-StrictMode -Version 1; Get-StrictMode }

Major  Minor  Build  Revision
-----  -----  -----  --------
1      0      -1     -1


PS> & { Set-StrictMode -Version 1; Get-StrictMode -ShowAllScopes }

StrictModeVersion Scope
----------------- -----
1.0                   0
                      1

PS> Get-StrictMode
<no value returned>

In this example, a script block is executed that calls Set-StrictMode. Any commands in that
scope will have to adhere to the version 1 'StrictMode'. Calling Get-StrictMode inside the
scriptblock shows that the effective version is 1.0. Using the -ShowAllScopes switch shows
that the current scope (scope 0)  has a 'StrictMode' setting, but the parent scope (scope 1)
does not. After the script block has executed, you are back in the original global scope
where there is no 'StrictMode'.

.EXAMPLE
PS> & {
    Set-StrictMode -Version 2;
    & {
        Set-StrictMode -Version 1;
        & {
            Set-StrictMode -Off;
            & {
                Get-StrictMode -ShowAllScopes
            }
        }
    }
}

StrictModeVersion Scope
----------------- -----
                      0
0.0                   1
1.0                   2
2.0                   3
3.0                   4

This example uses more script blocks to demonstrate that the function can see the 'StrictMode'
in each scope. For this example, calling Get-StrictMode without the -ShowAllScopes switch
would show an effective 'StrictModeVersion' of 0.0 in scope 0 (scope 0 has nothing defined,
so it searches all parent scopes until it finds a scope where it has been set).

#>

    [CmdletBinding()]
    param(
        # By default, only the effective
        [switch] $ShowAllScopes
    )

    function Get-Field {
        # FULL HELP AVAILABLE HERE: http://gallery.technet.microsoft.com/scriptcenter/Get-Field-Get-Public-and-7140945e
        [CmdletBinding()]
        param (
            # Specifies the object whose fields are retrieved
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
            $InputObject,
            # Specifies the names of one or more field names. The * wildcard is allowed.
            # Get-Field gets only the fields that satisfy the requirements of at least one of the Name strings.
            [Parameter(Position=0)]
            [string[]] $Name = "*",
            # Gets only the value of the field(s)
            [switch] $ValueOnly
        )

        process {
            $Type = $InputObject.GetType()
            [string[]] $BindingFlags = "Public", "NonPublic", "Instance"

            $Type.GetFields($BindingFlags) | Where-Object {
                    foreach($CurrentName in $Name) {
                        if ($_.Name -like $CurrentName) {
                            return $true
                        }
                    }
                } | ForEach-Object {
                    $CurrentField = $_

                    $CurrentFieldValue = $Type.InvokeMember($CurrentField.Name, $BindingFlags + "GetField", $null, $InputObject, $null)
                    if ($ValueOnly) {
                        $CurrentFieldValue
                    }
                    else {
                        $ReturnProperties = @{}
                        foreach ($PropName in @('Name','IsPublic','IsPrivate')) {
                            $ReturnProperties.$PropName = $CurrentField.$PropName
                        }

                        $ReturnProperties.Value = $CurrentFieldValue
                        New-Object PSObject -Property $ReturnProperties
                    }
                }
        }
    }


    # First scope appears to be from Get-Field scope, so ignore it and just get the parent
    # Second scope should be from this function, so ignore it and get its parent.
    $CurrentScope = $ExecutionContext | Get-Field _context -ValueOnly |
        Get-Field _engineSessionState -ValueOnly |
        Get-Field currentScope -ValueOnly |
        Get-Field *Parent* -ValueOnly |
        Get-Field *Parent* -ValueOnly
    $Scope = 0 # Keeps track of the scope that's being examined

    # Walk through scopes (this will continue to loop until there is no parent
    while ($CurrentScope) {
        # Field names use wild cards since ISE uses '<[FieldNameHere]>k__BackingField'
        # and console just uses [FieldName]
        $StrictModeVersion = $CurrentScope | Get-Field *StrictModeVersion* -ValueOnly
        $CurrentScope = $CurrentScope | Get-Field *Parent* -ValueOnly

        if ($ShowAllScopes) {
            New-Object PSObject -Property @{
                Scope = $Scope++
                StrictModeVersion = $StrictModeVersion
            }
        }
        elseif ($StrictModeVersion) {
            # User doesn't want all scopes, they just want the effective
            # strict mode version. Return it here (which breaks out of the
            # loop)
            return $StrictModeVersion
        }
    }

    }
