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
  Export-ModuleMember -Function 'Write-Logfile'