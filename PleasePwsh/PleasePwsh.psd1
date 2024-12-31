@{
    RootModule        = 'PleasePwsh.psm1'
    ModuleVersion     = '0.2'
    GUID              = '578d6603-96c2-4343-a824-6392b60667c4'
    Author            = 'Chad Boyce'
    CompanyName       = 'boycedesigns'
    Copyright         = '2025 Chad Boyce. All rights reserved.'
    Description       = 'Translates a prompt into a PowerShell command using Mistral AI.'
    PrivateData       = @{
        PSData = @{
            Tags       = @('PowerShell', 'Mistral', 'AI')
            ProjectUri = 'https://github.com/djsnipa1/please-pwsh'
        }
    }
    PowerShellVersion = '7.0'
    FunctionsToExport = 'Please'
    AliasesToExport   = '*'
}
