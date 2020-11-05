function Resolve-Exception {
    [CmdletBinding()]
    Param (
      [parameter(Mandatory = $true, HelpMessage = 'The exception object to handle')]
      [ValidateNotNull()]
      [Object] $ExceptionObject,
      [parameter(Mandatory = $false, HelpMessage = 'Toogle stacktrace output')]
      [switch] $HideStackTrace = $false
    )

    Begin {
    }

    Process
    {
      $st = ""
      $e = $ExceptionObject.Exception
      if ($null -ne (Get-Member -InputObject $ExceptionObject -Name "ScriptStackTrace")) {
        $st = $ExceptionObject.ScriptStackTrace
      }

      $msg = $e.Message
      while ($e.InnerException) {
        $e = $e.InnerException
        $msg += "`n" + $e.Message
        if ($null -ne (Get-Member -InputObject $e -Name "ScriptStackTrace")) {
          $st += "`n" + $e.ScriptStackTrace + "`n---"
        }
      }

      if (-not $HideStackTrace) {
        $msg += "`n---`n" + $st
      }
      Write-Error -Message $msg -ErrorAction Stop
    }

    End {
    }
}