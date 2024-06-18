$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psm1")
$ModuleName = Split-Path $ModuleRoot -Leaf
Import-Module (Join-Path "$ModuleRoot" "$ModuleName.psm1")

#$Global:connectionString = 'url=http://XXX/AppServer/;AcceptSelfSigned=true;AllowServerNameMismatch=true'
#$Global:factory = 'QBM.AppServer.Client.ServiceClientFactory'
$Global:factory = 'VI.DB.ViSqlFactory'
$Global:connectionString = 'Data Source=127.0.0.1,1433;Initial Catalog=DB;Integrated Security=False;User ID=sa;Password=***;Pooling=False'
$Global:ProductFilePath = 'D:\ClientTools'
$Global:authenticationString = 'Module=DialogUser;User=viadmin;Password=***'
$Global:modulesToSkip = 'RMB', 'RMS', 'RPS'
$Global:modulesToAdd = 'QER'

$Global:connectionString2 = 'Data Source=127.0.0.1,1433;Initial Catalog=DB2;Integrated Security=False;User ID=sa;Password=***;Pooling=False'
$Global:ProductFilePath2 = 'D:\ClientTools2'
$Global:authenticationString2 = 'Module=DialogUser;User=viadmin;Password=***'
