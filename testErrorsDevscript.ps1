Try {
    $SharepointSettings = Get-Content -Path "$($PSScriptRoot | Split-Path -Parent)\config\SharePointSettings.json" -ErrorAction Stop | ConvertFrom-Json
}
Catch {
    <#
        If this fails then the whole script won't work so halt the script with a "-FatalError"
    #>
    Invoke-ErrorHandling
}
$webLoginServer = "https://portal.office.com" #"http://projects.my.nemesis.com/PMO"
$webCredential = Get-Credential -UserName "Matt.Bane@my.nemesis.com" -Message "Enter your Office 365 credentials";
Try 
{
    Connect-SPOService -url $webLoginServer -Credential $webCredential -ErrorAction stop
    Fake-CmdletForTesting -name $fakeParam -ErrorAction stop
}
Catch 
{
    Invoke-ErrorHandling
}
$serverUserName = "MyNemesisDomain\mBane"
$onPremCredential = Get-Credential -UserName $serverUserName -Message "Enter your local AD domain credentials"
    <#
        Test credential value is valid by connecting to service. 
        Otherwise the parent/calling script will hit lots of sites very quickly with bad credentials lock out your\service account
    #>
    Try {
        Connect-Site -Url $SharepointSettings.Endpoints.ProjectServer -Username $onPremCredential.Username -Password $onPremCredential.Password -ErrorAction Stop
        Write-StatusMessage -SuccessMsg -MessageContent "Logged into Project Server (On-Prem)...."
    }
    Catch {
        Write-StatusMessage -FatalErrorMsg -MessageContent "Failed to log into Project Server (On-Prem)...."
        Invoke-ErrorHandling -FatalError 
    }
    <#
        Echo the value of $onPremCredential to be picked up by the parent scope in PowerShell (Note password is not viewable)
    #>