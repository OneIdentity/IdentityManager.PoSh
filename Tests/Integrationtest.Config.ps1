$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psm1")
$ModuleName = Split-Path $ModuleRoot -Leaf
Import-Module (Join-Path "$ModuleRoot" "$ModuleName.psm1")

#$Global:connectionString = 'url=http://XXX/AppServer/;AcceptSelfSigned=true;AllowServerNameMismatch=true'
#$Global:factory = 'QBM.AppServer.Client.ServiceClientFactory'
$Global:factory = 'VI.DB.ViSqlFactory'
$Global:connectionString = 'Data Source=127.0.0.1,10001;Initial Catalog=DBFaker91;Integrated Security=False;User ID=DBFaker91_Config;Password=P@ssw0rd;Pooling=False'
$Global:ProductFilePath = 'D:\Auslieferungen\v91\v91-249319\Modules\TST\Assemblies'
$Global:authenticationString = 'Module=DialogUser;User=cccadmin;Password=P@ssw0rd'
$Global:modulesToSkip = 'RMB', 'RMS', 'RPS'
$Global:modulesToAdd = 'QER'

$Global:connectionString2 = 'Data Source=127.0.0.1,10001;Initial Catalog=DBFaker91;Integrated Security=False;User ID=DBFaker91_Config;Password=P@ssw0rd;Pooling=False'
$Global:ProductFilePath2 = 'D:\Auslieferungen\v91\v91-249319\Modules\TST\Assemblies'
$Global:authenticationString2 = 'Module=DialogUser;User=cccadmin;Password=P@ssw0rd'