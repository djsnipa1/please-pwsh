using namespace System.Management.Automation.Host

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
    throw "This script requires PowerShell Core version 7 or higher."
}

Set-PSDebug -Strict
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Get-MistralApiKey {
    if ($env:PLEASE_MISTRAL_API_KEY) {
        return $env:PLEASE_MISTRAL_API_KEY
    }
    if ($env:MISTRAL_API_KEY) {
        return $env:MISTRAL_API_KEY
    }
    return $null
}

function Get-MistralModel {
    return "mistral-large-latest"
}

function Get-MistralBaseUrl {
    if ($env:PLEASE_MISTRAL_API_BASE) {
        return $env:PLEASE_MISTRAL_API_BASE
    }
    if ($env:MISTRAL_API_BASE) {
        return $env:MISTRAL_API_BASE
    }
    return "https://api.mistral.ai"
}

function Invoke-MistralRequest($Payload) {
    $Uri = "$(Get-MistralBaseUrl)/v1/chat/completions"

    $Headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $(Get-MistralApiKey)"
    }

    try {
        $Response = Invoke-RestMethod -Uri $Uri -Method Post -Headers $Headers -Body ($Payload | ConvertTo-Json)
    }
    catch {
        Write-Error "Received $($_.Exception.Response.ReasonPhrase): $($_.Exception.Response.Content | ConvertTo-Json)"
    }

    Return $Response.choices[0].message.content
}

function Please {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Alias("e")][switch]$Explain
    )

    Test-ApiKey

    if ($Explain) {
        $Explanation = Get-CommandExplanation $Prompt
        Write-Output "`u{261D} $Explanation"
        $Command = $Prompt
    }
    else {
        $Command = Get-PwshCommand $Prompt
        if ($Command.contains("I do not know")) {
            Write-Output $Command
            Return
        }
    }
    $Action = Show-Menu $Command
    Invoke-Action $Action
}

function Test-ApiKey {
    if ($null -eq $(Get-MistralApiKey)) {
        Write-Output "`u{1F50E} Api key missing. See https://help.mistral.ai/en/articles/4936850-where-do-i-find-my-secret-api-key"
        $Key = Read-Host "Please provide the api key"

        if ([string]::IsNullOrWhiteSpace($Key)) {
            throw "`u{1F937} Api key still missing. Aborting."
        }
        $env:MISTRAL_API_KEY = $Key
    }
}

function Get-PwshCommand([string]$Prompt) {
    $Role = "You translate the input given into PowerShell command. You may not use natural language, but only a PowerShell commands as answer. Do not use markdown. Do not quote the whole output. If you do not know the answer, answer only with 'I do not know'"

    $Payload = @{
        'model'    = Get-MistralModel
        'messages' = @(
            @{ 'role' = 'system'; 'content' = $Role },
            @{ 'role' = 'user'; 'content' = $Prompt }
        )
    }

    Return Invoke-MistralRequest $Payload
}

function Show-Menu($Command) {
    $Title = "`u{1F523} Command:`n   $Command"

    $Question = "`u{2753} What should I do?"

    $OptionAbort = [ChoiceDescription]::new('&Abort')
    $OptionCopy = [ChoiceDescription]::new('&Copy')
    $OptionInvoke = [ChoiceDescription]::new('&Invoke')
    $Options = [ChoiceDescription[]]($OptionAbort, $OptionCopy, $OptionInvoke)

    Return $Host.UI.PromptForChoice($Title, $Question, $Options, 0)
}

function Invoke-Action ($Action) {
    switch ($Action) {
        0 {
            Write-Output "`u{274C} Aborting"
        }
        1 {
            Write-Output "`u{00A9} Copying to clipboard"
            Set-Clipboard -Value $Command
        }
        2 {
            Write-Output "`u{25B6} Invoking command"
            Invoke-Expression $Command
        }
        Default {
            Write-Output "Invalid action"
        }
    }
}

function Get-CommandExplanation([string]$Command) {
    $Prompt = "Explain what the command $Command does. Don't be too verbose."

    $Payload = @{
        'max_tokens' = 100
        'model'      = Get-MistralModel
        'messages'   = @(
            @{ 'role' = 'user'; 'content' = $Prompt }
        )
    }

    Return Invoke-MistralRequest $Payload
}

Export-ModuleMember -Function "Please"
