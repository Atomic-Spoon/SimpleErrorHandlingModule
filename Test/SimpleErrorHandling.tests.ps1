<# Import local config #>
$LocalConfig = Get-Content -Path "$PSScriptRoot\SimpleErrorHandling.tests.config.json" | ConvertFrom-Json 
$GitHome= $LocalConfig.GitHome
Write-Output "`n`$GitHome = $GitHome"
<# Other Stuff #>
Import-Module "$GitHome\SimpleErrorHandlingModule\SimpleErrorHandling" -Force

Try {
    Get-ChildItem -FakeParameter "BobBobby" -ErrorAction Stop
}
Catch {
    Invoke-ErrorHandling
}

Try {
    Import-Module ATotallyFakeModule -ErrorAction Stop
}
Catch {
    Invoke-ErrorHandling -FatalError
}
