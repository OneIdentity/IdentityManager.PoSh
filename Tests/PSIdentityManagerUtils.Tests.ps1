$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psm1")
$ModuleName = Split-Path $ModuleRoot -Leaf

Describe "General project validation: $ModuleName" -Tag 'Compliance' {
    $scripts = Get-ChildItem $ProjectRoot -Include *.ps1,*.psm1,*.psd1 -Recurse

    $testCase = $scripts | Foreach-Object{@{file=$_}}
    It "Script <file> should be valid powershell" -TestCases $testCase {
        param($file)

        $file.fullname | Should -Exist

        $contents = Get-Content -Path $file.fullname -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It "Module '$ModuleName' can import cleanly" {
        $ProjectRoot = Resolve-Path "$PSScriptRoot\.."
        $ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psm1")
        $ModuleName = Split-Path $ModuleRoot -Leaf
        { Import-Module (Join-Path "$ModuleRoot" "$ModuleName.psm1") -force } | Should -Not -Throw
    }
}

Describe "$ModuleName ScriptAnalyzer" -Tag 'Compliance' {
    $PSScriptAnalyzerSettings = @{
        Severity    = @('Error', 'Warning')
        ExcludeRule = @('PSAvoidGlobalVars', 'PSUseShouldProcessForStateChangingFunctions', 'PSAvoidUsingInvokeExpression')
    }

    $ScriptAnalyzerErrors = @()
    $ScriptAnalyzerErrors += Invoke-ScriptAnalyzer -Path "$ModuleRoot\Private" @PSScriptAnalyzerSettings
    $ScriptAnalyzerErrors += Invoke-ScriptAnalyzer -Path "$ModuleRoot\Public" @PSScriptAnalyzerSettings

    $InternalFunctions = Get-ChildItem -Path "$ModuleRoot\Private" -Filter *.ps1 | Select-Object -ExpandProperty Name
    $ExportedFunctions = Get-ChildItem -Path "$ModuleRoot\Public" -Filter *.ps1 | Select-Object -ExpandProperty Name
    $AllFunctions = ($InternalFunctions + $ExportedFunctions) | Sort-Object
    $FunctionsWithErrors = $ScriptAnalyzerErrors.ScriptName | Sort-Object -Unique
    if ($ScriptAnalyzerErrors) {
        $testCase = $ScriptAnalyzerErrors | Foreach-Object {
            @{
                RuleName   = $_.RuleName
                ScriptName = $_.ScriptName
                Message    = $_.Message
                Severity   = $_.Severity
                Line       = $_.Line
            }
        }

        $FunctionsWithoutErrors = Compare-Object -ReferenceObject $AllFunctions -DifferenceObject $FunctionsWithErrors | Select-Object -ExpandProperty InputObject
        Context 'ScriptAnalyzer Testing' {
            It "Function <ScriptName> should not use <Message> on line <Line> (Rule: <RuleName>)" -TestCases $testCase {
                param(
                    $RuleName,
                    $ScriptName,
                    $Message,
                    $Severity,
                    $Line
                )
                $ScriptName | Should -BeNullOrEmpty
            }
        }
    } else {
        $FunctionsWithoutErrors = $AllFunctions
    }

    Context 'Successful ScriptAnalyzer Testing' {
        $testCase = $FunctionsWithoutErrors | Foreach-Object {
            @{
                ScriptName = $_
            }
        }

        It "Function <ScriptName> has no ScriptAnalyzer errors" -TestCases $testCase {
            param(
                $ScriptName
            )
            $ScriptName | Should -Not -BeNullOrEmpty
        }
    }
}