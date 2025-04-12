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

$global:WindowsCapablityName = 'OpenSSH.Server~~~~0.0.1.0'

$global:winCapPresentCommonProvider = [WindowsCapability]@{
    Ensure = [Ensure]::Present
    Name   = $global:WindowsCapablityName
}

$global:winCapAbsentCommonProvider = [WindowsCapability]@{
    Ensure = [Ensure]::Absent
    Name   = $global:WindowsCapablityName
}

# InModuleScope ensures that all mocks are on the Microsoft.Windows.Setting.System module.
InModuleScope Microsoft.Windows.Setting.System {
    Describe 'WindowsCapability' {

        BeforeAll {
            Mock Add-WindowsCapability {}
            Mock Remove-WindowsCapability {}
        }

        Context 'Get' {

            It 'WindowsCapability returns absent when not present with null name when capability does not exist' {
                Mock Get-WindowsCapability { return  @{  Name = ''; State = 'NotPresent' } }

                $nonexistantCapabilityName = 'nonexistantCapability'

                $getNonExistantCapabilityProvider = [WindowsCapability]@{
                    Ensure = [Ensure]::Present
                    Name   = $nonexistantCapabilityName
                }

                $getResourceResult = $getNonExistantCapabilityProvider.Get()
                $getResourceResult.Ensure | Should -Be 'Absent'
                $getResourceResult.Name | Should -Be $null

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $nonexistantCapabilityName -and $Online -eq $true
                }
            }

            It 'WindowsCapability returns absent when not present with name when capability exists' {
                Mock Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'NotPresent' } }

                $getResourceResult = $global:winCapPresentCommonProvider.Get()
                $getResourceResult.Ensure | Should -Be 'Absent'
                $getResourceResult.Name | Should -Be $global:WindowsCapablityName

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }
            }

            It 'WindowsCapability returns present when installed' {
                Mock Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'Installed' } }

                $getResourceResult = $global:winCapPresentCommonProvider.Get()
                $getResourceResult.Ensure | Should -Be 'Present'
                $getResourceResult.Name | Should -Be $global:WindowsCapablityName

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }
            }
        }

        Context 'Test' {

            It 'Test for presense should return false name when capability does not exist' {
                Mock Get-WindowsCapability { return  @{  Name = ''; State = 'NotPresent' } }

                $nonexistantCapabilityName = 'nonexistantCapability'

                $getNonExistantCapabilityProvider = [WindowsCapability]@{
                    Ensure = [Ensure]::Present
                    Name   = $nonexistantCapabilityName
                }

                $testResourceResult = $getNonExistantCapabilityProvider.Test()
                $testResourceResult | Should -BeFalse

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $nonexistantCapabilityName -and $Online -eq $true
                }
            }

            It 'Test for absense should return true name when capability does not exist' {
                Mock Get-WindowsCapability { return  @{  Name = ''; State = 'NotPresent' } }

                $nonexistantCapabilityName = 'nonexistantCapability'

                $getNonExistantCapabilityProvider = [WindowsCapability]@{
                    Ensure = [Ensure]::Absent
                    Name   = $nonexistantCapabilityName
                }

                $testResourceResult = $getNonExistantCapabilityProvider.Test()
                $testResourceResult | Should -BeTrue

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $nonexistantCapabilityName -and $Online -eq $true
                }
            }

            It 'Test for presense should return false capability exists but is not installed' {
                Mock Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'NotPresent' } }

                $testResourceResult = $global:winCapPresentCommonProvider.Test()
                $testResourceResult | Should -BeFalse

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }
            }

            It 'Test for presense should return true if capability exists and is installed' {
                Mock Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'Installed' } }

                $testResourceResult = $global:winCapPresentCommonProvider.Test()
                $testResourceResult | Should -BeTrue

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }
            }

            It 'Test for absense should return true if capability exists but is not installed' {
                Mock Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'NotPresent' } }

                $testResourceResult = $global:winCapAbsentCommonProvider.Test()
                $testResourceResult | Should -BeTrue

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }
            }

            It 'Test for absense should return false if capability exists and is installed' {
                Mock Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'Installed' } }

                $testResourceResult = $global:winCapAbsentCommonProvider.Test()
                $testResourceResult | Should -BeFalse

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }
            }
        }

        Context 'Set' {
            It 'Add WindowsCapability when not present' {
                Mock Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'NotPresent' } }

                $winCapPresentCommonProvider.Set()

                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }

                Should -Invoke Add-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }
            }

            It 'Remove WindowsCapability when present' {
                Mock Get-WindowsCapability { return  @{  Name = $global:WindowsCapablityName; State = 'Installed' } } -Verifiable

                $winCapAbsentCommonProvider.Set()

                Should -Invoke Remove-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }
                Should -Invoke Get-WindowsCapability -Times 1 -Exactly -ParameterFilter {
                    $Name -eq $global:WindowsCapablityName -and $Online -eq $true
                }
            }
        }

    }
}

AfterAll {
    $env:TestRegistryPath = ''
}
