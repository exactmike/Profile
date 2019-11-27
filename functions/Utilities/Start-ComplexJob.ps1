Function Start-ComplexJob
{
    <#
        .SYNOPSIS
        Helps Start Complex Background Jobs with many arguments and functions using Start-Job.
        .DESCRIPTION
        Helps Start Complex Background Jobs with many arguments and functions using Start-Job.
        The primary utility is to bring custom functions from the current session into the background job.
        A secondary utility is to formalize the input for creation complex background jobs by using a hashtable template and splatting.
        .PARAMETER  Name
        The name of the background job which will be created.  A string.
        .PARAMETER  JobFunctions
        The name[s] of any local functions which you wish to export to the background job for use in the background job script.
        The definition of any function listed here is exported as part of the script block to the background job.
        .EXAMPLE
        $StartComplexJobParams = @{
        jobfunctions = @(
                'Connect-WAAD'
            ,'Get-TimeStamp'
            ,'Write-Log'
            ,'Write-EndFunctionStatus'
            ,'Write-StartFunctionStatus'
            ,'Export-Data'
            ,'Get-MatchingAzureADUsersAndExport'
        )
        name = "MatchingAzureADUsersAndExport"
        arguments = @($SourceData,$SourceDataFolder,$LogPath,$ErrorLogPath,$OnlineCred)
        script = [scriptblock]{
            $PSModuleAutoloadingPreference = "None"
            $sourcedata = $args[0]
            $sourcedatafolder = $args[1]
            $logpath = $args[2]
            $errorlogpath = $args[3]
            $credential = $args[4]
            Connect-WAAD -MSOnlineCred $credential
            Get-MatchingAzureADUsersAndExport
        }
        }
        Start-ComplexJob @StartComplexJobParams
    #>
    [cmdletbinding()]
    param
    (
        [string]$Name
        ,
        [string[]]$JobFunctions
        ,
        [psobject[]]$Arguments
        ,
        [string]$Script
    )
    #build functions to initialize in job
    $JobFunctionsText = ''
    foreach ($Function in $JobFunctions)
    {
        $FunctionText = 'function ' + (Get-Command -Name $Function).Name + "{`r`n" + (Get-Command -Name $Function).Definition + "`r`n}`r`n"
        $JobFunctionsText = $JobFunctionsText + $FunctionText
    }
    $ExecutionScript = $JobFunctionsText + $Script
    #$initializationscript = [scriptblock]::Create($script)
    $ScriptBlock = [scriptblock]::Create($ExecutionScript)
    $StartJobParams = @{
        Name         = $Name
        ArgumentList = $Arguments
        ScriptBlock  = $ScriptBlock
    }
    #$startjobparams.initializationscript = $initializationscript
    Start-Job @StartJobParams

}
