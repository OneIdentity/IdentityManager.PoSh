Param (
    [parameter(Mandatory = $false, HelpMessage = 'Connectionstring to an Identity Manager database')]
    [ValidateNotNullOrEmpty()]
    [string] $ConectionString = 'Data Source=127.0.0.1;Initial Catalog=DB;Integrated Security=False;User ID=sa;Password=***;Pooling=False',

    [parameter(Mandatory = $false, HelpMessage = 'The authentication to use')]
    [ValidateNotNullOrEmpty()]
    [string] $ProductFilePath = 'D:\ClientTools',

    [parameter(Mandatory = $false, HelpMessage = 'The base path to load the Identity Manager product files from.')]
    [ValidateNotNullOrEmpty()]
    [string] $AuthenticationString = 'Module=DialogUser;User=viadmin;Password=***'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue' # Valid values are 'SilentlyContinue' -> Don't show any debug messages; Continue -> Show debug messages.
$ProgressPreference = 'SilentlyContinue'

Import-Module $(Join-Path "$PSScriptRoot" ".." "PSIdentityManagerUtils\PSIdentityManagerUtils.psm1")

$ModulesToAdd = 'QER'

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
$FileToLoad = Join-Path "$PSScriptRoot" 'Bogus.dll'
try {
    [System.Reflection.Assembly]::LoadFrom($FileToLoad) | Out-Null
    $clientVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FileToLoad).ProductVersion
    Write-Debug "[+] File ${FileToLoad} loaded with version ${clientVersion}"
} catch {
    Resolve-Exception -ExceptionObject $PSitem
}

# For easy QR Codes we use https://www.nuget.org/packages/QRCoder/1.4.3
# https://github.com/codebude/QRCoder/
$FileToLoad = Join-Path "$PSScriptRoot" 'QRCoder.dll'
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
            -DialogUserPassword 'UnsecureP@ssw0rd' `
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
      -Unsaved

      if ($null -ne $Department.PSObject.Members['UID_OrgAttestator']) {
        $Department.UID_OrgAttestator = 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR'
      }

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
      -Unsaved

      if ($null -ne $ProfitCenter.PSObject.Members['UID_OrgAttestator']) {
        $ProfitCenter.UID_OrgAttestator = 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR'
      }

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
      -Unsaved

      if ($null -ne $Locality.PSObject.Members['UID_OrgAttestator']) {
        $Locality.UID_OrgAttestator = 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR'
      }

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

$CommonAeRoles = @(
'AOB-AEROLE-ADMIN', # Application Governance\Administrators
'AOB-AEROLE-APPROVERS', # Application Governance\Application approvers
'AOB-AEROLE-OWNERS', # Application Governance\Application owners
'QER-AEROLE-AEADMIN', # Base roles\Administrators
'QER-AEROLE-SCIM-FILTER', # Base roles\ApiServer SCIM Filter
'QER-F8B968E2DFECD64EAFFE6A823816549F', # Base roles\Lock single properties
'QER-812e7024e3484428bb363ec24da53bfa', # Base roles\Operations support
'QER-493191220A59224BAD0D89D67C769D68', # Base roles\Operations support\Password helpdesk
'QER-5171ec005dde4649b3e10b3736033e0d', # Base roles\Operations support\Synchronization post-processing
'QER-ec9fe80870cb443da743d68d270c17be', # Base roles\Operations support\System administrators
'QER-AEROLE-CRITICAL-WHERECLAUSE', # Base roles\Security-critical queries
'QER-AEROLE-CUSTOMADMIN-ADMIN', # Custom\Administrators
'QER-AEROLE-CUSTOMADMIN-CUSTOM', # Custom\Managers
'CAP-AEROLE-AUDITING-AUDITOR', # Identity & Access Governance\§§Auditors
'ATT-AEROLE-ATTESTATIONADMIN-ADMIN', # Identity & Access Governance\Attestation\Administrators
'ATT-AEROLE-ATTESTATION-OWNER-DIRECT', # Identity & Access Governance\Attestation\Attestation policy owners\Direct owners
'ATT-AEROLE-ATTESTATION-OWNER-ROLE', # Identity & Access Governance\Attestation\Attestation policy owners\Owner roles
'ATT-AEROLE-ATTESTATION-INTERVENTION', # Identity & Access Governance\Attestation\Chief approval team
'ATT-6567356C50B5460693BBF3CF69F5883B', # Identity & Access Governance\Attestation\External user approvers
'POL-AEROLE-QERPOLICY-ADMIN', # Identity & Access Governance\Company policies\Administrators
'POL-AEROLE-QERPOLICY-ATTESTATOR', # Identity & Access Governance\Company policies\Attestors
'POL-AEROLE-QERPOLICY-EXCEPTION', # Identity & Access Governance\Company policies\Exception approvers
'POL-AEROLE-QERPOLICY-RESPONSIBLE', # Identity & Access Governance\Company policies\Policy supervisors
'CAP-AEROLE-IAG-CISO', # Identity & Access Governance\Compliance & Security Officer
'CPL-AEROLE-RULEADMIN-ADMIN', # Identity & Access Governance\Identity Audit\Administrators
'CPL-AEROLE-RULEADMIN-ATTESTATOR', # Identity & Access Governance\Identity Audit\Attestors
'CPL-AEROLE-RULEADMIN-EXCEPTION', # Identity & Access Governance\Identity Audit\Exception approvers
'SAC-AEROLE-RULEADMIN-SAPRIGHTS', # Identity & Access Governance\Identity Audit\Maintain SAP functions
'CPL-AEROLE-RULEADMIN-RESPONSIBLE', # Identity & Access Governance\Identity Audit\Rule supervisors
'RPS-AEROLE-IAG-REPORT-ADMIN', # Identity & Access Governance\Report Subscriptions\Administrators
'QER-AEROLE-AEROLEADMIN-ADDMANAGER', # Identity Management\Application roles\Additional managers
'RMB-AEROLE-ROLEADMIN-ADDMANAGER', # Identity Management\Business roles\Additional managers
'RMB-AEROLE-ROLEADMIN-ADMIN', # Identity Management\Business roles\Administrators
'RMB-AEROLE-ROLEADMIN-ATTESTATOR', # Identity Management\Business roles\Attestors
'RMB-AEROLE-ROLEADMIN-RULER', # Identity Management\Business roles\Role Approvers
'RMB-AEROLE-ROLEADMIN-RULERIT', # Identity Management\Business roles\Role Approvers (IT)
'QER-AEROLE-PERSONADMIN-ADMIN', # Identity Management\Identities\Administrators
'QER-AEROLE-STRUCTADMIN-ADDMANAGER', # Identity Management\Organizations\Additional managers
'QER-AEROLE-STRUCTADMIN-ADMIN', # Identity Management\Organizations\Administrators
'ATT-AEROLE-STRUCTADMIN-ATTESTATOR', # Identity Management\Organizations\Attestors
'QER-AEROLE-STRUCTADMIN-RULER', # Identity Management\Organizations\Role Approvers
'QER-AEROLE-STRUCTADMIN-RULERIT', # Identity Management\Organizations\Role Approvers (IT)
'PAG-AEROLE-ASSET-OWNER', # Privileged Account Governance\Asset and account owners
'QER-AEROLE-ITSHOPADMIN-ADDMANAGER', # Request & Fulfillment\IT Shop\Additional managers
'QER-AEROLE-ITSHOPADMIN-ADMIN', # Request & Fulfillment\IT Shop\Administrators
'ATT-AEROLE-ITSHOPADMIN-ATTESTATOR', # Request & Fulfillment\IT Shop\Attestors
'QER-AEROLE-ITSHOP-INTERVENTION', # Request & Fulfillment\IT Shop\Chief approval team
'QER-AEROLE-ITSHOPADMIN-OWNER', # Request & Fulfillment\IT Shop\Product owners
'ADS-AEROLE-ADSGROUP-OWNER-EMPTY', # Request & Fulfillment\IT Shop\Product owners\<Without owner in AD>
'SP0-AEROLE-SPSGROUP-OWNER-EMPTY', # Request & Fulfillment\IT Shop\Product owners\<Without owner in SharePoint>
'PAG-AEROLE-ITSHOP-OWNER-USRGROUP', # Request & Fulfillment\IT Shop\Product owners\PAM user groups
'APC-AEROLE-ITSHOP-OWNER-APP', # Request & Fulfillment\IT Shop\Product owners\Software
'RPS-AEROLE-ITSHOP-OWNER-RPSREPORT', # Request & Fulfillment\IT Shop\Product owners\Subscribable reports
'RMS-AEROLE-ITSHOP-OWNER-ESET', # Request & Fulfillment\IT Shop\Product owners\System roles
'ADS-AEROLE-NAMESPACEADMIN-ADS', # Target systems\Active Directory
'TSB-AEROLE-NAMESPACEADMIN-ADMIN', # Target systems\Administrators
'AAD-AEROLE-NAMESPACEADMIN-AAD', # Target systems\Azure Active Directory
'AAD-3ba6aa44fefb4b2694b7ca12d504b903', # Target systems\Azure Active Directory\Administrative unit owners
'AAD-c6b5865628cd46249367730f922a490b', # Target systems\Azure Active Directory\App registration owners
'AAD-AA4FBEC4EBCD3641BA75B7479D090EEF', # Target systems\Azure Active Directory\Role owners
'AAD-1d27dbae3fe94c9c83e633e72e4ab235', # Target systems\Azure Active Directory\Service principal owners
'CSM-AEROLE-NAMESPACEADMIN-CSM', # Target systems\Cloud target systems
'TSB-AEROLE-NAMESPACEADMIN-UNSB', # Target systems\Custom target systems
'NDO-AEROLE-NAMESPACEADMIN-NDO', # Target systems\Domino
'EX0-AEROLE-NAMESPACEADMIN-EX0', # Target systems\Exchange
'O3E-AEROLE-NAMESPACEADMIN-O3E', # Target systems\Exchange Online
'GAP-AEROLE-NAMESPACEADMIN-GAP', # Target systems\G Suite
'LDP-AEROLE-NAMESPACEADMIN-LDAP', # Target systems\LDAP
'OLG-AEROLE-NAMESPACEADMIN-OLG', # Target systems\OneLogin
'EBS-AEROLE-NAMESPACEADMIN-EBS', # Target systems\Oracle E-Business Suite
'PAG-AEROLE-NAMESPACEADMIN-PAG', # Target systems\Privileged Account Management
'SAP-AEROLE-NAMESPACEADMIN-SAPR3', # Target systems\SAP R/3
'SP0-AEROLE-NAMESPACEADMIN-SPS', # Target systems\SharePoint
'O3S-AEROLE-NAMESPACEADMIN-O3S', # Target systems\SharePoint Online
'TSB-AEROLE-NAMESPACEADMIN-UNS', # Target systems\Unified Namespace
'UNX-AEROLE-NAMESPACEADMIN-UNIX', # Target systems\Unix
'UCI-AEROLE-CLOUD-ADMINISTRATOR', # Universal Cloud Interface\Administrators
'UCI-AEROLE-CLOUD-AUDITOR', # Universal Cloud Interface\Auditors
'UCI-AEROLE-CLOUD-OPERATOR' # Universal Cloud Interface\Operators
)

$CommonAeRoles | ForEach-Object {
    if (Test-Entity -Type 'AERole' -Identity $_) {
      # Base roles\Administrators
      $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole $_ `
        -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
    } else {
      Write-Debug "Skip assignment of '$_'"
    }
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

Write-Debug "Closing connection"
$st = $(get-date)
Remove-IdentityManagerSession -Session $Session
$et = new-timespan $st $(get-date)
Write-Debug "Done in $($et.TotalSeconds) seconds"

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
