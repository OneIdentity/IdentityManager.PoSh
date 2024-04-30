$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psm1")
$ModuleName = Split-Path $ModuleRoot -Leaf
Import-Module (Join-Path "$ModuleRoot" "$ModuleName.psm1")

#$Global:connectionString = 'url=http://XXX/AppServer/;AcceptSelfSigned=true;AllowServerNameMismatch=true'
#$Global:factory = 'QBM.AppServer.Client.ServiceClientFactory'
$Global:factory = 'VI.DB.ViSqlFactory'
$Global:connectionString = 'Data Source=127.0.0.1,10001;Initial Catalog=DB;Integrated Security=False;User ID=DB_Config;Password=***;Pooling=False'
$Global:ProductFilePath = 'D:\Modules\TST\Assemblies'
$Global:authenticationString = 'Module=DialogUser;User=cccadmin;Password=***'
$Global:modulesToSkip = 'RMB', 'RMS', 'RPS'
$Global:modulesToAdd = 'QER'

$Global:connectionString2 = 'Data Source=127.0.0.1,10001;Initial Catalog=DB;Integrated Security=False;User ID=DB_Config;Password=***;Pooling=False'
$Global:ProductFilePath2 = 'D:\Modules\TST\Assemblies'
$Global:authenticationString2 = 'Module=DialogUser;User=cccadmin;Password=***'