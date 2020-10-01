Function Invoke-LogfileRotate{
    <#
      .SYNOPSIS
      
        Performs log roatation.
  
      .DESCRIPTION
  
        Log roation Function, looks for any file in the defined path with ".txt" or ".log" and archives (zips) any files older than 14 days
        Any archive files are deleted after 30 days.
  
    #>
    [CmdletBinding()]
    Param(
      [string]$LogFileFolderPath
    
    )  
      $filesToArchive = Get-ChildItem -Path "$LogFileFolderPath" -Recurse | Where-Object {$_.Extension -eq ".txt" -or $_.Extension -eq ".log" }
      $filesAgeByCreateDate = $filesToArchive | Where-Object CreationTime -lt (Get-Date).AddDays(-14)
      ForEach ($fileItem in $filesAgeByCreateDate){
        #Get the file name minus it's extension to use as the archive filename   
        $destFileName = $fileItem|Select-Object -ExpandProperty BaseName
        Compress-Archive -Path "$LogFileFolderPath\$fileItem" -DestinationPath "$LogFileFolderPath\$destFileName.zip"
        Remove-Item -Path "$LogFileFolderPath\$fileItem"
      }
      $archivedFilesLookup = Get-ChildItem -Path "$rootLogFilePath" -Recurse | Where-Object {$_.Extension -eq ".zip"}
      $archivedFilesAgeByCreateDate = $archivedFilesLookup | Where-Object CreationTime -lt (Get-Date).AddDays(-30)
      ForEach ($archivedFileAgeByCreateDate in $archivedFilesAgeByCreateDate){
        Remove-Item -Path "$LogFileFolderPath\$archivedFileAgeByCreateDate"
    }
  }
  Function Write-Logfile{
      <#
        .SYNOPSIS
          Performs log file writes.
  
        .DESCRIPTION
          Writes to log file
  
        .PARAMETER LogFilePath (Required)
  
          Mandatory parameter, this value can be a hardcoded path (c:\folder1\folder2\file.log) or a varible set in script ($logFile), but it
          MUST PRECEDE the log file string/output.
  
        .PARAMETER loggingTextString (Required)
  
          The text or string output to append to the log file, the contents of a output, string or captured error message.
          
          Does not require -LoggingTextString to be present just the text within quotes ("text and stuff")

        .PARAMETER WarningItem (Optional)

          Adds a warning header before adding the string to the log, this is for items which may not be a good result but are not a script error, 
          such as returning a null value or access was missing for the script to fully operate etc 
  
        .EXAMPLE
          -------------------------- EXAMPLE 1 --------------------------
          The following shows how you can use Write-LogFile log the start time of a script start, using the cmdlet Get-Date as part of the string.
  
          This will append to the file "file.log" with the string value with the time and date returned by Get-Date:
          i.e. "Script started 1/04/2020 10:41:43 PM"
  
          Write-LogFile -logFilePath c:\temp\logs\file.log "Script started $((Get-Date).tostring("yyyyMMdd-HHmmss"))"
        
        .EXAMPLE
          -------------------------- EXAMPLE 2 --------------------------
          The following shows how you can add a warning header to  log to easily find items that may be of concern:
          i.e.  "************** WARNING **************
                Warning: Get-Item value for $itemObject is empty or returned $null"

          If ([string]::IsNullOrEmpty($itemObject)){
            $loggingCustomWarning = "Warning: Get-Item value for `$itemObject is empty or returned `$null"
            Write-Logfile -logFilePath $logFilePath "$loggingCustomWarning" -WarningItem
      #>
      [CmdletBinding()]
      Param(
        [switch]$WarningItem,
        [string]$LoggingTextString,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$LogFilePath,
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$errorTimeStamp
      )
      If ($WarningItem.IsPresent) {
        Add-Content -Path $LogFilePath -Value "`r`n************** WARNING **************"
      }
      Add-Content -Path $LogFilePath -Value "`r`n"
      Add-content -Path $LogFilePath -value $loggingTextString
    }
Function Get-ErrorHandling{
  <#
    .SYNOPSIS

    .DESCRIPTION
      Error reporting and handling. The function is called when a Try,Catch results in a exception. 
      The function grabs the last error object from the PowerShell error stack (which is $Error[0],
      The second to last error object is $Error[1], the next (third) is $Error[2] etc.)

      Uses PowerShells native "Try, Catch, Finally" functionality:
        Try {
          Do Something
        } 
        Catch {
          Error Responce
        }
        Finally {
          Follow up action  
        }

      The basic (must be present items) command line to add into your scripts "Catch" statement is:

      Get-ErrorHandling -logFilePath $logFilePath -ErrorExceptionCatch $_.Exception -ErrorInvocationInfoCatch $_.InvocationInfo

      This will catch the last error in the error stack and write a readable error output to the screen and logfile, and then halt the script.

      Adding "-ExceptionAllowed" in the command will allow the script to continue if you feel the error is recoverable:
      
      Get-ErrorHandling -logFilePath $logFilePath -ErrorExceptionCatch $_.Exception -ErrorInvocationInfoCatch $_.InvocationInfo -ExceptionAllowed 

  #>
  Param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)][switch]$exceptionAllowed,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)][switch]$writeToLogFile,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]$LogFilePath,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]$errorStackInvocationInfo,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]$errorStackException
  )
  $isItFatalDoc = If ($exceptionAllowed.IsPresent)
  {
    "RECOVERABLE ERROR"
  } 
  ELSE 
  {
    "FATAL ERROR" 
  }
  Write-Host -ForegroundColor Red "`n** ENCOUNTERED $isItFatalDoc **`n"
  Write-Host "`n********** $isItFatalDoc DETAILS ********** "
  <# Perform error message formating #>
  $errorExceptionType = $errorStackException.GetType().FullName | Out-String
  $errorExceptionType = $errorExceptionType.Replace("`n","").Replace("`r","")
  Write-Host "`nException Type: `n$errorExceptionType"
  $errorExceptionMsg = $errorStackException | Out-String
  $errorExceptionMsg = $errorExceptionMsg.Replace("`n","").Replace("`r","")
  Write-Host "`nException Message: `n$errorExceptionMsg"
  $errorInvocationName = $errorStackInvocationInfo.MyCommand.Name | Out-String
  $errorInvocationName = $errorInvocationName.Replace("`n","").Replace("`r","")
  Write-Host "`nPowerShell Command Info:`n$errorInvocationName"
  <# Write Output to log file? #>
  If ($writeToLogFile.IsPresent)
  {
    If ([string]::IsNullOrEmpty($LogFilePath))
    {
      Write-Host -ForegroundColor Yellow "`n No log file defined, please use the `'-LogFilePath`' parameter to define a log file"
    }
    ELSE
    {
      
    }
  }
  <# Exit or continue? #>
  If ($exceptionAllowed -ne $true ) 
  {
    Write-Host -ForegroundColor Red "`n** HALTING SCRIPT  **"
    Write-Host "`n************** HALTING **************`n"
    # Do other this before we halt the script such as email log files etc
    BREAK
  }  
} 
  Function Write-HostReadableError {
    <#
      .SYNOPSIS
        Format and write the full error stack as a readble screen output

        `n = An new line in either wtrting a string to file or to screen
    #>
    Write-Host -ForegroundColor Yellow "`n********** $isItFatalDoc DETAILS ********** "
    Write-Host -ForegroundColor Yellow "`nException Type: `n"
    $SCRIPT:errorStackException.GetType().FullName
    Write-Host -ForegroundColor Yellow "`nException Message: `n"
    $SCRIPT:errorStackException
    Write-Host -ForegroundColor Yellow "`nPowerShell Command Info: `n"
    $SCRIPT:errorStackInvocationInfo.MyCommand
    #$scriptPosition = $SCRIPT:errorStackInvocationInfo.PositionMessage
    Write-Host -ForegroundColor Yellow "`nCode error at line and postion: `n"
    $SCRIPT:errorStackInvocationInfo.PositionMessage 
  }
  Function Write-LogFullStackError {
    <#
      .SYNOPSIS
        Formats and write the full error as a readble and formatted text item to add to a text or log file

        This involves some crazy formatting PS code due to the fact PowerShell formatted outputs such as table views
        will output horribly to a text or log file.

        `n = A new line in either wtrting a string to file or to screen
        `r = A new line in either wtrting a string to file or to screen on legacy text editors such as notepad.exe
    #>
    Write-Logfile -logFilePath $LogFilePath "`r`n********** $isItFatalDoc DETAILS ********** "
    $errorExceptionType = $SCRIPT:errorStackException.GetType().FullName | Out-String
    $errorExceptionType = $errorExceptionType.Replace("`n","").Replace("`r","")
    Write-Logfile -logFilePath $LogFilePath "`r`nException Type: `n$errorExceptionType"
    $errorExceptionMsg = $SCRIPT:errorStackException | Out-String
    $errorExceptionMsg = $errorExceptionMsg.Replace("`n","").Replace("`r","")
    Write-Logfile -logFilePath $LogFilePath "`r`nException Message: `n$errorExceptionMsg"
    $errorInvocationName = $SCRIPT:errorStackInvocationInfo.MyCommand.Name | Out-String
    $errorInvocationName = $errorInvocationName.Replace("`n","").Replace("`r","")
    Write-Logfile -logFilePath $$LogFilePath "`r`nPowerShell Command Info:`r`n$errorInvocationName"
    $major = $SCRIPT:errorStackInvocationInfo.MyCommand.Version.Major
    $minor = $SCRIPT:errorStackInvocationInfo.MyCommand.Version.Minor
    $build = $SCRIPT:errorStackInvocationInfo.MyCommand.Version.Build
    $cmdletVersion = "$major"+'.'+"$minor"+'.'+"$build"
    Write-Logfile -logFilePath $LogFilePath  "Version = $cmdletVersion"
    $powerShellSource = $SCRIPT:errorStackInvocationInfo.MyCommand.Source
    Write-Logfile -logFilePath $LogFilePath "Source: $powerShellSource"
    $errorInvocationPosition = $SCRIPT:errorStackInvocationInfo.PositionMessage | Out-String
    $errorInvocationPosition = $errorInvocationPosition 
    Write-Logfile -logFilePath $LogFilePath "`r`nCode error at line and postion: `r`n$errorInvocationPosition"
  }
Export-ModuleMember -Function 'Invoke-LogfileRotate'
Export-ModuleMember -Function 'Write-Logfile'
Export-ModuleMember -Function 'Get-ErrorHandling'
