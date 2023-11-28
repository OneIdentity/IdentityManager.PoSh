Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue' # or 'SilentlyContinue'

function Resolve-Exception {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The exception object to handle')]
    [ValidateNotNull()]
    [Object] $ExceptionObject,
    [parameter(Mandatory = $false, HelpMessage = 'Toogle stacktrace output')]
    [switch] $HideStackTrace = $false
  )

  Begin {
  }

  Process
  {
    $sst = ''
    $st = ''

    if (-Not ($ExceptionObject.PSObject.Properties.Name -contains 'Exception')) {
      # Do not proceed on any non Exception object

      Write-Warning -Message "No Exception object."
      return
    }

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

      $msg += "`n" + $e.Message
      if ($null -ne (Get-Member -InputObject $e -Name 'ScriptStackTrace')) {
        $sst += "`n" + $e.ScriptStackTrace + "`n---"
      }

      if ($null -ne (Get-Member -InputObject $e -Name 'StackTrace')) {
        $st += "`n" + $e.StackTrace + "`n---"
      }
    }

    if (-not ($HideStackTrace)) {
      $msg += "`n---[ScriptStackTrace]---`n" + $sst + "`n---[StackTrace]---`n" + $st
    }

    Write-Error -Message $msg -ErrorAction Stop
  }

  End {
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

  $FileToLoad = Join-Path "${BasePath}" "$File"

  if (-not (Test-Path "$FileToLoad" -PathType Leaf))
  {
      throw "[!] Can't find or access file ${FileToLoad}."
  }

  if (-not ([appdomain]::currentdomain.getassemblies() |Where-Object Location -Like ${FileToLoad})) {
      try {
          [System.Reflection.Assembly]::LoadFrom($FileToLoad) | Out-Null
          $clientVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FileToLoad).ProductVersion
          Write-Debug "[+] File ${File} loaded with version ${clientVersion} from ${BasePath}."
      } catch {
          Resolve-Exception -ExceptionObject $PSitem
      }
  }
}

function Add-IdentityManagerProductFile {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $false, Position = 0, HelpMessage = 'The base path to load files from.')]
      [string] $BasePath = $null
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
        Write-Error -Message "`n[!] Can't find any place with needed Identity Manager assemblies.`n"
      }
    }
  }

  Add-FileToAppDomain -BasePath $oneImBasePath -File $VIDB
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