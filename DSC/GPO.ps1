configuration GPO
{
   param
   (
        [String]$GPOName,
        [String]$GPOSASUrl,
        [String]$GPOGUID,
        [String]$BaseDN
    )

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile

    Node localhost
    {
        Registry SchUseStrongCrypto
        {
            Key                         = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        Registry SchUseStrongCrypto64
        {
            Key                         = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
        File MachineConfig
        {
            Type = 'Directory'
            DestinationPath = 'C:\MachineConfig'
            Ensure = "Present"
        }

        xRemoteFile GPOName
        {
            DestinationPath = "C:\MachineConfig\$GPOName.zip"
            Uri             = "$GPOSASUrl"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn =    "[File]MachineConfig"
        }

        Archive GPOName
        {
            Ensure = "Present"
            Path = "C:\MachineConfig\$GPOName.zip"
            Destination = "C:\MachineConfig\$GPOName"
            DependsOn = '[xRemoteFile]GPOName'
        }

        Script ApplyGPO
        {
            SetScript =
            {
                # Create GPO
                $gpo = Get-Gpo -Name "$using:GPOName" -ErrorAction 0
                IF ($gpo -eq $null) {New-Gpo -Name "$using:GPOName" | New-GPLink -Target "$using:BaseDN"}

                # Link GPO and set Order
                IF ($gpo -eq $null) {Set-GPLink -Name "$using:GPOName" -Target "$using:BaseDN" -Order 2}

                # Import GPO
                IF ($gpo -eq $null) {Import-GPO -BackupId "$using:GPOGUID" -TargetName "$using:GPOName" -path "C:\MachineConfig\$using:GPOName"}

            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Archive]GPOName'
        }
    }
}