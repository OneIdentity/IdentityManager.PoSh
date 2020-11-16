Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$VIDB = 'VI.DB.dll'
$ONEIMDIR = 'One Identity\One Identity Manager'

# Loading order for the needed assemblies:
# Try to figure out if there a files relative to our directory
# if not, try the default Identity Manager installation path

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

Write-Warning "Using '$oneImBasePath' as base path for loading needed Identity Manager assemblies."

[System.Reflection.Assembly]::LoadFrom([io.path]::combine($oneImBasePath, $VIDB)) | Out-Null

$Global:OnAssemblyResolve = [System.ResolveEventHandler] {
  param($s, $e)

  $s | Out-Null

  #Write-Warning "(1) ResolveEventHandler: Attempting FullName resolution of $($e.Name) from within the current appdomain." -InformationAction Continue
  foreach ($assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
    if ($assembly.FullName -eq $e.Name) {
      #Write-Warning "(1) Successful FullName resolution of $($e.Name) from within the current appdomain." -InformationAction Continue
      return $assembly
    }
  }

  #Write-Warning "  (2) ResolveEventHandler: Attempting name-only resolution of $($e.Name) from within the current appdomain." -InformationAction Continue
  foreach ($assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
    # Get just the name from the FullName (no version)
    $assemblyName = $assembly.FullName.Substring(0, $assembly.FullName.IndexOf(", "))
    if ($e.Name.StartsWith($($assemblyName + ","))) {
      #Write-Warning "  (2) Successful name-only (no version) resolution of $assemblyName from within the current appdomain." -InformationAction Continue
      return $assembly
    }
  }

  #Write-Warning "    (3) ResolveEventHandler: Attempting name-only resolution of $($e.Name) from within the base path $($oneImBasePath)." -InformationAction Continue
  $files = Get-ChildItem "$oneImBasePath"
  foreach ($file in $files) {
    $searchForFile = $($e.Name).Substring(0, $($e.Name).IndexOf(", "))

    if ($file.ToString().StartsWith($searchForFile)) {
      $assembly = [System.Reflection.Assembly]::LoadFrom([io.path]::combine($oneImBasePath, $file))
      #Write-Warning "    (3) Successful name-only (no version) resolution of $searchForFile from within the current base path $($oneImBasePath)." -InformationAction Continue
      return $assembly
    }
  }

  throw "[!] Unable to resolve $($e.Name)."
}

# just for convenience to save typing
$noneToken = [System.Threading.CancellationToken]::None
$noneToken | Out-Null

# initialize global variables
$Global:imsessions = @{}
