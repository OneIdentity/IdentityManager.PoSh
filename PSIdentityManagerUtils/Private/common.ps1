Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$oneImBasePath = [io.path]::combine(${Env:ProgramFiles}, 'One Identity\One Identity Manager')

# Precheck if path exists. If not, we set it to the current working directory to hopefully find the needed DLLs relativ to that directory
if (-not (Test-Path $oneImBasePath -PathType Container))
{
  $oneImBasePath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

[System.Reflection.Assembly]::LoadFrom([io.path]::combine($oneImBasePath, 'VI.Base.dll')) | Out-Null
[System.Reflection.Assembly]::LoadFrom([io.path]::combine($oneImBasePath, 'VI.DB.dll')) | Out-Null

# just for convenience to save typing
$noneToken = [System.Threading.CancellationToken]::None

# initialize global variables
$Global:imsessions = @{}