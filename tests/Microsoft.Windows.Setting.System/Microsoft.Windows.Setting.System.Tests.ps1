# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
using module Microsoft.Windows.Setting.System

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

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

Describe 'WindowsCapability' {

    $WindowsCapablityName = 'OpenSSH.Server~~~~0.0.1.0'
    BeforeAll {
        Mock -ModuleName Microsoft.Windows.Setting.System Add-WindowsCapability {} -Verifiable

        Mock -ModuleName Microsoft.Windows.Setting.System Remove-WindowsCapability {} -Verifiable
    }

    It 'Add WindowsCapability' {

        Mock -ModuleName Microsoft.Windows.Setting.System Get-WindowsCapability { return  @(  Name = $WindowsCapablityName, State = 'NotPresent') } -Verifiable -ParameterFilter {
            $Name -eq $WindowsCapablityName -and $Online -eq $true
        }

        $desiredDeveloperModeBehavior = [Ensure]::Present
        $desiredState = @{
            Ensure = $desiredDeveloperModeBehavior
            Name   = $WindowsCapablityName
        }

        Invoke-DscResource -Name WindowsCapability -ModuleName Microsoft.Windows.Setting.System -Method Set -Property $desiredState

        Assert-MockCalled -CommandName 'Add-WindowsCapability' -Exactly 1 -Scope It -ParameterFilter {
            $Name -eq $WindowsCapablityName -and $Online -eq $true
        } -Verifiable
        Assert-MockCalled -CommandName 'Get-WindowsCapability' -Exactly 1 -Scope It -ParameterFilter {
            $Name -eq $WindowsCapablityName -and $Online -eq $true
        } -Verifiable
    }

    It 'Remove WindowsCapability' {
        Mock -ModuleName Microsoft.Windows.Setting.System Get-WindowsCapability { return  @(  Name = $WindowsCapablityName, State = 'Installed') } -Verifiable -ParameterFilter {
            $Name -eq $WindowsCapablityName -and $Online -eq $true
        }

        $desiredDeveloperModeBehavior = [Ensure]::Absent
        $desiredState = @{
            Ensure = $desiredDeveloperModeBehavior
            Name   = $WindowsCapablityName
        }

        Invoke-DscResource -Name WindowsCapability -ModuleName Microsoft.Windows.Setting.System -Method Set -Property $desiredState

        Assert-MockCalled -CommandName 'Remove-WindowsCapability' -Exactly 1 -Scope It -ParameterFilter {
            $Name -eq $WindowsCapablityName -and $Online -eq $true
        } -Verifiable
        Assert-MockCalled -CommandName 'Get-WindowsCapability' -Exactly 1 -Scope It -ParameterFilter {
            $Name -eq $WindowsCapablityName -and $Online -eq $true
        } -Verifiable
    }
}

AfterAll {
    $env:TestRegistryPath = ''
}
