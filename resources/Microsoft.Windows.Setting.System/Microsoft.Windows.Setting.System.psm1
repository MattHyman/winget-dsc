# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

enum Ensure {
    Absent
    Present
}

if ([string]::IsNullOrEmpty($env:TestRegistryPath)) {
    $global:AppModelUnlockRegistryKeyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock\'
} else {
    $global:AppModelUnlockRegistryKeyPath = $env:TestRegistryPath
}

[DSCResource()]
class DeveloperMode {
    # Key required. Do not set.
    [DscProperty(Key)]
    [string]$SID

    [DscProperty()]
    [Ensure] $Ensure = [Ensure]::Present

    hidden [string] $DeveloperModePropertyName = 'AllowDevelopmentWithoutDevLicense'

    [DeveloperMode] Get() {
        $exists = DoesRegistryKeyPropertyExist -Path $global:AppModelUnlockRegistryKeyPath -Name $this.DeveloperModePropertyName

        # If the registry key does not exist, we assume developer mode is not enabled.
        if (-not($exists)) {
            return @{
                Ensure = [Ensure]::Absent
            }
        }

        $registryValue = Get-ItemPropertyValue -Path $global:AppModelUnlockRegistryKeyPath -Name $this.DeveloperModePropertyName

        # 1 == enabled == Present // 0 == disabled == Absent
        return @{
            Ensure = $registryValue ? [Ensure]::Present : [Ensure]::Absent
        }
    }

    [bool] Test() {
        $currentState = $this.Get()
        return $currentState.Ensure -eq $this.Ensure
    }

    [void] Set() {
        # 1 == enabled == Present // 0 == disabled == Absent
        $value = ($this.Ensure -eq [Ensure]::Present) ? 1 : 0
        Set-ItemProperty -Path $global:AppModelUnlockRegistryKeyPath -Name $this.DeveloperModePropertyName -Value $value
    }
}

#region Functions
function DoesRegistryKeyPropertyExist {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    # Get-ItemProperty will return $null if the registry key property does not exist.
    $itemProperty = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    return $null -ne $itemProperty
}
#endregion Functions
