Function Write-Logfile{
    <#
      .SYNOPSIS
        Performs log (or txt) file writes.

      .DESCRIPTION
        Writes to a .log file or .txt file, with the string values included with the -LoggingTextString parameter

      .PARAMETER LogFilePath

        [Mandatory] The path to the log file

      .PARAMETER loggingTextString

        [Mandatory] The text/content to append to the log file, the contents of a output, string or captured error message.
        
        Does not actually require -LoggingTextString to be present, if you just add the text within quotes ("text and stuff" it will write to the log file, if missing the cmdlet will pause and prompt for a text entry)
      
      .PARAMETER AddTimeStamp

        [Optional] If included a Date\Time stamp will append to the log file entry

        Outputs the result in the following format: dd-MM-yyyy HH:mm:ss

      .EXAMPLE

        The following shows how you can use Write-LogFile to log a script or module being started, and using -AddTimeStamp we can prefix the log entry with the date and time without making "Get-Date" plus formatting calls in the script.

        Write-Logfile -LogFilePath "$env:UserProfile\Documents\timestamp-test.txt" -LoggingTextString "Script started" -AddTimeStamp
    
      .NOTES  
        File Name  : WriteLogFile.ps1
        Authors    : Matt Gane
        Requires   : PowerShell version 5.0 or greater
        Version    : 1.1 - 28th Jan 2021: Parse current logged in user's credentials to web proxy
        History    : 
    
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