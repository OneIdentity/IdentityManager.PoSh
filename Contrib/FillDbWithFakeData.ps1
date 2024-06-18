Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue' # Valid values are 'SilentlyContinue' -> Don't show any debug messages; Continue -> Show debug messages.
$ProgressPreference = 'SilentlyContinue'

$ConectionString = 'Data Source=127.0.0.1,1433;Initial Catalog=DB;Integrated Security=False;User ID=sa;Password=***;Pooling=False'
$ProductFilePath = 'D:\ClientTools'
$AuthenticationString = 'Module=DialogUser;User=viadmin;Password=***'
$ModulesToAdd = 'QER'
Import-Module "$PSScriptRoot\..\PSIdentityManagerUtils\PSIdentityManagerUtils.psm1"

function Resolve-Exception {
  [CmdletBinding()]
  Param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The exception object to handle')]
      [ValidateNotNull()]
      [Object] $ExceptionObject,
      [parameter(Mandatory = $false, HelpMessage = 'Toogle stacktrace output')]
      [switch] $HideStackTrace = $false,
      [parameter(Mandatory = $false, HelpMessage = 'The error action to use')]
      [String] $CustomErrorAction = 'Stop'
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

          $msg += $([Environment]::NewLine) + $e.Message
          if ($null -ne (Get-Member -InputObject $e -Name 'ScriptStackTrace')) {
              $sst += $([Environment]::NewLine) + $e.ScriptStackTrace + $([Environment]::NewLine) + "---"
          }

          if ($null -ne (Get-Member -InputObject $e -Name 'StackTrace')) {
              $st += $([Environment]::NewLine) + $e.StackTrace + $([Environment]::NewLine) + "---"
          }
      }

      if (-not ($HideStackTrace)) {
          $msg += $([Environment]::NewLine) + "---[ScriptStackTrace]---" + $([Environment]::NewLine) + $sst + $([Environment]::NewLine) + "---[StackTrace]---" + $([Environment]::NewLine) + $st
      }

      Write-Error -Message $msg -ErrorAction $CustomErrorAction
  }

  End {
  }
}

$Session = New-IdentityManagerSession `
-ConnectionString $ConectionString `
-AuthenticationString $AuthenticationString `
-ProductFilePath $ProductFilePath `
-ModulesToAdd $ModulesToAdd

$StartTimeTotal = $(get-date)

Write-Debug "Session for $($Session.Display)"

# For easy Fakedata we use Bogus - get it from https://github.com/bchavez/Bogus
$FileToLoad = "$PSScriptRoot\Bogus.dll"
try {
    [System.Reflection.Assembly]::LoadFrom($FileToLoad) | Out-Null
    $clientVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FileToLoad).ProductVersion
    Write-Debug "[+] File ${FileToLoad} loaded with version ${clientVersion}"
} catch {
    Resolve-Exception -ExceptionObject $PSitem
}

# For easy QR Codes we use https://www.nuget.org/packages/QRCoder/1.4.3
# https://github.com/codebude/QRCoder/
$FileToLoad = "$PSScriptRoot\QRCoder.dll"
try {
    [System.Reflection.Assembly]::LoadFrom($FileToLoad) | Out-Null
    $clientVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FileToLoad).ProductVersion
    Write-Debug "[+] File ${FileToLoad} loaded with version ${clientVersion}"
} catch {
    Resolve-Exception -ExceptionObject $PSitem
}

$FakeData = [PSCustomObject]@{
  Identities = @()
  Departments = @()
  CostCenters = @()
  Locations = @()
  IdentityInDepartment = @()
  IdentityInCostCenter = @()
  IdentityInLocality = @()
  AccProducts = @()
  ProductOwners = @()
  PersonInAERoles = @()
  QERReuses = @()
  ITShopOrgHasQERReuse = @()
  AccProductGroup = ''
}

function New-Identities {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
        [ValidateNotNull()]
        [VI.DB.Entities.ISession] $Session,
        [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
        [ValidateNotNull()]
        [Bogus.Faker] $Faker,
        [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
        [int] $Quantity
    )

    Write-Debug "Creating $Quantity identity records in memory"

    $StartTime = $(get-date)
    for ($i = 1; $i -le $Quantity; $i++)
    {
        $fakeDate = [Bogus.DataSets.Date]::new()

        $FirstName = $Faker.Name.FirstName()
        $LastName = $Faker.Name.LastName()

        $qrGenerator = New-Object -TypeName QRCoder.QRCodeGenerator
        $TextToEncode = "$($Lastname), $($Firstname)"
        # Fehlerkorrekturlevel / ECCLevel: L (7%), M (15%), Q (25%) und H (30%)
        $qrCodeData = $qrGenerator.CreateQrCode($TextToEncode, 'M')
        $qrCode = New-Object -TypeName QRCoder.PngByteQRCode -ArgumentList ($qrCodeData)
        $byteArray = $qrCode.GetGraphic(5)

        $p = New-Person `
            -FirstName $FirstName `
            -LastName $LastName `
            -PersonalTitle $Faker.Name.JobTitle() `
            -Gender $Faker.Random.Int(1,2) `
            -Description $Faker.Name.JobType() `
            -BirthDate $([VI.Base.DbVal]::ToUniversalTime($fakeDate.Past(50, $(Get-Date).AddYears(-20)), $Session.TimeZone)) `
            -PersonnelNumber $Faker.Commerce.Ean13() `
            -Phone $Faker.Phone.PhoneNumber() `
            -PhoneMobile $Faker.Phone.PhoneNumber() `
            -Street $Faker.Address.StreetAddress() `
            -ZIPCode $Faker.Address.ZipCode() `
            -City $Faker.Address.City() `
            -Remarks $Faker.Lorem.Sentences() `
            -Room $Faker.Random.Number(1, 10000) `
            -Floor $Faker.Random.Number(1, 90) `
            -Building $Faker.Address.BuildingNumber() `
            -CustomProperty01 'Fakedata' `
            -JpegPhoto $byteArray `
            -Unsaved

        $p
    }

    $ElapsedTime = new-timespan $StartTime $(get-date)
    Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

function New-Departments {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Debug "Creating $Quantity department records in memory"

  $StartTime = $(get-date)
  for ($i = 1; $i -le $Quantity; $i++)
  {
    $Department = New-Department `
      -DepartmentName $($Faker.Address.City() + ' ' + $Faker.Commerce.Categories(1)) `
      -CustomProperty01 'Fakedata' `
      -ShortName $Faker.Commerce.Ean13() `
      -Description $Faker.Lorem.Sentences() `
      -Commentary $Faker.Lorem.Sentence(3, 5) `
      -Remarks $Faker.Lorem.Sentences() `
      -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_RulerContainer 'QER-AEROLE-STRUCTADMIN-RULER' `
      -UID_RulerContainerIT 'QER-AEROLE-STRUCTADMIN-RULERIT' `
      -UID_OrgAttestator 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR' `
      -Unsaved

    $Department
  }
  $ElapsedTime = new-timespan $StartTime $(get-date)
  Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

function New-CostCenters {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Debug "Creating $Quantity cost center records in memory"

  $StartTime = $(get-date)
  for ($i = 1; $i -le $Quantity; $i++)
  {
    $ProfitCenter = New-ProfitCenter `
      -AccountNumber $Faker.Commerce.Ean13() `
      -CustomProperty01 'Fakedata' `
      -ShortName $($Faker.Address.City() + ' ' + $Faker.Commerce.Categories(1)) `
      -Description $Faker.Lorem.Sentences() `
      -Commentary $Faker.Lorem.Sentence(3, 5) `
      -Remarks $Faker.Lorem.Sentences() `
      -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_RulerContainer 'QER-AEROLE-STRUCTADMIN-RULER' `
      -UID_RulerContainerIT 'QER-AEROLE-STRUCTADMIN-RULERIT' `
      -UID_OrgAttestator 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR' `
      -Unsaved

    $ProfitCenter
  }
  $ElapsedTime = new-timespan $StartTime $(get-date)
  Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

function New-Locations {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Debug "Creating $Quantity location records in memory"

  $StartTime = $(get-date)
  for ($i = 1; $i -le $Quantity; $i++)
  {
    $LocationName = $Faker.Address.OrdinalDirection() + ' ' + $Faker.Lorem.Word() + ' ' + $Faker.Commerce.Ean8()
    $Locality = New-Locality `
      -Ident_Locality $LocationName `
      -CustomProperty01 'Fakedata' `
      -ShortName $($Faker.Address.City() + ' ' + $Faker.Commerce.Categories(1)) `
      -LongName $($Faker.Address.City() + ' ' + $Faker.Commerce.Categories(1)) `
      -Street $Faker.Address.StreetAddress() `
      -ZIPCode $Faker.Address.ZipCode() `
      -City $Faker.Address.City() `
      -Building $Faker.Address.BuildingNumber() `
      -Room $Faker.Random.Number(1, 10000) `
      -Telephone $Faker.Phone.PhoneNumber() `
      -Description $Faker.Lorem.Sentences() `
      -Commentary $Faker.Lorem.Sentence(3, 5) `
      -Remarks $Faker.Lorem.Sentences() `
      -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_RulerContainer 'QER-AEROLE-STRUCTADMIN-RULER' `
      -UID_RulerContainerIT 'QER-AEROLE-STRUCTADMIN-RULERIT' `
      -UID_OrgAttestator 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR' `
      -Unsaved

    $Locality
  }
  $ElapsedTime = new-timespan $StartTime $(get-date)
  Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

function New-AccProducts {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Debug "Creating $Quantity AccProduct records in memory"

  $StartTime = $(get-date)
  for ($i = 0; $i -lt $Quantity; $i++)
  {
    $ProductName = $Faker.Commerce.Ean8() + '_' + $i
    $qrGenerator = New-Object -TypeName QRCoder.QRCodeGenerator
    $TextToEncode = "$ProductName"
    # Fehlerkorrekturlevel / ECCLevel: L (7%), M (15%), Q (25%) und H (30%)
    $qrCodeData = $qrGenerator.CreateQrCode($TextToEncode, 'M')
    $qrCode = New-Object -TypeName QRCoder.PngByteQRCode -ArgumentList ($qrCodeData)
    $byteArray = $qrCode.GetGraphic(5)
    
    $AccProduct = New-AccProduct -Ident_AccProduct $ProductName `
      -Description $Faker.Lorem.Sentence(3, 5) `
      -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
      -ArticleCode $ProductName `
      -IsCopyOnShopChange 1 `
      -CustomProperty01 'Fakedata' `
      -JPegPhoto $byteArray `
      -Unsaved

    $AccProduct
  }
  $ElapsedTime = new-timespan $StartTime $(get-date)
  Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

function New-AccProductGroups {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Debug "Creating AccProductGroup record in memory"

  $StartTime = $(get-date)

  $ProductName = 'FakeShop products'
  $qrGenerator = New-Object -TypeName QRCoder.QRCodeGenerator
  $TextToEncode = "$ProductName"
  # Fehlerkorrekturlevel / ECCLevel: L (7%), M (15%), Q (25%) und H (30%)
  $qrCodeData = $qrGenerator.CreateQrCode($TextToEncode, 'M')
  $qrCode = New-Object -TypeName QRCoder.PngByteQRCode -ArgumentList ($qrCodeData)
  $byteArray = $qrCode.GetGraphic(5)
  
  $AccProductGroup = New-AccProductGroup -Ident_AccProductGroup $ProductName `
    -Description $Faker.Lorem.Sentence(3, 5) `
    -Remarks $Faker.Lorem.Sentences() `
    -CustomProperty01 'Fakedata' `
    -JPegPhoto $byteArray `
    -Unsaved

  $AccProductGroup

  $ElapsedTime = new-timespan $StartTime $(get-date)
  Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

function New-ProductOwners {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Debug "Creating $Quantity ProductOwner records in memory"
  $StartTime = $(get-date)
  for ($i = 0; $i -lt $Quantity; $i++)
  {
    $ProductOwner = New-AERole -Ident_AERole $FakeData.AccProducts[$i].Ident_AccProduct `
      -UID_OrgRoot 'QER-V-AERole' `
      -Description $Faker.Lorem.Sentence(3, 5) `
      -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
      -UID_Department $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department) `
      -UID_Locality $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality) `
      -UID_ParentAERole 'QER-AEROLE-ITSHOPADMIN-OWNER' `
      -Commentary $Faker.Lorem.Sentence(3, 5) `
      -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -CustomProperty01 'Fakedata' `
      -Unsaved

    $ProductOwner
  }
  $ElapsedTime = new-timespan $StartTime $(get-date)
  Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

function New-QERReuses {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Debug "Creating $Quantity QERReuse records in memory"

  $StartTime = $(get-date)
  for ($i = 0; $i -lt $Quantity; $i++)
  {
   
    $QERReuse = New-QERReuse -Ident_QERReuse $FakeData.AccProducts[$i].Ident_AccProduct `
      -Description $Faker.Lorem.Sentence(3, 5) `
      -IsForITShop 1 `
      -IsITShopOnly 1 `
      -UID_AccProduct $FakeData.AccProducts[$i].UID_AccProduct `
      -CustomProperty01 'Fakedata' `
      -Unsaved

    $QERReuse
  }
  $ElapsedTime = new-timespan $StartTime $(get-date)
  Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

function New-ITShopOrgHasQERReuses {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The UID_ITShopOrg Shelf for the assignment')]
      [string] $UID_ITShopOrg
  )

  Write-Debug "Creating $Quantity QERReuse records in memory"

  $StartTime = $(get-date)
  for ($i = 0; $i -lt $Quantity; $i++)
  {
   
    $ITShopOrgHasQERReuse = New-ITShopOrgHasQERReuse -UID_QERReuse $FakeData.QERReuses[$i].UID_QERReuse `
      -UID_ITShopOrg $UID_ITShopOrg `
      -Unsaved

    $ITShopOrgHasQERReuse
  }
  $ElapsedTime = new-timespan $StartTime $(get-date)
  Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

function New-PersonInAERoles  {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Debug "Creating $Quantity PersonInAERole records for every AERole in memory"

  $StartTime = $(get-date)
  for ($i = 0; $i -lt $FakeData.ProductOwners.Count; $i++)
  {
    $UniquePersonInAERoles = @{}

    for ($j = 0; $j -lt $Quantity; $j++)
    {
      $RandomPerson = $FakeData.Identities | Get-Random
      $PersonInAERole = New-PersonInAERole -UID_AERole $FakeData.ProductOwners[$i].UID_AERole `
        -UID_Person $RandomPerson.UID_Person `
        -Unsaved

      $key = $PersonInAERole.UID_Person + '|' + $PersonInAERole.UID_AERole
      if (-not $UniquePersonInAERoles.ContainsKey($key)) {
        $UniquePersonInAERoles.Add($key, $key)
        $PersonInAERole
      } else {
        $j--
      }
    }

    $UniquePersonInAERoles.Clear()
  }
  $ElapsedTime = new-timespan $StartTime $(get-date)
  Write-Debug "Done in $($elapsedTime.TotalSeconds) seconds"
}

$Faker = [Bogus.Faker]::new('en')
$uow = New-UnitOfWork -Session $Session

# Create Identities
$FakeData.Identities = New-Identities -Session $Session -Faker $Faker -Quantity 100

# Create Departments
$FakeData.Departments = New-Departments -Session $Session -Faker $Faker -Quantity 20 -FakeData $FakeData

# Create cost centers
$FakeData.CostCenters = New-CostCenters -Session $Session -Faker $Faker -Quantity 20 -FakeData $FakeData

# Create locations
$FakeData.Locations = New-Locations -Session $Session -Faker $Faker -Quantity 20 -FakeData $FakeData

# Wire Departments <--> Cost Centers
for ($i = 0; $i -lt $FakeData.Departments.Count; $i++)
{
  # Assign a cost center to every department
  $UID_ProfitCenter = $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter)
  $FakeData.Departments[$i].UID_ProfitCenter = $UID_ProfitCenter

  # Assign a location to every department
  $UID_Locality = $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality)
  $FakeData.Departments[$i].UID_Locality = $UID_Locality

  # Reverse the assignment - so the department links back to the same cost center
  $($FakeData.CostCenters |Where-Object UID_ProfitCenter -eq $UID_ProfitCenter).UID_Department = $FakeData.Departments[$i].UID_Department

  # Reverse the assignment - so the department links back to the same location
  $($FakeData.Locations |Where-Object UID_Locality -eq $UID_Locality).UID_Department = $FakeData.Departments[$i].UID_Department
}

# Because of the random based assignment, we might have some cost centers without any assigment for departments - let's fix that
$FakeData.CostCenters |Where-Object UID_Department -eq '' | ForEach-Object {
  $_.UID_Department = $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department)
}

# Because of the random based assignment, we might have some locations without any assigment for departments - let's fix that
$FakeData.Locations |Where-Object UID_Department -eq '' | ForEach-Object {
  $_.UID_Department = $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department)
}

# Wire Cost Centers <--> Locations
for ($i = 0; $i -lt $FakeData.CostCenters.Count; $i++)
{
  # Assign a location to every cost center
  $UID_Locality = $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality)
  $FakeData.CostCenters[$i].UID_Locality = $UID_Locality

  # Reverse the assignment - so the cost links back to the same location
  $($FakeData.Locations |Where-Object UID_Locality -eq $UID_Locality).UID_ProfitCenter = $FakeData.CostCenters[$i].UID_ProfitCenter
}

# Because of the random based assignment, we might have some locations without any assigment for profitcenter - let's fix that
$FakeData.Locations |Where-Object UID_ProfitCenter -eq '' | ForEach-Object {
  $_.UID_ProfitCenter = $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter)
}

#
# Persist data into database - this MUST be DONE HERE otherwise we cannot find the foreign keys
#
Write-Debug "[*] Persisting data stage 1"
$st = $(get-date)
Write-Debug "Adding identities to unit of work"
$FakeData.Identities | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

$st = $(get-date)
Write-Debug "Adding departments to unit of work"
$FakeData.Departments | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

$st = $(get-date)
Write-Debug "Adding cost centers to unit of work"
$FakeData.CostCenters | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

$st = $(get-date)
Write-Debug "Adding locations to unit of work"
$FakeData.Locations | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

$st = $(get-date)
Write-Debug "[*] Wire Identities with Cost Centers, Departments, Locations, Managers (direct and indirect)"
# Wire Identities with Cost Centers, Departments, Managers
# and add Identities additionally to Cost Centers, Departments
for ($i = 0; $i -lt $FakeData.Identities.Count; $i++)
{
  # Reload entities to allow further updates
  $FakeData.Identities[$i] = $FakeData.Identities[$i].Reload()

  # Assign a Cost Center to every identity
  $UID_ProfitCenter = $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter)
  $FakeData.Identities[$i].UID_ProfitCenter = $UID_ProfitCenter

  # Assign a Department to every identity
  $UID_Department = $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department)
  $FakeData.Identities[$i].UID_Department = $UID_Department

  # Assign a Location to every identity
  $UID_Locality = $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality)
  $FakeData.Identities[$i].UID_Locality = $UID_Locality

  # Give Identities a fixed default email address
  $FakeData.Identities[$i].DefaultEMailAddress = $FakeData.Identities[$i].CentralAccount + '@fakedata.local'

  # Assign a manager to the identity
  $UID_PersonHead = $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person)
  # Exclude assignments of ourself
  if ($UID_PersonHead -ne $FakeData.Identities[$i].UID_Person) {
    $FakeData.Identities[$i].UID_PersonHead = $UID_PersonHead
  }

  # Do additional assignments only for every 10% of identity
  if (0 -ne $($i % ($FakeData.Identities.Count * 0.1))) {
    continue
  }

  # Additional Department assignments (Exclude the same as already direct assigned)
  $numberOfAdditionalAssignments = $Faker.Random.Number(0, $FakeData.Departments.Count)
  for ($j = 0; $j -lt $numberOfAdditionalAssignments; $j++) {
    $RandomAssignement = $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department)
    if ($RandomAssignement -ne $UID_Department) {
      $Assignment = New-PersonInDepartment -UID_Person $FakeData.Identities[$i].UID_Person `
        -UID_Department $RandomAssignement -Unsaved

      if (0 -eq $FakeData.IdentityInDepartment.Count) {
        $FakeData.IdentityInDepartment += $Assignment
      } elseif (-not ($FakeData.IdentityInDepartment | Where-Object { ($_.UID_Person -eq $FakeData.Identities[$i].UID_Person) -and ($_.UID_Department -eq $RandomAssignement) } )) {
        $FakeData.IdentityInDepartment += $Assignment
      }
    }
  }

  # Additional Cost Center assignments (Exclude the same as already direct assigned)
  $numberOfAdditionalAssignments = $Faker.Random.Number(0, $FakeData.CostCenters.Count)
  for ($j = 0; $j -lt $numberOfAdditionalAssignments; $j++) {
    $RandomAssignement = $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter)
    if ($RandomAssignement -ne $UID_ProfitCenter) {
      $Assignment = New-PersonInProfitCenter -UID_Person $FakeData.Identities[$i].UID_Person `
        -UID_ProfitCenter $RandomAssignement -Unsaved

      if (0 -eq $FakeData.IdentityInCostCenter.Count) {
        $FakeData.IdentityInCostCenter += $Assignment
      } elseif (-not ($FakeData.IdentityInCostCenter | Where-Object { ($_.UID_Person -eq $FakeData.Identities[$i].UID_Person) -and ($_.UID_ProfitCenter -eq $RandomAssignement) } )) {
        $FakeData.IdentityInCostCenter += $Assignment
      }
    }
  }

  # Additional Locality assignments (Exclude the same as already direct assigned)
  $numberOfAdditionalAssignments = $Faker.Random.Number(0, $FakeData.Locations.Count)
  for ($j = 0; $j -lt $numberOfAdditionalAssignments; $j++) {
    $RandomAssignement = $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality)
    if ($RandomAssignement -ne $UID_Locality) {
      $Assignment = New-PersonInLocality -UID_Person $FakeData.Identities[$i].UID_Person `
        -UID_Locality $RandomAssignement -Unsaved

      if (0 -eq $FakeData.IdentityInLocality.Count) {
        $FakeData.IdentityInLocality += $Assignment
      } elseif (-not ($FakeData.IdentityInLocality | Where-Object { ($_.UID_Person -eq $FakeData.Identities[$i].UID_Person) -and ($_.UID_Locality -eq $RandomAssignement) } )) {
        $FakeData.IdentityInLocality += $Assignment
      }
    }
  }

}

$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

#
# Create IT Shop structure
#

# Shop
$ItShop = New-ITShopOrg -Ident_Org 'FakeShop' `
  -ITShopInfo 'SH' `
  -InternalName 'Dummy Shop for testing' `
  -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
  -UID_Department $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department) `
  -UID_Locality $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality) `
  -UID_OrgAttestator 'ATT-AEROLE-ITSHOPADMIN-ATTESTATOR' `
  -Description $Faker.Lorem.Sentence(3, 5) `
  -CustomProperty01 'Fakedata' `
  -Unsaved

# Customer Folder
$ItShopCustomer = New-ITShopOrg -Ident_Org 'Customers of FakeShop' `
  -ITShopInfo 'CU' `
  -InternalName 'Customer folder for FakeShop' `
  -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
  -UID_Department $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department) `
  -UID_Locality $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality) `
  -Description $Faker.Lorem.Sentence(3, 5) `
  -CustomProperty01 'Fakedata' `
  -Unsaved

$ItShopCustomer.UID_ParentITShopOrg = $ItShop.UID_ITShopOrg

# Dynamic group for Customer Folder
# UID_DialogSchedule -> "Dynamic roles check" with fixed UID 'QER-B78E7C59F09D487085506ED339F0257D'
$DynGroupForCustomers = New-DynamicGroup -DisplayName 'Dynamic Group for FakeShop customers' `
  -IsCalculateImmediately 1 `
  -ObjectKeyBaseTree $('<Key><T>ITShopOrg</T><P>' + $ItShopCustomer.UID_ITShopOrg + '</P></Key>') `
  -UID_DialogTableObjectClass 'QER-T-Person' `
  -UID_DialogSchedule 'QER-B78E7C59F09D487085506ED339F0257D' `
  -WhereClause "isnull(IsInActive, 0) = 0 and CustomProperty01 = 'Fakedata'" `
  -Description $Faker.Lorem.Sentence(3, 5) `
  -Unsaved

# Shelf
$ItShopShelf = New-ITShopOrg -Ident_Org 'Shelf for FakeShop' `
  -ITShopInfo 'BO' `
  -InternalName 'Shelf for FakeShop' `
  -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
  -UID_Department $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department) `
  -UID_Locality $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality) `
  -Description $Faker.Lorem.Sentence(3, 5) `
  -UID_OrgAttestator 'ATT-AEROLE-ITSHOPADMIN-ATTESTATOR' `
  -CustomProperty01 'Fakedata' `
  -Unsaved

$ItShopShelf.UID_ParentITShopOrg = $ItShop.UID_ITShopOrg

# Assigning the "Recipient's manager" Approval Policy
$ITShopOrgHasPWODecisionMethod = New-ITShopOrgHasPWODecisionMethod -UID_ITShopOrg $ItShop.UID_ITShopOrg `
  -UID_PWODecisionMethod 'QER-9F9FF8FD4D2FCB4E916B45990E8765B7' `
  -Unsaved

$ItShopQuantity = 1000 # They should be the same
$FakeData.AccProductGroup = New-AccProductGroups -Session $Session -Faker $Faker -FakeData $FakeData
$FakeData.AccProducts = New-AccProducts -Session $Session -Faker $Faker -Quantity $ItShopQuantity -FakeData $FakeData
$FakeData.ProductOwners = New-ProductOwners -Session $Session -Faker $Faker -Quantity $ItShopQuantity -FakeData $FakeData
$FakeData.QERReuses = New-QERReuses -Session $Session -Faker $Faker -Quantity $ItShopQuantity -FakeData $FakeData
$FakeData.ITShopOrgHasQERReuse = New-ITShopOrgHasQERReuses -Session $Session -Faker $Faker -Quantity $ItShopQuantity -FakeData $FakeData -UID_ITShopOrg $ItShopShelf.UID_ITShopOrg

#
# Persist data into database
#
Write-Debug "[*] Persisting data stage 2"
$st = $(get-date)
Write-Debug "Adding identities to unit of work"
$FakeData.Identities | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

$st = $(get-date)
Write-Debug "Adding assignment of identities to departments to unit of work"
$FakeData.IdentityInDepartment | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

$st = $(get-date)
Write-Debug "Adding assignment of identities to cost centers to unit of work"
$FakeData.IdentityInCostCenter | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

$st = $(get-date)
Write-Debug "Adding assignment of identities to locations to unit of work"
$FakeData.IdentityInLocality | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

$ItShop | Add-UnitOfWorkEntity -UnitOfWork $uow
$ItShopCustomer | Add-UnitOfWorkEntity -UnitOfWork $uow
$ItShopShelf | Add-UnitOfWorkEntity -UnitOfWork $uow
$ITShopOrgHasPWODecisionMethod | Add-UnitOfWorkEntity -UnitOfWork $uow
$DynGroupForCustomers | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.AccProductGroup | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.AccProducts | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.ProductOwners | Add-UnitOfWorkEntity -UnitOfWork $uow

# Assign ProductOwner to AccProduct
for ($i = 0; $i -lt $FakeData.AccProducts.Count; $i++)
{
  # Reload entities to allow further updates
  $FakeData.AccProducts[$i] = $FakeData.AccProducts[$i].Reload()
  $FakeData.AccProducts[$i].UID_OrgRuler = $FakeData.ProductOwners[$i].UID_AERole
  $FakeData.AccProducts[$i].UID_AccProductGroup = $FakeData.AccProductGroup.UID_AccProductGroup
}
$FakeData.AccProducts | Add-UnitOfWorkEntity -UnitOfWork $uow

$FakeData.PersonInAERoles = New-PersonInAERoles -Session $Session -Faker $Faker -Quantity 3 -FakeData $FakeData

# Add some random Identities to some common AERoles

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-AEADMIN') {
  # Base roles\Administrators
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-AEADMIN' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-812e7024e3484428bb363ec24da53bfa') {
  # Base roles\Operations support
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-812e7024e3484428bb363ec24da53bfa' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-SCIM-FILTER') {
  # Base roles\API Server SCIM filter
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-SCIM-FILTER' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-CRITICAL-WHERECLAUSE') {
  # Base roles\Security-critical queries
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-CRITICAL-WHERECLAUSE' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'ATT-AEROLE-ATTESTATION-INTERVENTION') {
  # Identity & Access Governance\Attestation\Chief approval team
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'ATT-AEROLE-ATTESTATION-INTERVENTION' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'POL-AEROLE-QERPOLICY-EXCEPTION') {
  # Identity & Access Governance\Company policies\Exception approvers
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'POL-AEROLE-QERPOLICY-EXCEPTION' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'POL-AEROLE-QERPOLICY-ATTESTATOR') {
  # Identity & Access Governance\Company policies\Attestors
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'POL-AEROLE-QERPOLICY-ATTESTATOR' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'POL-AEROLE-QERPOLICY-RESPONSIBLE') {
  # Identity & Access Governance\Company policies\Policy supervisors
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'POL-AEROLE-QERPOLICY-RESPONSIBLE' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'CAP-AEROLE-AUDITING-AUDITOR') {
  # Identity & Access Governance\Auditors
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'CAP-AEROLE-AUDITING-AUDITOR' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'CAP-AEROLE-IAG-CISO') {
  # Identity & Access Governance\Compliance & Security Officer
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'CAP-AEROLE-IAG-CISO' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'CPL-AEROLE-RULEADMIN-ATTESTATOR') {
  # Identity & Access Governance\Identity Audit\Attestors
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'CPL-AEROLE-RULEADMIN-ATTESTATOR' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'CPL-AEROLE-RULEADMIN-EXCEPTION') {
  # Identity & Access Governance\Identity Audit\Exception approvers
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'CPL-AEROLE-RULEADMIN-EXCEPTION' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'CPL-AEROLE-RULEADMIN-RESPONSIBLE') {
  # Identity & Access Governance\Identity Audit\Rule supervisors
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'CPL-AEROLE-RULEADMIN-RESPONSIBLE' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'RPS-AEROLE-IAG-REPORT-ADMIN') {
  # Identity & Access Governance\Report Subscriptions\Administrators
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'RPS-AEROLE-IAG-REPORT-ADMIN' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'RMB-AEROLE-ROLEADMIN-ADMIN') {
  # Identity Management\Business roles\Administrators
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'RMB-AEROLE-ROLEADMIN-ADMIN' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'RMB-AEROLE-ROLEADMIN-ATTESTATOR') {
  # Identity Management\Business roles\Attestors
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'RMB-AEROLE-ROLEADMIN-ATTESTATOR' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'RMB-AEROLE-ROLEADMIN-RULER') {
  # Identity Management\Business roles\Role Approvers
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'RMB-AEROLE-ROLEADMIN-RULER' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'RMB-AEROLE-ROLEADMIN-RULERIT') {
  # Identity Management\Business roles\Role Approvers
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'RMB-AEROLE-ROLEADMIN-RULERIT' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-PERSONADMIN-ADMIN') {
  # Identity Management\Employees\Administrators
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-PERSONADMIN-ADMIN' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-STRUCTADMIN-ADMIN') {
  # Identity Management\Organizations\Administrators
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-STRUCTADMIN-ADMIN' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR') {
  # Identity Management\Organizations\Attestors
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-STRUCTADMIN-RULER') {
  # Identity Management\Organizations\Role approvers
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-STRUCTADMIN-RULER' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-STRUCTADMIN-RULERIT') {
  # Identity Management\Organizations\Role approvers (IT)
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-STRUCTADMIN-RULERIT' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-ITSHOPADMIN-ADMIN') {
  # Request & Fulfillment\IT Shop\Administrators
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-ITSHOPADMIN-ADMIN' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'ATT-AEROLE-ITSHOPADMIN-ATTESTATOR') {
  # Request & Fulfillment\IT Shop\Attestors
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'ATT-AEROLE-ITSHOPADMIN-ATTESTATOR' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-ITSHOP-INTERVENTION') {
  # Request & Fulfillment\IT Shop\Chief approval team
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-ITSHOP-INTERVENTION' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'QER-AEROLE-ITSHOPADMIN-OWNER') {
  # Request & Fulfillment\IT Shop\Product owners
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'QER-AEROLE-ITSHOPADMIN-OWNER' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'RPS-AEROLE-ITSHOP-OWNER-RPSREPORT') {
  # Request & Fulfillment\IT Shop\Product owners\Subscribable reports
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'RPS-AEROLE-ITSHOP-OWNER-RPSREPORT' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'RMS-AEROLE-ITSHOP-OWNER-ESET') {
  # Request & Fulfillment\IT Shop\Product owners\System roles
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'RMS-AEROLE-ITSHOP-OWNER-ESET' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'TSB-AEROLE-NAMESPACEADMIN-ADMIN') {
  # Target systems\Administrators
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'TSB-AEROLE-NAMESPACEADMIN-ADMIN' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'TSB-AEROLE-NAMESPACEADMIN-UNSB') {
  # Target systems\Custom target systems
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'TSB-AEROLE-NAMESPACEADMIN-UNSB' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

if (Get-Entity -Type 'AERole' -Identity 'TSB-AEROLE-NAMESPACEADMIN-UNS') {
  # Target systems\Unified Namespace
  $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole 'TSB-AEROLE-NAMESPACEADMIN-UNS' `
    -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
}

$FakeData.PersonInAERoles | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.QERReuses | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.ITShopOrgHasQERReuse | Add-UnitOfWorkEntity -UnitOfWork $uow

#
# Real save into database
#
Write-Debug "Saving data into database"
$st = $(get-date)
Save-UnitOfWork $uow
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

Remove-IdentityManagerSession -Session $Session

$ElapsedTimeTotal = new-timespan $StartTimeTotal $(get-date)
Write-Debug "[*] Total runtime: $($ElapsedTimeTotal.TotalSeconds) seconds"

### Cleanup

# update ITShopOrgHasQERReuse set XOrigin = 0 where uid_QERReuse in (select uid_QERReuse from QERReuse where CustomProperty01 = 'Fakedata')
# delete from ITShopOrgHasQERReuse where uid_QERReuse in (select uid_QERReuse from QERReuse where CustomProperty01 = 'Fakedata')
# update PersonInAERole set XOrigin = 0 where UID_Person in (select UID_Person from Person where CustomProperty01 = 'Fakedata')
# delete from PersonInAERole where UID_Person in (select UID_Person from Person where CustomProperty01 = 'Fakedata')
# delete from AERole where CustomProperty01 = 'Fakedata'

# delete from ITShopOrg where UID_AccProduct in (select UID_AccProduct from AccProduct where CustomProperty01 = 'Fakedata')
# delete from QERReuse where CustomProperty01 = 'Fakedata'
# delete from AccProduct where CustomProperty01 = 'Fakedata'
# delete from AccProductGroup where CustomProperty01 = 'Fakedata'

# delete from DynamicGroup where DisplayName = 'Dynamic Group for FakeShop customers'
# delete from ITShopOrg where CustomProperty01 = 'Fakedata'

# delete from Person where CustomProperty01 = 'Fakedata'
# delete from Department where CustomProperty01 = 'Fakedata'
# delete from ProfitCenter where CustomProperty01 = 'Fakedata'
# delete from Locality where CustomProperty01 = 'Fakedata'
