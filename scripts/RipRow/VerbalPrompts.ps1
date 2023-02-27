$Movements = Import-JSON -FilePath $PSScriptRoot\Movements.json | Select-Object -ExpandProperty Movements
$Workouts = Import-JSON -FilePath $PSScriptRoot\Workouts.json | Select-Object -ExpandProperty Workouts
foreach ($w in $Workouts)
{
    foreach ($s in $w.Steps)
    {
        $substeps = $movements | Where-Object {$_.name -eq $s.name} | Select-Object -ExpandProperty Steps
        Add-Member -InputObject $s -MemberType NoteProperty -Name SubSteps -Value $substeps
    }
}

function Start-Workout
{
    [cmdletbinding()]
    param(
        $Identity
        ,
        [int]$initialdelayseconds = 5
    )
    $Workout = $Workouts | Where-Object Name -EQ $Identity
    if ($initialdelayseconds -ge 1)
    {
        Out-Speech -InputObject "Start $($Workout.name) in $initialdelayseconds seconds" -Volume 99 -SynchronousOutput
        New-Timer -Units Seconds -Length ($initialdelayseconds - 1) -ShowProgress -speech -Frequency 1
    }
    foreach ($s in $Workout.Steps)
    {
        Out-Speech -InputObject "Start $($s.Name) for $($s.Duration) $($s.DurationUnits)" -SynchronousOutput -Volume 99 -Rate 0
        New-Timer -Units $s.DurationUnits -Length $s.Duration -ShowProgress -Frequency 5 -speech
    }
    Out-Speech -InputObject "$($Workout.name) completed!" -Volume 99
}