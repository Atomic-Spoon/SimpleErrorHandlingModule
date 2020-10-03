Function Invoke-LogfileRotate{
    <#
      .SYNOPSIS
      
        Performs log file roatation. Work with .log, .txt, and .zip files. 
  
      .DESCRIPTION
  
        Log roation Function, looks for any file in the defined path with ".txt" or ".log" and archives (zips) any files older than 21 days
        Any archive files are deleted after 60 days.

        These numbers (days) were chosen what would be suitble for most roles and changing there value won't break anything. 
        
        The idea is to stop any logging action taken by this module from eating all the disk space over time without too much editing.
      
      .PARAMETER LogFileRootFolder (Required)
       
        The path of log file root folder, required to find files to archive and delete.
      
      .EXAMPLE
      
        Invoke-LogFileRotate -LogFileRootFolder C:\Folder\AnotherFolder\Logs
    #>
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$LogFileRootFolder
    
    )  
      $filesToArchive = Get-ChildItem -Path "$LogFileRootFolder" -Recurse | Where-Object {$_.Extension -eq ".txt" -or $_.Extension -eq ".log" }
      $filesAgeByCreateDate = $filesToArchive | Where-Object CreationTime -lt (Get-Date).AddDays(-21)
      ForEach ($fileItem in $filesAgeByCreateDate){
        #Get the file name minus it's extension to use as the archive filename   
        $destFileName = $fileItem|Select-Object -ExpandProperty BaseName
        Compress-Archive -Path "$LogFileRootFolder\$fileItem" -DestinationPath "$LogFileRootFolder\$destFileName.zip"
        Remove-Item -Path "$LogFileRootFolder\$fileItem"
      }
      $archivedFilesLookup = Get-ChildItem -Path "$rootLogFilePath" -Recurse | Where-Object {$_.Extension -eq ".zip"}
      $archivedFilesAgeByCreateDate = $archivedFilesLookup | Where-Object CreationTime -lt (Get-Date).AddDays(-60)
      ForEach ($archivedFileAgeByCreateDate in $archivedFilesAgeByCreateDate){
        Remove-Item -Path "$LogFileRootFolder\$archivedFileAgeByCreateDate"
    }
  }
  Function Write-Logfile{
      <#
        .SYNOPSIS
          Performs log (or txt) file writes.
  
        .DESCRIPTION
          Writes to a .log file or .txt file, with the string value captured by the -LoggingTextString parameter
  
        .PARAMETER LogFilePath
  
          [Mandatory parameter] This value can be a hardcoded path (c:\folder1\folder2\file.log) or a varible set in script ($logFile), but it
          MUST PRECEDE the log file string/output.
  
        .PARAMETER loggingTextString
  
          [Mandatory parameter] The text or string output to append to the log file, the contents of a output, string or captured error message.
          
          Does not require -LoggingTextString to be present just the text within quotes ("text and stuff")
        
        .PARAMETER AddTimeStamp

          [Optional parameter] This switch tells the Write-Logfile function to add a Date Time stamp to the log file entry

          Outputs the result in the following format: dd-MM-yyyy HH:mm:ss

        .EXAMPLE

          The following shows how you can use Write-LogFile to log a script or module being started, and using -AddTimeStamp we can prefix the log entry with the date and time without making "Get-Date" plus formatting calls in the script.

          Write-Logfile -LogFilePath "$env:UserProfile\Documents\timestamp-test.txt" -LoggingTextString "Script started" -AddTimeStamp
      
      
      #>
      [CmdletBinding()]
      Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$LoggingTextString,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$LogFilePath,
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)][switch]$AddTimeStamp
      )
      Add-Content -Path $LogFilePath -Value "`n"
      If ($AddTimeStamp.IsPresent){
        $eventTimeStamp = $((Get-Date).tostring("dd-MM-yyyy HH:mm:ss"))
        Add-content -Path $LogFilePath -value "$eventTimeStamp $loggingTextString"
      } 
      Else 
      {
        Add-content -Path $LogFilePath -value $loggingTextString
      }
    }
Function Get-EventHandling{
  <#
    .SYNOPSIS

      Error\Event reporting and handling. Events are displayed in a more readable fashion. Optional calls to record events to a log file also exist 

    .DESCRIPTION

      Error reporting and handling. The function is called when a Try,Catch results in a exception.

      The function grabs the last error object from the PowerShell error stack (which is either $_ (the current item in the eror stack) or which is $Error[0] the newest addition to the error stack.
      
      NOTE: The last (newest) item of the PS error stack is $Error[0], the second to last error object is $Error[1], the next (third) is $Error[2] etc.

      Using PowerShells native "Try, Catch, Finally" functionality Get-EventHandling is called within the "Catch" statement (see examples):

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

      Get-EventHandling -logFilePath $logFilePath -$ErrorExceptionCatch $_.Exception -ErrorInvocationInfoCatch $_.InvocationInfo

      This will catch the last error in the error stack and write a readable error output to the screen and logfile, and then halt the script.

      Adding "-ExceptionAllowed" in the command will allow the script to continue if you feel the error is recoverable:
      
      Get-EventHandling -logFilePath $logFilePath -$ErrorExceptionCatch $_.Exception -ErrorInvocationInfoCatch $_.InvocationInfo -ExceptionAllowed

    .EXAMPLE

      The basic way to catch a script/module exception is to tell Get-EventHandling to catch the current error written to the PS error stack ($_):

      Try
      {
        Get-ADUser -justaFakeParam
      }
      Catch
      {
        Get-EventHandling -ErrorCatch $_
      }

    .EXAMPLE

      If you wish to add more parameters to use with Get-EventHandling you can "splat" your parameters as a hash-table and and call the hash-table whenever you invoke Get-EventHandling:

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
        Get-EventHandling @eventParameters
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
        Get-EventHandling -ErrorCatch $Error[0] -ExceptionAllowed
      } 
  #>
  Param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)][switch]$exceptionAllowed,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)][switch]$writeToLogFile,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]$LogFilePath,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]$ErrorCapture
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
  $errorExceptionType = $ErrorCapture.Exception.GetType().FullName 
  Write-Host "`nException Type: `n$errorExceptionType"
  $errorExceptionId = $ErrorCapture.Exception.ErrorId
  Write-Host "`nException ID: `n$errorExceptionId"
  $errorExceptionMsg = $ErrorCapture.Exception.Message
  $errorInvocationLineNumber= $ErrorCapture.InvocationInfo.ScriptLineNumber
  Write-Host "`nException Message: `n$errorExceptionMsg"
  Write-Host "`nException in script\command, within line $errorInvocationLineNumber"
  $errorInvocationFullScriptLine = $ErrorCapture.InvocationInfo.Line
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
    $errorCommandInfo = $ErrorCapture.InvocationInfo.MyCommand
    Write-Logfile -logFilePath $LogFilePath "`n$EventTimeStamp : $isItFatalDoc ENCOUNTERED"
    Write-Logfile -logFilePath $LogFilePath "*** $isItFatalDoc DETAILS ***"
    Write-Logfile -logFilePath $LogFilePath "Exception Message: `n$errorExceptionMsg"
    Write-Logfile -LogFilePath $LogFilePath "Exception Reason: `n$($ErrorCapture.CategoryInfo.Reason)"
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
Export-ModuleMember -Function 'Invoke-LogfileRotate'
Export-ModuleMember -Function 'Write-Logfile'
Export-ModuleMember -Function 'Get-EventHandling'
