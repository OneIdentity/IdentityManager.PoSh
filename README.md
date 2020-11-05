**One Identity open source projects are supported through [One Identity GitHub issues](https://github.com/OneIdentity/ars-ps/issues) and the [One Identity Community](https://www.oneidentity.com/community/). This includes all scripts, plugins, SDKs, modules, code snippets or other solutions. For assistance with any One Identity GitHub project, please raise a new Issue on the [One Identity GitHub project](https://github.com/OneIdentity/ars-ps/issues) page. You may also visit the [One Identity Community](https://www.oneidentity.com/community/) to ask questions.  Requests for assistance made through official One Identity Support will be referred back to GitHub and the One Identity Community forums where those requests can benefit all users.**

# IdentityManager.PoSh
A Powershell library for One Identity Manager

## Requirements

* Windows PowerShell 5.0

The Identity Manager product DLLs
  * By default, the Powershell module with try to load all referenced DLLs from a valid Identity Manager client component installation. This is typically at the default path 'C:\Program Files\One Identity\One Identity Manager'.

  * As an alternative method the referenced DLLs can be placed relative to the Powershell module. You need at least (for a connection through the application server):

    * Newtonsoft.Json.dll
    * NLog.dll
    * QBM.AppServer.Client.dll
    * QBM.AppServer.Interface.dll
    * QBM.AppServer.JobProvider.Plugin.dll
    * QER.AppServer.Plugin.dll
    * QER.Customizer.dll
    * QER.DB.Plugin.dll
    * QER.Interfaces.dll
    * ServiceStack.Client.dll
    * ServiceStack.Common.dll
    * ServiceStack.dll
    * ServiceStack.Interfaces.dll
    * ServiceStack.Text.dll
    * VI.Base.dll
    * VI.DB.dll

⚠ Hint

It is recommended to using the Application Server connection! 

## Basic usage

### Importing the module

    Import-Module .\PSIdentityManagerUtils -Force

### A first session

After the module is imported a first connection (session) can be established. As this is the first connection, it will take some seconds to pre generate the internal wrapper functions.

❗ Warning

The function generation for wrapper functions ("New-", "Get-", "Set-" and "Remove-") will be skipped for every disabled table / object type. If an object may have disabled columns, these columns either won't be added as possible parameters.
It may happen that errors occur during the function generation ```Function ... cannot be created because function capacity 4096 has been exceeded for this scope.```. This is a limitation by Powershell. You can workaround this error by skipping the function generation for specific modules by using the parameter ```-ModulesToSkip``` during the call of ```New-IdentityManagerSession```. An alternative for that is overwriting the limitation for the maximum function capacity by setting a new value like ```$MaximumFunctionCount = 10000``` just before you import the PSIdentityManagerUtils module.

#### Direct database connection

    $connectionString = "User ID=<DBUser-Name>;initial Catalog=<DB-Name>;Data Source=<Server-Name>;Password=<DBUser-Password>;pooling= 'false'"
    $authenticationString = 'Module=DialogUser;User=viadmin;Password=<Password>'
    New-IdentityManagerSession -ConnectionString $connectionString -AuthenticationString $authenticationString

#### Application server connection

    $connectionString = 'url=https://<URL>/AppServer/'
    $authenticationString = 'Module=DialogUser;User=viadmin;Password=<Password>'
    $factory = 'QBM.AppServer.Client.ServiceClientFactory'
    New-IdentityManagerSession -ConnectionString $connectionString -AuthenticationString $authenticationString -FactoryName $factory

⚠ Hint

To deal with special certificate requirements you can provide some extra arguments to the connection string:

    $connectionString = 'url=https://<URL>/AppServer/;AcceptSelfSigned=true;AllowServerNameMismatch=true'

As an example to skip wrapper function generation for certain tables / objects use:

    New-IdentityManagerSession -ConnectionString $connectionString -AuthenticationString $authenticationString -FactoryName $factory -ModulesToSkip 'EBS','CSM','UCI','AAD'

### Creating an entity

#### Generic option of creating an entity

To create a new entity in a generic way use:

    $person = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Fritz'; 'LastName' = 'Fuchs' }

#### Typed wrapper function for creation of an entity

Next, a first object can be created. In this example we are going to create a person entry by using one of the pre generated wrapper functions.

    $p1 = New-Person -FirstName 'Fritz' -LastName 'Fuchs'

To get some more details about the person, just call the assigned variable with ```$p1```.
You can get some more details about the available properties by issuing ```Get-Help New-Person```. Also all mandatory fields will be marked by only ```[<parameter>]``` and every optional with ```[[<parameter>]]```.

### Load an entity

#### Generic option of loading an entity

An entity can be loaded directly either by the corresponding XObjectKey or by its UID in combination with specifying its type.

    $x = Get-Entity -Identity "<Key><T>Person</T><P>0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b</P></Key>"

    $y = Get-Entity -Identity "0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b" -Type Person

##### Loading of multiple entities (collections)

Instead of loading only one entity, it's also possible to query more of them.
In the next example, all entities in the Person table that have the same last name "Lustig" are retrieved.

    Get-Entity -Type 'Person' -Filter "Lastname = 'Lustig'"

⚠ Hint

To limit the number of returned entities, you can specify a value for the Parameter ```-ResultSize```. The default value is 1.000 records.

#### Typed wrapper function for loading of an entity

Beside the generic method of loading entities it's also possible to use the typed wrapper functions.

To load an entity by its unique identity keys (UID or XObjectKey) use:

    $p = Get-Person -Identity '4782235b-f606-4c2b-9e3e-b95727b61456'
    $p.Display

    $p = Get-Person -Identity '<Key><T>Person</T><P>4782235b-f606-4c2b-9e3e-b95727b61456</P></Key>'
    $p.Display

##### Loading of multiple entities (collections)

Also the retrieving of several entities is possible:

    # Retrieve all persons with first name Peter and last name Lustig
    Get-Person -FirstName 'Peter' -LastName 'Lustig' | Sort-Object -Property Display | Format-Table Display

    # Retrieve 15 persons
    Get-Person -ResultSize 15 | Sort-Object -Property Display | Format-Table Display

    # Retrieve all Departments there name starts with letter V
    Get-Department -FilterClause "DepartmentName like 'V%'" | Sort-Object -Property Display | Format-Table Display

⚠ Hint

To limit the number of returned entities, you can specify a value for the Parameter ```-ResultSize```. The default value is 1.000 records.

### Modifying an entity

#### Generic option of modifying an entity

You can modify a value of an entity like that.

    Set-Entity -Type Person -Identity "0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b" -Properties @{'LastName' = 'Schmidt'}

#### Typed wrapper function for modifying an entity

To change or modify an object you have to use the "Set-" functions. This can be used for single object operations as well as for pipeline operations.

For example to add a value to column CustomProperty01 of every Department:

    Get-Department |Set-Department -CustomProperty01 'xyz'

#### Special handling of foreign keys

Foreign keys can be handled either by the string representation of the primary key or directly with an entity:

    # Assign a manager to a department / the UID_Person must be known
    Get-Department -DepartmentName 'D1' |Set-Department -UID_PersonHead 'a5a169ab-eac3-4292-9b05-20eeba990379'

    # Assign a manager to a department by its entity
    $p1 = Get-Person -CentralAccount 'marada'
    Get-Department -DepartmentName 'D1' |Set-Department -UID_PersonHead $p1

#### Direct modification of entity values

It's even possible to modify a loaded entity directly. In the following sample a person entity is loaded, the last name as well as the direct department assignment is changed:

    # Load person with last name Lustig
    $p1 = Get-Person -Lastname 'Lustig'
    # Modify the last name of that loaded person
    $p1.Lastname = 'Lustiger'
    # Load Accounting department
    Get-Department -FilterClause "DepartmentName = 'Accounting'"
    # Set Accounting department
    $p1.UID_Department = $d1

### Removing an entity

#### Generic option of removing an entity

To delete an entity from the database you have to call the Remove-Entity method. In the first place, this will only mark the entity for deletion and not delete it directly. For a direct deletion you have to specify the parameter ```-IgnoreDeleteDelay``` as well.

    Remove-Entity -Type Person -Identity "0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b"

#### Typed wrapper function for removing an entity

Objects can be removed by there corresponding ```Remove-``` function. You have to specify either an identity (UID or XObjectKey) or an entity directly. Pipeline operations are supported.

    Remove-Person -Identity '4307b156-3c48-4153-b0de-89e79bba06ee'
    Remove-Person -Identity '<Key><T>Person</T><P>1b3441fa-c2d3-4a18-9fc2-40d364039234</P></Key>'
    Get-Entity -Type 'Person' -Filter "Lastname = 'Lustig'" |Remove-Person -IgnoreDeleteDelay

### Dealing with events

Both methods support pipelining for entities.

#### Show possible events for an entity

To get a list of possible events to trigger for a specific entity use:

    Get-Event -Entity $p1

#### Trigger an event for an entity

After you know the name for the event to trigger, you can fire it like:

    Invoke-Event -Entity $p1 -EventName "CHECK_EXITDATE"

It's possible to pass certain event parameters if needed. Use ```EventParameters``` as hash table for that.

### Dealing with methods

The identity manager supports object as well as customizer methods. The following functions support the handling of entities within pipelines.

#### Show possible methods for an entity

    Get-Method -Entity $p1

#### Run methods for an entity

    Invoke-EntityMethod  -Entity $p1

It's also possible to pass certain method parameters if needed. Use ```Parameters``` for that.

### Executing scripts within Identity Manager

The Identity Manager allows you to execute scripts.

    Invoke-IdentityManagerScript -Name 'QBM_GetTempPath'

### Closing the connection

It's good practice to close any database session after usage.

    Remove-IdentityManagerSession

## Advanced usage

### Dealing with multiple database sessions

The Identity Manager powershell utils allows you to deal with multiple database connections at the same time. For every session you have to specify a unique prefix for that specific connection:

    New-IdentityManagerSession -ConnectionString $connectionString -AuthenticationString $authenticationString -Prefix db1

With that, the automatically generated functions will get there prefix as well. E.g.: ```New-Person``` will become ```New-db1Person```.
