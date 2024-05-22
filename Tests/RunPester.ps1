$config = New-PesterConfiguration
$config.Run.Path = '.'
$config.CodeCoverage.Enabled = $false
$config.CodeCoverage.OutputPath = 'IdentityManager.Posh.CodeCoverage.xml'
$config.CodeCoverage.Path = ".\PSIdentityManagerUtils\*\*.ps*1"
$config.CodeCoverage.CoveragePercentTarget = 65
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = 'IdentityManager.Posh.TestResult.xml'
$config.Output.Verbosity = 'Detailed'

Invoke-Pester -Configuration $config