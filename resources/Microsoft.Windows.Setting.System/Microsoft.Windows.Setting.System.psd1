# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
@{
    RootModule           = 'Microsoft.Windows.Setting.System.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = 'cae11fd0-bf38-420f-9986-39d46990ae9b'
    Author               = 'Microsoft Corporation'
    CompanyName          = 'Microsoft Corporation'
    Copyright            = '(c) Microsoft Corp. All rights reserved.'
    Description          = 'DSC Module for Windows System Settings'
    PowerShellVersion    = '7.2'
    DscResourcesToExport = @(
        'DeveloperMode',
        'WindowsCapability'
    )
    PrivateData          = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags       = @(
                'PSDscResource_DeveloperMode',
                'PSDscResource_WindowsCapability'
            )

            # Prerelease string of this module
            Prerelease = 'alpha'

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/microsoft/winget-dsc/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/microsoft/winget-dsc'
        }
    }
}
