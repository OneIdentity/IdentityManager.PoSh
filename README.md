**One Identity open source projects are supported through [One Identity GitHub issues](https://github.com/OneIdentity/ars-ps/issues) and the [One Identity Community](https://www.oneidentity.com/community/). This includes all scripts, plugins, SDKs, modules, code snippets or other solutions. For assistance with any One Identity GitHub project, please raise a new Issue on the [One Identity GitHub project](https://github.com/OneIdentity/ars-ps/issues) page. You may also visit the [One Identity Community](https://www.oneidentity.com/community/) to ask questions.  Requests for assistance made through official One Identity Support will be referred back to GitHub and the One Identity Community forums where those requests can benefit all users.**

# IdentityManager.PoSh
A Powershell library for One Identity Manager
# IdentityManagerUtils

Powershell module to interact with the Identity Manager starting from version 8.0

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

## Basic usage

### Importing the module

    Import-Module .\PSIdentityManagerUtils -Force

### A first session

After the module is imported a first connection (session) can be established. As this is the first connection, it will take some seconds to pre generate the internal wrapper functions.

❗ Warning

The function generation for wrapper functions ("New-", "Get-", "Set-" and "Remove-") will be skipped for every disabled table / object type. If an object may have disabled columns, these columns either won't be added as possible parameters.
It may happen that errors occur during the function generation ```Function ... cannot be created because function capacity 4096 has been exceeded for this scope.```. This is a limitation by Powershell. You can workaround this error by skipping the function generation for specific modules by using the parameter ```-ModulesToSkip``` during the call of ```New-IdentityManagerSession```.

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

You can also provide some extra arguments to the connection string do deal with special certificate requirements:

    $connectionString = 'url=https://<URL>/AppServer/;AcceptSelfSigned=true;AllowServerNameMismatch=true'

### Creating an entity

Next, a first object can be created. In this example we are going to create a person entry by using one of the pre generated wrapper functions.

    $p1 = New-Person -FirstName 'Fritz' -LastName 'Fuchs'

To get some more details about the person, just call the assigned variable with ```$p1```.
You can get some more details about the available properties by issuing ```Get-Help New-Person```. Also all mandatory fields will be marked by only ```[<parameter>]``` and every optional with ```[[<parameter>]]```.

### Load an entity

#### Generic option of loading an entity

An entity can be loaded directly either by the corresponding XObjectKey or by it's UID in combination with specifying it's type.

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

To load an entity by it's unique identity keys (UID or XObjectKey) use:

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

    # Retrieve all Departments there Departmentname starts with letter V
    Get-Department -FilterClause "DepartmentName like 'V%'" | Sort-Object -Property Display | Format-Table Display

⚠ Hint

To limit the number of returned entities, you can specify a value for the Parameter ```-ResultSize```. The default value is 1.000 records.

### Getting  attributes of an object
After loading an object it first contains the primary keys and attributes relevant for display. 
    #Additional attributes can be loaded using GetValue
    $p1 = Get-Person -Identity 'a5a169ab-eac3-4292-9b05-20eeba990379'
    $p1.GetValue('Lastname').Value

### Modifying an entity

#### Generic option of modifying an entity

You can modify a value of an entity like that.

    Set-Entity -Type Person -Identity "0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b" -Properties @{'LastName' = 'Schmidt'}

#### Typed wrapper function for modifying an entity

To change or modify an object you have to use the "Set-" functions. This can be used for single object operations as well as for pipeline operations.

For example to add a value to column CustomProperty01 of every Department:

    Get-Department |Set-Department -CustomProperty01 'xyz'

#### Special handling or foreign keys

Foreign keys can be handled either by the string representation of the primary key or directly with an entity:

    # Assign a manager to an department / the UID_Person must be known
    Get-Department -DepartmentName 'D1' |Set-Department -UID_PersonHead 'a5a169ab-eac3-4292-9b05-20eeba990379'

    # Assign a manager to an department by its entity
    $p1 = Get-Person -CentralAccount 'marada'
    Get-Department -DepartmentName 'D1' |Set-Department -UID_PersonHead $p1

### Removing an entity

#### Generic option of removing an entity

To delete an entity from the database you have to call the Remove-Entity method. In the first place, this will only mark the entity for deletion and not delete it directly. For an direct deletion you have to specify the parameter ```-IgnoreDeleteDelay``` as well.

    Remove-Entity -Type Person -Identity "0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b"

#### Typed wrapper function for removing an entity

Objects can be removed by there corresponding ```Remove-``` function. You have to specify either an identity (UID or XObjectKey) or an entity directly. Pipeline operations are supported.

    Remove-Person -Identity '4307b156-3c48-4153-b0de-89e79bba06ee'
    Remove-Person -Identity '<Key><T>Person</T><P>1b3441fa-c2d3-4a18-9fc2-40d364039234</P></Key>'
    Get-Entity -Type 'Person' -Filter "Lastname = 'Lustig'" |Remove-Person -IgnoreDeleteDelay

### Closing the connection

It's good practice to close any database session after usage.

    Remove-IdentityManagerSession

## Advanced usage

### Dealing with multiple database sessions

The Identity Manager powershell utils allows you to deal with multiple database connections at the same time. For every session you have to specify an unique prefix for that specific connection:

    New-IdentityManagerSession -ConnectionString $connectionString -AuthenticationString $authenticationString -Prefix db1

With that, the automatically generated functions will get there prefix as well. E.g.: ```New-Person``` will become ```New-db1Person```.
