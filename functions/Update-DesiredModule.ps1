    Function Update-DesiredModule {
        
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Named')]
        [string[]]$Name
    )
    #how to handle this - use AvailableModuleInstallationStatus as input?

    }
