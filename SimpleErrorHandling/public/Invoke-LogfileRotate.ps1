Function Invoke-LogfileRotate{
    <#
      .SYNOPSIS
      
        Performs log file roatation. Work with .log, .txt, and .zip files. 
  
      .DESCRIPTION
  
        Log roation Function, looks for any file in the defined path with ".txt" or ".log" and archives (zips) any files older than 21 days
        Any archive files are deleted after 60 days.

        These numbers (days) were chosen what would be suitble for most roles and changing there value won't break anything. 
        
        The idea is to stop any logging action taken by this module from eating all the disk space over time without too much editing.
      
      .PARAMETER LogFileRootFolder 
       
        [Mandatory] The path of log file root folder, required to find files to archive and delete.
      
      .EXAMPLE
      
        Invoke-LogFileRotate -LogFileRootFolder C:\Folder\AnotherFolder\Logs

      .NOTES  
        File Name  : Invoke-LogfileRotate
        Authors    : Matt Gane
        Requires   : PowerShell version 5.0 or greater
        Version    : 1.0 - 8th July 2019: It rotates the files
        History    : 
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
  Export-ModuleMember -Function 'Invoke-LogfileRotate'