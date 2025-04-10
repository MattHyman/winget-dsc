# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
using module Microsoft.Windows.Setting.System

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$global:WindowsCapablityName = 'OpenSSH.Server~~~~0.0.1.0'

<#
.Synopsis
   Pester tests related to the Microsoft.Windows.Setting.System PowerShell module.
#>

BeforeAll {
    Install-Module -Name PSDesiredStateConfiguration -Force -SkipPublisherCheck
    Import-Module Microsoft.Windows.Setting.System

    # Create test registry path.
    New-Item -Path TestRegistry:\ -Name TestKey
    # Set-ItemProperty requires the PSDrive to be in the format 'HKCU:'.
    $env:TestRegistryPath = ((Get-Item -Path TestRegistry:\).Name).replace('HKEY_CURRENT_USER', 'HKCU:')
}

Describe 'List available DSC resources' {
    It 'Shows DSC Resources' {
        $expectedDSCResources = 'DeveloperMode', 'WindowsCapability'
        $availableDSCResources = (Get-DscResource -Module Microsoft.Windows.Setting.System).Name
        $availableDSCResources.Count | Should -Be $expectedDSCResources.Count
        $availableDSCResources | Where-Object { $expectedDSCResources -notcontains $_ } | Should -BeNullOrEmpty -ErrorAction Stop
    }
}

Describe 'DeveloperMode' {
    It 'Sets Enabled' {
        $desiredDeveloperModeBehavior = [Ensure]::Present
        $desiredState = @{ Ensure = $desiredDeveloperModeBehavior }

        Invoke-DscResource -Name DeveloperMode -ModuleName Microsoft.Windows.Setting.System -Method Set -Property $desiredState

        $finalState = Invoke-DscResource -Name DeveloperMode -ModuleName Microsoft.Windows.Setting.System -Method Get -Property @{}
        $finalState.Ensure | Should -Be $desiredDeveloperModeBehavior
    }

    It 'Sets Disabled' {
        $desiredDeveloperModeBehavior = [Ensure]::Absent
        $desiredState = @{ Ensure = $desiredDeveloperModeBehavior }

        Invoke-DscResource -Name DeveloperMode -ModuleName Microsoft.Windows.Setting.System -Method Set -Property $desiredState

        $finalState = Invoke-DscResource -Name DeveloperMode -ModuleName Microsoft.Windows.Setting.System -Method Get -Property @{}
        $finalState.Ensure | Should -Be $desiredDeveloperModeBehavior
    }
}

# InModuleScope ensures that all mocks are on the Microsoft.Windows.Setting.System module.
InModuleScope Microsoft.Windows.Setting.System {
    Describe 'WindowsCapability' {
        BeforeAll {
            Mock Dism\Add-WindowsCapability {} -Verifiable
            Mock Dism\Remove-WindowsCapability {} -Verifiable
        }

        It 'Add WindowsCapability' {
            Mock Dism\Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'NotPresent' } } -Verifiable

            $provider = [WindowsCapability]@{
                Ensure = [Ensure]::Present
                Name   = $global:WindowsCapablityName
            }

            $provider.Set()

            Assert-MockCalled Dism\Get-WindowsCapability -Exactly 1 -Scope It -ParameterFilter {
                $Name -eq $global:WindowsCapablityName -and $Online -eq $true
            }

            Assert-MockCalled Dism\Add-WindowsCapability -Exactly 1 -Scope It -ParameterFilter {
                $Name -eq $global:WindowsCapablityName -and $Online -eq $true
            }

        }

        It 'Remove WindowsCapability' {
            Mock Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'Installed' } } -Verifiable

            $provider = [WindowsCapability]@{
                Ensure = [Ensure]::Absent
                Name   = $global:WindowsCapablityName
            }

            $provider.Set()

            Assert-MockCalled Remove-WindowsCapability -Exactly 1 -Scope It -ParameterFilter {
                $Name -eq $global:WindowsCapablityName -and $Online -eq $true
            }
            Assert-MockCalled Get-WindowsCapability -Exactly 1 -Scope It -ParameterFilter {
                $Name -eq $global:WindowsCapablityName -and $Online -eq $true
            }
        }
    }
}

AfterAll {
    $env:TestRegistryPath = ''
}
