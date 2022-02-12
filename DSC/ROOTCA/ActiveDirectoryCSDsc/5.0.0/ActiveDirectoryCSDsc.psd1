@{
    # Version number of this module.
    moduleVersion        = '5.0.0'

    # ID used to uniquely identify this module
    GUID                 = 'f8ddd7fc-c6d6-469e-8a80-c96efabe2fcc'

    # Author of this module
    Author               = 'DSC Community'

    # Company or vendor of this module
    CompanyName          = 'DSC Community'

    # Copyright statement for this module
    Copyright            = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'DSC resources for installing, uninstalling and configuring Certificate Services components in Windows Server.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'AdcsAuthorityInformationAccess',
        'AdcsCertificationAuthority',
        'AdcsCertificationAuthoritySettings',
        'AdcsEnrollmentPolicyWebService',
        'AdcsOnlineResponder',
        'AdcsWebEnrollment',
        'AdscTemplate'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResource', 'ActiveDirectory', 'CertificateServices')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/dsccommunity/ActiveDirectoryCSDsc/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/ActiveDirectoryCSDsc'

            # A URL to an icon representing this module.
            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [5.0.0] - 2020-06-20

### Changed

- Updated common function `Test-DscParameterState` to support ordered comparison
  of arrays by copying function and tests from `ComputerManagementDsc`.
- Added new resource AdcsAuthorityInformationAccess - see
  [Issue #101](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/101).
- BREAKING CHANGE: Deprecate AdcsOcspExtension. This has been superceeded by
  AdcsAuthorityInformationAccess.
- AdcsCertificateAuthoritySettings:
  - Correct types returned by `CRLPeriodUnits` and `AuditFilter` properties
    from Get-TargetResource.
- Updated module ownership to DSC Community.
- BREAKING CHANGE: Changed resource prefix from MSFT to DSC.
- Updated to use continuous delivery pattern using Azure DevOps - Fixes
  [Issue #105](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/105).
- Fixed build badge IDs - Fixes [Issue #108](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/108).
- Corrected MOF formatting of `DSC_AdcsAuthorityInformationAccess.schema.mof`
  to fix issue with auto documentation generation.
- Updated CI pipeline files.
- No longer run integration tests when running the build task `test`, e.g.
  `.\build.ps1 -Task test`. To manually run integration tests, run the
  following:
  ```powershell
  .\build.ps1 -Tasks test -PesterScript ''tests/Integration'' -CodeCoverageThreshold 0
  ```
- Removed unused files repository - Fixes [Issue #112](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/112).
- Change Azure DevOps Pipeline definition to include `source/*` - Fixes [Issue #114](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/114).
- Updated pipeline to use `latest` version of `ModuleBuilder` - Fixes [Issue #115](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/115).
- Merge `HISTORIC_CHANGELOG.md` into `CHANGELOG.md` - Fixes [Issue #115](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/115).
- Fixed build failures caused by changes in `ModuleBuilder` module v1.7.0
  by changing `CopyDirectories` to `CopyPaths` - Fixes [Issue #119](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/119).
- Updated to use the common module _DscResource.Common_ - Fixes [Issue #117](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/117).
- Pin `Pester` module to 4.10.1 because Pester 5.0 is missing code
  coverage - Fixes [Issue #118](https://github.com/dsccommunity/ActiveDirectoryCSDsc/issues/118).

### Added

- Added build task `Generate_Conceptual_Help` to generate conceptual help
  for the DSC resource.
- Added build task `Generate_Wiki_Content` to generate the wiki content
  that can be used to update the GitHub Wiki.

'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}







