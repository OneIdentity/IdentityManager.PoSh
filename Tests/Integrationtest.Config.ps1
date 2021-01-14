$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psm1")
$ModuleName = Split-Path $ModuleRoot -Leaf
Import-Module (Join-Path "$ModuleRoot" "$ModuleName.psm1") -force

$Global:connectionString = 'url=http://localhost/AppServerAR814ALL/;AcceptSelfSigned=true;AllowServerNameMismatch=true'
$Global:factory = 'QBM.AppServer.Client.ServiceClientFactory'
$Global:authenticationString = 'Module=DialogUser;User=viadmin;Password=P@ssw0rd'
$Global:modulesToSkip = 'AAD','ACN','ADS','APC','ATT','CAP','CCC','CPL','CSM','DPR','EBS','EX0','EXH','GAP','HDS','LDP','NDO','O3E','O3S','PAG','POL','RMB','RMS','RPS','SAC','SAP','SBW','SHR','SP0','TSB','UCI','UNX'