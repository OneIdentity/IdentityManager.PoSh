<#!
.SYNOPSIS
Represents an entity method.

.DESCRIPTION
Holds method metadata for an Identity Manager entity, including type, name, and
display caption.

.EXAMPLE
[EntityMethod]::new('Object', 'SetActive', 'Set Active')
#>
class EntityMethod {
    [ValidateNotNullOrEmpty()]
    [string]$Type
    [ValidateNotNullOrEmpty()]
    [string]$Name
    [ValidateNotNullOrEmpty()]
    [string]$Display

    EntityMethod($Type, $Name, $Display) {
        $this.Type = $Type
        $this.Name = $Name
        $this.Display = $Display
     }

     [string]ToString(){
        return ('{0}|{1}' -f $this.Type, $this.Name)
      }
}