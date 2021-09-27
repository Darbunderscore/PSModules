<#
EL-PS-Common.psm1  Copyright (C) 2021  Brad Eley (brad.eley@gmail.com)
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

## Begin Test-Admin function
# Checks if the script is running in elevated mode.
Function Test-Admin {
	$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
	$currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
## End Test-Admin function

## Begin Restart-ScriptElevated function
<# 	Restarts the script this function was called from with original parameters.
	Usage: 	1. Add a switch parameter to script named $elevated
			2. Add something like this check to script to see if it was already restarted but is still not elevated (uses Test-Admin function):
				If (!(Test-Admin) -and $elevated){
					Write-Error -Message "Could not elevate privleges. Please restart PowerShell in elevated mode before running this script." -ErrorId 99 -TargetObject $_ -ErrorAction Stop
				}
				Elseif (!(Test-Admin)){
					Write-Warning "Script ran with non-elevated privleges."
					Restart-ScriptElevated -ScriptArgs $PSBoundParameters -PSPath $PSCommandPath
					exit
				}
				Else { Write-Output "INFO: Running script in elevated mode." }
			3. Note in example - Call script with $PSBoundParameters & $PSCommandPath built-in variables
#>
Function Restart-ScriptElevated {
	Param(
		[Parameter(Mandatory)]
		$PSPath,	
		
		$ScriptArgs
	)

	Write-Output "INFO: Attempting script restart in elevated mode..."
	$AllParameters_String = "";
	ForEach ($Parameter in $ScriptArgs.GetEnumerator()){
		$Parameter_Key = $Parameter.Key;
		$Parameter_Value = $Parameter.Value;
		$Parameter_Value_Type = $Parameter_Value.GetType().Name;

		If ($Parameter_Value_Type -Eq "SwitchParameter"){
			$AllParameters_String += " -$Parameter_Key";
		} Else {
			$AllParameters_String += " -$Parameter_Key `"$Parameter_Value`"";
		}
	}

	$Arguments= @("-NoProfile","-NoExit","-File",$PSPath,"-elevated",$AllParameters_String)

	Start-Process PowerShell -Verb Runas -ArgumentList $Arguments
}
## End Restart-ScriptElevated fundtion

## Begin Write-ProgressHelper function
<#	Author: Adam Bertram <https://www.adamtheautomator.com/building-progress-bar-powershell-scripts/>
	Usage:	Add the following lines into your script:
				$script:steps = ([System.Management.Automation.PsParser]::Tokenize((gc "$PSScriptRoot\$($MyInvocation.MyCommand.Name)"), [ref]$null) | where { $_.Type -eq 'Command' -and $_.Content -eq 'Write-ProgressHelper' }).Count
				$stepCounter = 1
				$title = "<Your title here>"
			At various places in your script, add the following to update the progress bar:
				Write-ProgressHelper -Title $title -Message '<What your script is currently doing>' -StepNumber ($stepCounter++)
#>
Function Write-ProgressHelper {
	param (
	    [int]$StepNumber,
	    [string]$Message,
		[string]$Title
	)

	Write-Progress -Activity $Title -Status $Message -PercentComplete (($StepNumber / $steps) * 100)
}
## End Write-ProgressHelper function

## Begin Get-ScriptDirectory function
# The $PSScriptRoot automatic variable was not availabe in PowerShell v1 and only to modules in version 2.
function Get-ScriptDirectory {
    If (($PSVersionTable.PSVersion | Select-Object -ExpandProperty Major) -ge 3){ Return $PSScriptRoot }
	Else{
	$Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
	}
  }
## End Get-ScriptDirectory function