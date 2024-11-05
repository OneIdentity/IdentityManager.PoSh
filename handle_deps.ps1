<#
This script is a simple helper to handle all operation with the needed product dependent DLLs.
#>

Param (
    [parameter(Mandatory = $false, HelpMessage = 'The operation mode to use.')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('collect','clean', IgnoreCase = $true)]
    [string] $OpMode = 'clean',
    [parameter(Mandatory = $false, HelpMessage = 'The source directory to use.')]
    [ValidateNotNullOrEmpty()]
    [string] $SrcDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$targetDir = $PSScriptRoot

$depFiles = @(
    'Newtonsoft.Json.dll',
    'NLog.dll',
    'QBM.AppServer.Client.dll',
    'QBM.AppServer.Interface.dll',
    'QBM.AppServer.JobProvider.Plugin.dll',
    'QER.AppServer.Plugin.dll',
    'QER.Customizer.dll',
    'QER.DB.Plugin.dll',
    'QER.Interfaces.dll',
    'ServiceStack.Client.dll',
    'ServiceStack.Common.dll',
    'ServiceStack.dll',
    'ServiceStack.Interfaces.dll',
    'ServiceStack.Text.dll',
    'System.Memory.dll',
    'System.Numerics.Vectors.dll',
    'System.Runtime.CompilerServices.Unsafe.dll',
    'VI.Base.dll',
    'VI.DB.dll'
)

$fallbackMarkerFiles = @(
    'NLog',
    'ServiceStack.Client',
    'ServiceStack',
    'ServiceStack.Interfaces',
    'ServiceStack.Text',
    'System.Memory',
    'System.Numerics.Vectors',
    'System.Runtime.CompilerServices.Unsafe',
    'Newtonsoft.Json'
)

function CollectDeps {
    param (
        [parameter(Mandatory = $true, HelpMessage = 'The source directory to use.')]
        [string] $SrcDir,
        [parameter(Mandatory = $true, HelpMessage = 'The target directory to use.')]
        [string] $TargetDir
    )

    Write-Output 'Start collection operation'
    Write-Output "[+] Source directory: $SrcDir"
    Write-Output "[+] Target directory: $TargetDir"

    Write-Output 'Getting file list...'
    $excludes = @(
        'database'
        'MDK'
        'autorun'
        'projects'
        'documentation'
    )
    $excludesRegex = $excludes -join '|'
    $allFiles = Get-ChildItem -Recurse -File -Path $SrcDir | Where-Object {
        $_.DirectoryName -notmatch $excludesRegex
    }

    Write-Output 'Copying files...'
    $failed = $False
    $depFiles | ForEach-Object {
        $searchFile = $_
        $file = $allFiles | Where-Object { $_.Name -EQ $searchFile } | Select-Object -First 1

        if ( $file ) {
            $exists = Test-Path $file.FullName
        }

        if ( $exists ) {
            Copy-Item -Path $file.FullName -Destination $TargetDir -Recurse
            Write-Output "[+] File or folder '$searchFile' copied successfully"
        } else {
            Write-Output "[!] File or folder '$searchFile' not found in (sub)folder '${SrcDir}'"
            $failed = $True
        }
    }

    Write-Output 'Creating fallback marker files...'
    $markerDir = Join-Path "$TargetDir" -ChildPath 'fallback'

    if ( -Not (Test-Path "$markerDir") ) {
        New-Item -Path "$markerDir" -ItemType Directory > $null
    }

    $fallbackMarkerFiles | ForEach-Object {
        $marker = Join-Path $markerDir -ChildPath "$_.use_default"
        Write-Output "[+] Create fallback marker for $_"
        Write-Output 'Use default' > $marker
    }

    if ( $failed ){
        Write-Output ''
        Write-Output 'WARNING: Found some errors. Thats means some files may not be copied'
        exit 1
    } else {
        Write-Output ''
        Write-Output '--> All files successfully copied <--'
    }
}

function Cleanup {
    param (
        [parameter(Mandatory = $true, HelpMessage = 'The target directory to clean.')]
        [string] $TargetDir
    )

    Write-Output 'Start cleanup operation'
    Write-Output "[+] Directory to clean: $TargetDir"

    $depFiles | ForEach-Object {
        $searchFile = $_
        if ( Test-Path "$searchFile" ) {
            Remove-Item -Path "$searchFile"
            Write-Output "[+] File or folder '$searchFile' removed"
        }
    }

    $markerDir = Join-Path "$TargetDir" -ChildPath 'fallback'
    if ( Test-Path "$markerDir" ) {
        Remove-Item -Path "$markerDir" -Recurse -Force
    }
}

switch ($OpMode.ToLowerInvariant()) {
    'collect' {CollectDeps -SrcDir "${SrcDir}" -TargetDir "${TargetDir}"; break}
    'clean' {Cleanup -TargetDir "${TargetDir}"; break}
    default {CollectDeps; break}
}