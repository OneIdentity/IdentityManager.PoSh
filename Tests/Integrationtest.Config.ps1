$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psm1")
$ModuleName = Split-Path $ModuleRoot -Leaf
Import-Module (Join-Path "$ModuleRoot" "$ModuleName.psm1")

#$Global:connectionString = 'url=http://XXX/AppServer/;AcceptSelfSigned=true;AllowServerNameMismatch=true'
#$Global:factory = 'QBM.AppServer.Client.ServiceClientFactory'
$Global:factory = 'VI.DB.ViSqlFactory'
$Global:connectionString = 'Data Source=XXX;Initial Catalog=<DB>;Integrated Security=False;User ID=sa;Password=XXX;Pooling=False'
$Global:ProductFilePath = '...'
$Global:authenticationString = 'Module=DialogUser;User=cccadmin;Password=XXX'
$Global:modulesToSkip = 'RMB', 'RMS', 'RPS'
$Global:modulesToAdd = 'QER'

$Global:connectionString2 = 'Data Source=XXX;Initial Catalog=<DB>;Integrated Security=False;User ID=sa;Password=XXX;Pooling=False'
$Global:ProductFilePath2 = '...'
$Global:authenticationString2 = 'Module=DialogUser;User=cccadmin;Password=XXX'