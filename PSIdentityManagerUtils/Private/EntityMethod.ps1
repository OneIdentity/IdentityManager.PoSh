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