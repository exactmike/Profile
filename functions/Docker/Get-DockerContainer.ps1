#requires -version 5.1

Function Get-DockerContainer
{
    [cmdletbinding(DefaultParameterSetName = "name")]
    [alias("gdc")]
    [OutputType("Get-DockerContainer.myDockerContainer")]

    Param(
        [Parameter(Position = 0, HelpMessage = "Enter a docker container name. The default is all running containers.", ParameterSetName = "name")]
        [ValidateNotNullorEmpty()]
        [string[]]$Name,
        [Parameter(HelpMessage = "Get all containers, not just those that are running.", ParameterSetName = "all")]
        [switch]$All
    )

    Begin
    {
        Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"

        #define a class for my docker container objects
        Class myDockerContainer
        {

            [string]$ID
            [string]$Name
            [datetime]$Created
            [string]$State
            [Boolean]$IsRunning
            [datetime]$Started
            #define Finished as a generic object so it can be null or a datetime
            [object]$Finished
            [timespan]$Runtime
            [string]$Image
            [object[]]$Mount
            [string]$Platform
            [int]$Size
            [string]$Path

            #methods
            [timespan] GetRuntime([datetime]$Start, [datetime]$End)
            {
                return ($end - $start)
            }
            [string] GetImageName([string]$image)
            {
                $val = (docker image inspect ($image -split ":")[1] --format "{{json .RepoTags}}") -replace '\[|\]|"', ""
                return $val
            }
            [int] GetContainerSize()
            {

                $stat = Get-ChildItem $this.path -file -recurse | Measure-Object length -sum

                $sz = docker ps -asf "name=$($this.name)" --format "{{json .}}" | ConvertFrom-Json | Select-Object -expandproperty size
                [regex]$rx = "\d+"
                [int]$szbytes = $rx.match($sz).value
                if ($this.mount)
                {
                    [int]$mnt = ($this.mount |
                        ForEach-Object { Get-ChildItem -path $_.source -file -recurse } |
                        Measure-Object length -sum).sum
                }
                else
                {
                    $mnt = 0
                }

                $totalsz = $stat.sum + $szbytes + $mnt

                return $totalsz
            }
            #the constructor
            myDockerContainer ($Name)
            {
                #get the docker installation directory
                $dockpath = ((docker system info | Select-String "docker root dir") -split ": ")[1]
                $json = docker container inspect $Name | ConvertFrom-Json

                $this.Name = $Name.replace('"', '')
                $this.Created = $json.Created
                $this.ID = $json.ID
                $this.IsRunning = $json.state.Running
                #adjust date to localtime because PowerShell Core converts it differently than Windows PowerShell
                $this.Started = ($json.state.startedat -as [datetime]).toLocalTime()
                $this.Finished = if ($this.IsRunning) { $null } else { $json.state.finishedat -as [datetime] }
                $this.Runtime = if ($this.IsRunning) { $this.GetRuntime($this.started, (Get-Date) ) } else { $this.GetRuntime($this.started, $this.finished ) }
                $this.State = $json.state.status
                $this.image = $this.GetImageName($json.image)
                $this.platform = $json.platform
                $this.mount = $json.mounts
                $this.Path = Join-Path -path $dockpath -childpath "containers\$($this.ID)"
                $this.Size = $this.GetContainerSize()
            }
        } #close class

    } #begin
    Process
    {
        if ($all)
        {
            Write-Verbose "[PROCESS] Getting all containers"
            $names = docker container ls -a --no-trunc --format "{{json .Names}}"
        }
        elseif ($Name)
        {
            Write-Verbose "[PROCESS] Getting container $name"
            $names = $Name
        }
        else
        {
            Write-Verbose "[PROCESS] Getting running containers"
            $names = docker container ls --no-trunc --format "{{json .Names}}"
        }

        if ($names)
        {
            foreach ($name in $names)
            {
                Write-Verbose "[PROCESS] Processing $name"
                if (docker container ls -qaf Name=$name)
                {
                    [myDockerContainer]::new($name)
                }
                else
                {
                    Write-Warning "Failed to find a container named $name"
                }
            } #foreach $Name
        } #if $name
        else
        {
            Write-Warning "No containers found"
        }
    } #process
    End
    {
        Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"
    } #end
} #close function

#import a format file if found
# https://gist.github.com/jdhitsolutions/74e52f89471720fb29b7fbaed279e183
$fmt = "C:\scripts\mydockercontainer.format.ps1xml"
if (Test-Path -path $fmt)
{
    Update-FormatData $fmt
}

<#
sample usage
get-dockercontainer
get-dockercontainer | select *
get-dockercontainer -all | format-table -view stats
#>