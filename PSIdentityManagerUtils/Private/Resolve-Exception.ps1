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
      $sst = ''
      $st = ''
      $e = $ExceptionObject.Exception
      if ($null -ne (Get-Member -InputObject $ExceptionObject -Name 'ScriptStackTrace')) {
        $sst = $ExceptionObject.ScriptStackTrace
      }
      if ($null -ne (Get-Member -InputObject $ExceptionObject -Name 'StackTrace')) {
        $st = $ExceptionObject.StackTrace
      }

      $msg = $e.Message
      while ($e.InnerException) {
        $e = $e.InnerException

        $msg += "`n" + $e.Message
        if ($null -ne (Get-Member -InputObject $e -Name 'ScriptStackTrace')) {
          $sst += "`n" + $e.ScriptStackTrace + "`n---"
        }

        if ($null -ne (Get-Member -InputObject $e -Name 'StackTrace')) {
          $st += "`n" + $e.StackTrace + "`n---"
        }
      }

      if (-not ($HideStackTrace)) {
        $msg += "`n---[ScriptStackTrace]---`n" + $sst + "`n---[StackTrace]---`n" + $st
      }
      Write-Error -Message $msg -ErrorAction Stop
    }

    End {
    }
}