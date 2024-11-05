#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $(Join-Path "$PSScriptRoot" -ChildPath 'Public' | Join-Path -ChildPath '*.ps1') -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $(Join-Path "$PSScriptRoot" -ChildPath 'Private' | Join-Path -ChildPath '*.ps1') -ErrorAction SilentlyContinue )

Foreach($import in @( $Public + $Private )) {
    try {
        . $import.fullname
    } catch {
        throw "Failed to import function $($import.fullname): $PSitem.Exception.Message"
    }
}

Export-ModuleMember -Function $Public.Basename