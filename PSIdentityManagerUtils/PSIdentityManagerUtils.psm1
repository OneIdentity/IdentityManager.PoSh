#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

Foreach($import in @( $Public + $Private )) {
    try {
        . $import.fullname
    } catch {
        throw "Failed to import function $($import.fullname): $PSitem.Exception.Message"
    }
}

Export-ModuleMember -Function $Public.Basename