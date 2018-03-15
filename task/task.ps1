[CmdletBinding()]
param()

# Docs used:
# https://www.visualstudio.com/en-us/docs/integrate/extensions/develop/build-task-schema
# https://github.com/Microsoft/vsts-task-lib/blob/master/powershell/Docs/README.md
# https://github.com/Microsoft/vsts-task-lib/blob/master/powershell/Docs/Consuming.md

# create extension; run this in the folder that contains vss-extension.json: tfx extension create
# upload here: http://aka.ms/vsmarketplace-manage
 
Trace-VstsEnteringInvocation $MyInvocation
try {
    # Required variables
    [string]$serverName = Get-VstsInput -Name servername -Require
    [string]$appPoolName = Get-VstsInput -Name apppoolname -Require
    [string]$userName = Get-VstsInput -Name username -Require
    [string]$password = Get-VstsInput -Name password -Require
    [string]$cpulimit = Get-VstsInput -Name cpulimit
    [string]$cpulimitaction = Get-VstsInput -Name cpulimitaction
    [string]$processmodelidletimeoutminutes = Get-VstsInput -Name processmodelidletimeoutminutes
    [bool]$processmodelloaduserprofile = Get-VstsInput -Name processmodelloaduserprofile -AsBool
    [string]$recyclingregulartimeinterval = Get-VstsInput -Name recyclingregulartimeinterval
    [string]$recyclingspecifictimes = Get-VstsInput -Name recyclingspecifictimes
    
    

    $script = {
        param (
            [string]$loc_apppoolname,
            [string]$loc_cpulimit,
            [string]$loc_cpulimitaction,
            [string]$loc_processmodelidletimeoutminutes,
            [bool]$loc_processmodelloaduserprofile,
            [string]$loc_recyclingregulartimeinterval,
            [string]$loc_recyclingspecifictimes
        )
        Import-Module WebAdministration
        [string]$appPoolPath = "IIS:\AppPools\$loc_appPoolName" 
        if (!(Test-Path -Path $appPoolPath))
        {
            Write-Error "The application pool '$loc_appPoolName' does not exist! Make sure it exists before running this task."
            return
        }
        else {
            Write-Output "Application pool '$loc_appPoolName' found"
        }

        $appPool = Get-Item -Path $appPoolPath
        Write-Output "Application pool state is '$($appPool.state)'"

        # CPU - Limit
        if (![string]::IsNullOrEmpty($loc_cpulimit))
        {
            [int]$cpulimitsetting = $null
            if (!([int]::TryParse($loc_cpulimit, [ref]$cpulimitsetting)))
            {
                Write-Error "The value provided for the setting 'CPU - Limit' must be numeric and between 0 and 100. The current value is $loc_cpulimit"
                return
            }
            if ($cpulimitsetting -lt 0 -or $cpulimitsetting -gt 100)
            {
                Write-Error "The value provided for the setting 'CPU - Limit' must be between 0 and 100. The current value is $loc_cpulimit"
                return
            }
            if ($appPool.cpu.limit -eq ($cpulimitsetting * 1000))
            {
                Write-Output "Setting 'CPU - Limit (percent)' is up to date (nothing changed)"
            }
            else {
                Write-Output "Setting 'CPU - Limit (percent)' to value $loc_cpulimit"
                $appPool.cpu.limit = $cpulimitsetting * 1000
            }
        }

        # CPU - Limit Action
        if (![string]::IsNullOrEmpty($loc_cpulimitaction))
        {
            if ($appPool.cpu.action -eq $loc_cpulimitaction)
            {
                Write-Output "Setting 'CPU - Limit Action' is up to date (nothing changed)"
            }
            else {
                Write-Output "Setting 'CPU - Limit Action' to value $loc_cpulimitaction"
                $appPool.cpu.action = $loc_cpulimitaction
            }
        }

        # Process Model - Idle Time-out (minutes)
        if (![string]::IsNullOrEmpty($loc_processmodelidletimeoutminutes))
        {
            [int]$processmodelidletimeoutminutessetting = $null
            if (!([int]::TryParse($loc_processmodelidletimeoutminutes, [ref]$processmodelidletimeoutminutessetting)))
            {
                Write-Error "The value provided for the setting 'Process Model - Idle Time-out (minutes)' must be numeric and greater than 0. The current value is $loc_processmodelidletimeoutminutes"
                return
            }
            if ($processmodelidletimeoutminutessetting -lt 0)
            {
                Write-Error "The value provided for the setting 'Process Model - Idle Time-out (minutes)' must be greater than 0. The current value is $loc_processmodelidletimeoutminutes"
                return
            }
            if ($appPool.processModel.idleTimeout.TotalMinutes -ne $loc_processmodelidletimeoutminutes)
            {
                Write-Output "Setting 'Process Model - Idle Time-out (minutes)' to value $loc_processmodelidletimeoutminutes"
                [int]$hrs = [math]::Floor($loc_processmodelidletimeoutminutes / 60)
                [int]$mins = $loc_processmodelidletimeoutminutes % 60
                $appPool.processModel.idleTimeout = [TimeSpan]"$($hrs):$($mins):00"
            }
            else {
                Write-Output "Setting 'Process Model - Idle Time-out (minutes)' is up to date (nothing changed)"
            }
        }

        # Process Model - Load User Profile
        if ($appPool.processModel.loadUserProfile -ne $loc_processmodelloaduserprofile)
        {
            Write-Output "Setting 'Process Model - Load User Profile' to value $loc_processmodelloaduserprofile"
            $appPool.processModel.loadUserProfile = $loc_processmodelloaduserprofile
        }
        else {
            Write-Output "Setting 'Process Model - Load User Profile' is up to date (nothing changed)"
        }

        # Recycling - Regular Time Interval (minutes)
        if (![string]::IsNullOrEmpty($loc_recyclingregulartimeinterval))
        {
            [int]$recyclingregulartimeintervalsetting = $null
            if (!([int]::TryParse($loc_recyclingregulartimeinterval, [ref]$recyclingregulartimeintervalsetting)))
            {
                Write-Error "The value provided for the setting 'Recycling - Regular Time Interval (minutes)' must be numeric and greater than 0. The current value is $loc_recyclingregulartimeinterval"
                return
            }
            if ($recyclingregulartimeintervalsetting -lt 0)
            {
                Write-Error "The value provided for the setting 'Recycling - Regular Time Interval (minutes)' must be greater than 0. The current value is $loc_recyclingregulartimeinterval"
                return
            }
            if ($appPool.recycling.periodicRestart.time.TotalMinutes -ne $loc_recyclingregulartimeinterval)
            {
                Write-Output "Setting 'Recycling - Regular Time Interval (minutes)' to value $loc_recyclingregulartimeinterval"
                [int]$hrs = [math]::Floor($loc_recyclingregulartimeinterval / 60)
                [int]$mins = $loc_recyclingregulartimeinterval % 60
                $appPool.recycling.periodicRestart.time = [TimeSpan]"$($hrs):$($mins):00"
            }
            else {
                Write-Output "Setting 'Recycling - Regular Time Interval (minutes)' is up to date (nothing changed)"
            }
        }

        # Save changes
        $appPool | Set-Item
        

        # Recycling - Specific Times
        if (!([string]::IsNullOrEmpty($loc_recyclingspecifictimes)))
        {
            $times = $loc_recyclingspecifictimes -split "\n"
            Remove-ItemProperty $appPoolPath -Name Recycling.periodicRestart.schedule
            foreach ($time in $times)
            {
                Write-Output "Processing input '$time'"
                if ([string]::IsNullOrEmpty($time))
                {
                    continue
                }
                $dt = 0
                if (!([datetime]::TryParse($time, [ref]$dt)))
                {
                    Write-Error "The format used in the value provided for the setting 'Recycling - Specific Times' ($time) is not valid. Use the notation HH:mm:ss"
                    return
                }
                [string]$fixedTime = $dt.ToString("HH:mm:ss")
                New-ItemProperty -Path $appPoolPath -Name Recycling.periodicRestart.schedule -Value @{value=$fixedTime}
                Write-Output "Scheduled recycle added at '$fixedTime'"
            }
        }
        else {
            Write-Output "'Recycling - Specific Times' is empty so removing any existing entries"
            Remove-ItemProperty $appPoolPath -Name Recycling.periodicRestart.schedule
        }
        
    }

    # Run script on remote instance
    Write-Output "Start making changes to IIS Application Pool '$appPoolName'"
    $pass = ConvertTo-SecureString -AsPlainText $password -Force
    $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $userName,$pass
    Invoke-Command -ComputerName $serverName -Credential $Cred -ScriptBlock $script -ArgumentList $appPoolName,$cpulimit,$cpulimitaction,$processmodelidletimeoutminutes,$processmodelloaduserprofile,$recyclingregulartimeinterval,$recyclingspecifictimes -Verbose
    Write-Output "Finished making changes to IIS Application Pool '$appPoolName'"
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
