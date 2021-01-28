
Function Invoke-ErrorHandling{
    <#
      .SYNOPSIS
  
        Error\Event reporting and handling. Events are displayed in a more readable fashion. Optional calls to record events to a log file also exist 
  
      .DESCRIPTION
  
        Error reporting and handling. The function is called when a Try,Catch results in a exception.
  
        The function grabs the last error object from the PowerShell error stack (which is either $_ (the current item in the eror stack) or which is $Error[0] the newest addition to the error stack.
        
        NOTE: The last (newest) item of the PS error stack is $Error[0], the second to last error object is $Error[1], the next (third) is $Error[2] etc.
  
        Using PowerShells native "Try, Catch, Finally" functionality Invoke-ErrorHandling is called within the "Catch" statement (see examples):
  
          Try {
            Do Something
          } 
          Catch {
            Error Responce
          }
          Finally {
            Follow up action  
          }
  
      .PARAMETER ErrorCatch
  
        [Mandatery] Needs to equal "$_" or "$Error[0]". The current\last item written to the error stack.
  
      .PARAMETER WriteToLogFile
  
        [Optional] Enables the passin g of the event\error to a designated log file
  
        NOTE: If no logfile path is defined (LogFilePath paraameter (see below)) the module will write to to $env:UserProfile\Documents\
  
        Invoke-ErrorHandling -logFilePath $logFilePath -$ErrorExceptionCatch $_.Exception -ErrorInvocationInfoCatch $_.InvocationInfo
  
        This will catch the last error in the error stack and write a readable error output to the screen and logfile, and then halt the script.
  
        Adding "-ExceptionAllowed" in the command will allow the script to continue if you feel the error is recoverable:
        
        Invoke-ErrorHandling -logFilePath $logFilePath -$ErrorExceptionCatch $_.Exception -ErrorInvocationInfoCatch $_.InvocationInfo -ExceptionAllowed
  
      .EXAMPLE
  
        The basic way to catch a script/module exception is to tell Invoke-ErrorHandling to catch the current error written to the PS error stack ($_):
  
        Try
        {
          Get-ADUser -justaFakeParam
        }
        Catch
        {
          Invoke-ErrorHandling -ErrorCatch $_
        }
  
      .EXAMPLE
  
        If you wish to add more parameters to use with Invoke-ErrorHandling you can "splat" your parameters as a hash-table and and call the hash-table whenever you invoke Invoke-ErrorHandling:
  
        #Splat those params!
        $eventParameters = @{
          ErrorCapture = "$error[0]"
          LogFilePath = "$env:UserProfile\Documents\myLogFile.log" 
        }
        Try
        {
          Get-ADUser -justaFakeParam
        }
        Catch
        {
          Invoke-ErrorHandling @eventParameters
        }
  
        NOTE: To catch the last error written to the PS error stack use you can use $error[0] or $_.
  
      .EXAMPLE
  
        Adding the "-ExceptionAllowed" parameter in the command will allow the script to continue should you feel the exception would be recoverable and rhe script can still complete it's run:
  
        Try
        {
          Get-ADUser -justaFakeParam
        }
        Catch
        {
          Invoke-ErrorHandling -ErrorCatch $Error[0] -ExceptionAllowed
        } 
    #>
    Param(
      [Parameter(Mandatory=$false,ValueFromPipeline=$true)][switch]$exceptionAllowed,
      [Parameter(Mandatory=$false,ValueFromPipeline=$true)][switch]$writeToLogFile,
      [Parameter(Mandatory=$false,ValueFromPipeline=$true)]$LogFilePath,
      [Parameter(Mandatory=$false,ValueFromPipeline=$true)]$ErrorCatch
    )
    $eventTimeStamp = $((Get-Date).tostring("dd-MM-yyyy HH:mm:ss"))
    $isItFatalDoc = If ($exceptionAllowed.IsPresent)
    {
      "RECOVERABLE ERROR"
    } 
    ELSE 
    {
      "FATAL ERROR" 
    }
    Write-Host -ForegroundColor Red "`n*** ENCOUNTERED $isItFatalDoc ***`n"
    Write-Host "`n### $isItFatalDoc DETAILS ###"
    $errorExceptionType = $ErrorCatch.Exception.GetType().FullName 
    Write-Host "`nException Type: `n$errorExceptionType"
    $errorExceptionId = $ErrorCatch.Exception.ErrorId
    Write-Host "`nException ID: `n$errorExceptionId"
    $errorExceptionMsg = $ErrorCatch.Exception.Message
    $errorInvocationLineNumber= $ErrorCatch.InvocationInfo.ScriptLineNumber
    Write-Host "`nException Message: `n$errorExceptionMsg"
    Write-Host "`nException in script\command, within line $errorInvocationLineNumber"
    $errorInvocationFullScriptLine = $ErrorCatch.InvocationInfo.Line
    Write-Host "`nFull line of script\code involved: `n$($errorInvocationFullScriptLine.trim())"
    <# Write Output to log file or not? #>
    If ($writeToLogFile.IsPresent)
    {
      If ([string]::IsNullOrEmpty($LogFilePath))
      {
        Write-Host -ForegroundColor Yellow "`n INFO: No log file path defined, using $env:UserProfile\Documents\EventHandlingOuput-yyyyyMMdd-HHmmss.txt"
        $fileDateStamp = $((Get-Date).tostring("yyyyMMdd-HHmmss"))
        $autoFileName = "EventHandlingOuput-$fileDateStamp.txt"
        $LogFilePath = "$env:UserProfile\Documents\$autoFileName"
      }
      $errorCommandInfo = $ErrorCatch.InvocationInfo.MyCommand
      Write-Logfile -logFilePath $LogFilePath "`n$EventTimeStamp : $isItFatalDoc ENCOUNTERED"
      Write-Logfile -logFilePath $LogFilePath "*** $isItFatalDoc DETAILS ***"
      Write-Logfile -logFilePath $LogFilePath "Exception Message: `n$errorExceptionMsg"
      Write-Logfile -LogFilePath $LogFilePath "Exception Reason: `n$($ErrorCatch.CategoryInfo.Reason)"
      Write-Logfile -LogFilePath $LogFilePath "Exception occured at line $errorInvocationLineNumber"
      Write-Logfile -LogFilePath $LogFilePath "Exception Type: `n$errorExceptionType"
      Write-Logfile -LogFilePath $LogFilePath "Exception ID: `n$errorExceptionId"
      Write-Logfile -logFilePath $LogFilePath "## PowerShell Module & Cmdlet Info ##"
      $errorInvocationName = $errorCommandInfo.Name
      Write-Logfile -logFilePath $LogFilePath "PowerShell cmdlet = $errorInvocationName"
      $major = $errorCommandInfo.Version.Major
      $minor = $errorCommandInfo.Version.Minor
      $build = $errorCommandInfo.Version.Build
      $cmdletVersion = "$major"+'.'+"$minor"+'.'+"$build"
      Write-Logfile -logFilePath $LogFilePath  "Version = $cmdletVersion"
      $powerShellSource = $errorCommandInfo.Source
      Write-Logfile -logFilePath $LogFilePath "Source PS Module = $powerShellSource"
      $errorCommandInfo
    }
    <# Exit or continue? #>
    If ($exceptionAllowed -ne $true ) 
    {
      Write-Host -ForegroundColor Red "`n*** HALTING SCRIPT  ***"
      Write-Host "`n## HALTING ##`n"
      # Do other this before we halt the script such as email log files etc
      BREAK
    } ELSE {
  
    }  
  } 
  Export-ModuleMember -Function 'Invoke-ErrorHandling'