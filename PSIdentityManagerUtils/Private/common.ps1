Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
#$DebugPreference = 'SilentlyContinue' # Valid values are 'SilentlyContinue' -> Don't show any debug messages; Continue -> Show debug messages.
# Output of debug messages can also be handled by setting '$global:DebugPreference = "Continue"'

function Get-SystemInfo {
  Begin {
  }

  Process {
    $platform = [System.Environment]::OSVersion.Platform
    $psversion = $PSVersionTable.PSVersion
    Write-Debug "System platform: $platform"
    Write-Debug "PowerShell version: $psversion"
  }

  End {
  }
}

Get-SystemInfo

function Resolve-Exception {
  [CmdletBinding()]
  Param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The exception object to handle')]
      [ValidateNotNull()]
      [Object] $ExceptionObject,
      [parameter(Mandatory = $false, HelpMessage = 'Toogle stacktrace output')]
      [switch] $HideStackTrace = $false,
      [parameter(Mandatory = $false, HelpMessage = 'The error action to use')]
      [String] $CustomErrorAction = 'Stop'
  )

  Begin {
  }

  Process {
      $sst = ''
      $st = ''
      $e = $ExceptionObject.Exception
      if ($null -ne (Get-Member -InputObject $ExceptionObject -Name 'ScriptStackTrace')) {
          $sst = $ExceptionObject.ScriptStackTrace
      }
      if ($null -ne (Get-Member -InputObject $ExceptionObject -Name 'StackTrace')) {
          $st = $ExceptionObject.StackTrace
      }

      $msg = $e.Message
      while ($e.InnerException) {
          $e = $e.InnerException

          $msg += $([Environment]::NewLine) + $e.Message
          if ($null -ne (Get-Member -InputObject $e -Name 'ScriptStackTrace')) {
              $sst += $([Environment]::NewLine) + $e.ScriptStackTrace + $([Environment]::NewLine) + "---"
          }

          if ($null -ne (Get-Member -InputObject $e -Name 'StackTrace')) {
              $st += $([Environment]::NewLine) + $e.StackTrace + $([Environment]::NewLine) + "---"
          }
      }

      if (-not ($HideStackTrace)) {
          $msg += $([Environment]::NewLine) + "---[ScriptStackTrace]---" + $([Environment]::NewLine) + $sst + $([Environment]::NewLine) + "---[StackTrace]---" + $([Environment]::NewLine) + $st
      }

      Write-Error -Message $msg -ErrorAction $CustomErrorAction
  }

  End {
  }
}

function Get-SqlFactoryFromConnectionString {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'Connectionstring to analyze')]
    [ValidateNotNullOrEmpty()]
    [String] $ConnectionString
  )

  if ($ConnectionString.ToLower().Contains('initial catalog')) {
    return 'VI.DB.ViSqlFactory'
  } elseif ( $ConnectionString.ToLower().Contains('url=')) {
    return 'QBM.AppServer.Client.ServiceClientFactory'
  } else {
    return 'VI.DB.Oracle.ViOracleFactory'
  }
}

function Add-FileToAppDomain {
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $true, HelpMessage = 'The base path to load files from.')]
    [ValidateNotNull()]
    [string] $BasePath,
    [parameter(Mandatory = $true, HelpMessage = 'The file to load into the AppDomain.')]
    [ValidateNotNull()]
    [string] $File
  )

  if (-not (Test-Path "$BasePath" -PathType Container))
  {
    throw "[!] Can't find or access folder ${BasePath}."
  }

  $FileToLoad = Join-Path "${BasePath}" -ChildPath "$File"

  if (-not (Test-Path "$FileToLoad" -PathType Leaf))
  {
    throw "[!] Can't find or access file ${FileToLoad}."
  }

  if (-not ([appdomain]::currentdomain.getassemblies() |Where-Object Location -Like ${FileToLoad})) {
    try {
      [System.Reflection.Assembly]::LoadFrom($FileToLoad) | Out-Null
      $clientVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FileToLoad)
      Write-Debug "[+] File ${File} loaded with version $($clientVersion.ProductVersion) from ${BasePath}."
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  } else {
    $AlreadyLoaderAssembly = $([appdomain]::currentdomain.getassemblies() |Where-Object Location -Like ${FileToLoad}).Location
    try {
      $clientVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($AlreadyLoaderAssembly)
      Write-Debug "[+] File ${File} already loaded with version $($clientVersion.ProductVersion) from ${BasePath}."
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  $clientVersion
}

function Add-IdentityManagerProductFile {
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $false, Position = 0, HelpMessage = 'The base path to load files from.')]
    [string] $BasePath = $null,
    [Parameter(Mandatory = $false, HelpMessage = 'If the switch is specified the trace mode for the Identity Manager will be activated. This means NLog will use log level trace.')]
    [switch] $TraceMode = $false
  )

  $VIDB = 'VI.DB.dll'
  $ONEIMDIR = 'One Identity\One Identity Manager'

  # Loading order for the needed assemblies:
  # Try to figure out if there are files relative to our directory
  # if not, try the default Identity Manager installation path

  if (-not ([string]::IsNullOrEmpty($BasePath))) {
    $oneImBasePath = $BasePath
  } else {
    $relativPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    if (Test-Path ([io.path]::combine($relativPath, $VIDB))) {
      $oneImBasePath = $relativPath
    } else {
      $oneImBasePath = [io.path]::combine(${Env:ProgramFiles}, $ONEIMDIR)

      if (-not (Test-Path $oneImBasePath -PathType Container))
      {
        Write-Error -Message "[!] Can't find any place with needed Identity Manager assemblies."
      }
    }
  }

  $ViDBVersion = Add-FileToAppDomain -BasePath $oneImBasePath -File $VIDB

  # Everything after 9.2 is not compatible with PowerShell 5
  if (5 -eq $PSVersionTable.PSVersion.Major -and $ViDBVersion.FileMajorPart -ge 9 -and $ViDBVersion.FileMinorPart -gt 2) {
    throw "[!] This version of Identity Manager ($($ViDBVersion.ProductVersion)) is not usable with PowerShell version $($PSVersionTable.PSVersion)."
  }

  # Everything below 9.3 is not compatible with PowerShell 7
  if (7 -eq $PSVersionTable.PSVersion.Major -and $ViDBVersion.FileMajorPart -le 9 -and $ViDBVersion.FileMinorPart -lt 3) {
    throw "[!] This version of Identity Manager ($($ViDBVersion.ProductVersion)) is not usable with PowerShell version $($PSVersionTable.PSVersion)."
  }

  # Support Identity Manager after 9.2 with version with PowerShell 7
  if (7 -eq $PSVersionTable.PSVersion.Major -and (($ViDBVersion.FileMajorPart -eq 9 -and $ViDBVersion.FileMinorPart -gt 2) -or ($ViDBVersion.FileMajorPart -eq 10 -and $ViDBVersion.FileMinorPart -ge 0))) {
    if ($IsWindows) {
      Add-FileToAppDomain -BasePath $(Join-Path $oneImBasePath -ChildPath 'net8.0') -File 'Microsoft.Data.SqlClient.dll' | Out-Null
    } elseif ($IsLinux) {
      Add-FileToAppDomain -BasePath $(Join-Path $(Join-Path $(Join-Path $(Join-Path $oneImBasePath -ChildPath 'runtimes') -ChildPath 'unix') -ChildPath 'lib') -ChildPath 'net8.0') -File 'Microsoft.Data.SqlClient.dll' | Out-Null
    }
  }

  if ($TraceMode) {
    Add-FileToAppDomain -BasePath $oneImBasePath -File 'NLog.dll' | Out-Null
  }

  $oneImBasePath
}

$Global:OnAssemblyResolve = [System.ResolveEventHandler] {
  param($s, $e)

  # Make PSScriptAnalyzer happy.
  $s |Out-Null

  Write-Debug "(1) ResolveEventHandler: Attempting FullName resolution of $($e.Name) from within the current appdomain." -InformationAction Continue
  foreach ($assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
    if ($assembly.FullName -eq $e.Name) {
      Write-Debug "(1) Successful FullName resolution of $($e.Name) from within the current appdomain." -InformationAction Continue
      return $assembly
    }
  }

  Write-Debug "  (2) ResolveEventHandler: Attempting name-only resolution of $($e.Name) from within the current appdomain." -InformationAction Continue
  foreach ($assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
    # Get just the name from the FullName (no version)
    $assemblyName = $assembly.FullName.Substring(0, $assembly.FullName.IndexOf(", "))
    if ($e.Name.StartsWith($($assemblyName + ","))) {
      Write-Debug "  (2) Successful name-only (no version) resolution of $assemblyName from within the current appdomain." -InformationAction Continue
      return $assembly
    }
  }

  Write-Debug "    (3) ResolveEventHandler: Attempting name-only resolution of $($e.Name) from within the base path $($oneImBasePath)." -InformationAction Continue
  $files = Get-ChildItem "$oneImBasePath"
  foreach ($file in $files) {
    $searchForFile = $($e.Name).Substring(0, $($e.Name).IndexOf(", ")) + '.dll'

    if ($file.ToString() -eq $searchForFile) {
      $assembly = [System.Reflection.Assembly]::LoadFrom([io.path]::combine($oneImBasePath, $file))
      Write-Debug "    (3) Successful name-only (no version) resolution of $searchForFile from within the current base path $($oneImBasePath)." -InformationAction Continue
      return $assembly
    }
  }

  throw "[!] Unable to resolve $($e.Name)."
}

function New-TemporaryDirectory {
  $parent = [System.IO.Path]::GetTempPath()
  do {
    $name = [System.IO.Path]::GetRandomFileName()
    $item = New-Item -Path $parent -Name $name -ItemType 'Directory' -ErrorAction SilentlyContinue
  } while (-Not $item)

  return $item.FullName
}

# just for convenience to save typing
$noneToken = [System.Threading.CancellationToken]::None
# Make PSScriptAnalyzer happy.
$noneToken | Out-Null

# initialize global variables
$Global:imsessions = @{}
$Global:newTypedWrapperProviderDone = $false
$Global:getTypedWrapperProviderDone = $false
$Global:removeTypedWrapperProviderDone = $false
$Global:setTypedWrapperProviderDone = $false