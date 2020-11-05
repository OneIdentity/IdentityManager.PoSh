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

# just for convenience to save typing
$noneToken = [System.Threading.CancellationToken]::None
$noneToken | Out-Null

# initialize global variables
$Global:imsessions = @{}
