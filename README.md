**One Identity open source projects are supported through [One Identity GitHub issues](https://github.com/OneIdentity/IdentityManager.PoSh) and the [One Identity Community](https://www.oneidentity.com/community/). This includes all scripts, plugins, SDKs, modules, code snippets or other solutions. For assistance with any One Identity GitHub project, please raise a new Issue on the [One Identity GitHub project](https://github.com/OneIdentity/IdentityManager.PoSh/issues) page. You may also visit the [One Identity Community](https://www.oneidentity.com/community/) to ask questions. Requests for assistance made through official One Identity Support will be referred back to GitHub and the One Identity Community forums where those requests can benefit all users.**

# IdentityManager.PoSh
A Powershell library for One Identity Manager interaction.

<!-- toc -->
<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
    <li><a href="#supported-versions">Supported Versions</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#basic-usage">Basic usage</a>
      <ul>
        <li><a href="#importing-the-module">Importing the module</a></li>
        <li><a href="#list-supported-modules-for-authentication">List supported modules for authentication</a></li>
        <li><a href="#a-first-session">A first session</a>
        <ul>
            <li><a href="#direct-database-connection">Direct database connection</a></li>
            <li><a href="#application-server-connection">Application server connection</a></li>
        </ul>
        <li><a href="#creating-an-entity">Creating an entity</a>
        <ul>
            <li><a href="#generic-option-of-creating-an-entity">Generic option of creating an entity</a></li>
            <li><a href="#typed-wrapper-function-for-creation-of-an-entity">Typed wrapper function for creation of an entity</a></li>
        </ul>
        </li>
        <li><a href="#entity-loading">Entity loading</a>
        <ul>
            <li><a href="#generic-option-of-loading-an-entity">Generic option of loading an entity</a></li>
            <li><a href="#loading-of-multiple-generic-entities">Loading of multiple generic entities</a></li>
            <li><a href="#typed-wrapper-function-for-loading-of-an-entity">Typed wrapper function for loading of an entity</a></li>
            <li><a href="#loading-of-multiple-typed-entities">Loading of multiple typed entities</a></li>
        </ul>
        </li>
        <li><a href="#modifying-an-entity">Modifying an entity</a>
        <ul>
            <li><a href="#generic-option-of-modifying-an-entity">Generic option of modifying an entity</a></li>
            <li><a href="#typed-wrapper-function-for-modifying-an-entity">Typed wrapper function for modifying an entity</a></li>
            <li><a href="#handling-of-foreign keys">Handling of foreign keys</a></li>
            <li><a href="#direct-modification-of-entity-values">Direct modification of entity values</a></li>
        </ul>
        </li>
        <li><a href="#removing-an-entity">Removing an entity</a>
        <ul>
            <li><a href="#generic-option-of-removing-an-entity">Generic option of removing an entity</a></li>
            <li><a href="#typed-wrapper-function-for-removing-an-entity">Typed wrapper function for removing an entity</a></li>
        </ul>
        </li>
        <li><a href="#dealing-with-events">Dealing with events</a>
        <ul>
            <li><a href="#show-possible-events-for-an-entity">Show possible events for an entity</a></li>
            <li><a href="#trigger-an-event-for-an-entity">Trigger an event for an entity</a></li>
        </ul>
        </li>
        <li><a href="#dealing-with-methods">Dealing with methods</a>
        <ul>
            <li><a href="#show-possible-methods-for-an-entity">Show possible methods for an entity</a></li>
            <li><a href="#run-methods-for-an-entity">Run methods for an entity</a></li>
        </ul>
        </li>
        <li><a href="#executing-scripts-within-identity-manager">Executing scripts within Identity Manager</a></li>
        <li><a href="#closing-the-connection">Closing the connection</a></li>
      </ul>
    </li>
    <li><a href="#advanced-usage">Advanced usage</a>
    <ul>
        <li><a href="#using-of-session-variables">Using of session variables</a></li>
        <li><a href="#dealing-with-multiple-database-sessions">Dealing with multiple database sessions</a></li>
    </ul>
    </li>
    <li><a href="#contributing">Contributing</a>
    <ul>
        <li><a href="#general">General</a></li>
        <li><a href="#run-pester-tests">Run Pester tests</a></li>
    </ul>
    </li>
    <li><a href="#license">License</a></li>
  </ol>
</details>

<!-- Supported Versions -->
## Supported Versions

This library is known to work with One Identity Manager version 8.0x and 8.1x.

[:top:](#)

<!-- Requirements -->
## Requirements

* Windows PowerShell 5.0

The Identity Manager product DLLs
  * By default, the Powershell module with try to load all referenced DLLs from a valid Identity Manager client component installation. This is typically at the default path '```C:\Program Files\One Identity\One Identity Manager```'.

  * An alternative method the referenced DLLs can be placed relative to the Powershell module. For a successful connection through the application server you need the following product DLLs:

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
    * System.Memory.dll
    * System.Numerics.Vectors.dll
    * System.Runtime.CompilerServices.Unsafe.dll
    * VI.Base.dll
    * VI.DB.dll

    For convenience there is a script "[handle_deps.ps1](handle_deps.ps1)" that will assist with collecting or cleanup of product dependent DLLs.

:warning: Hint

It is recommended to use the Application Server connection!

[:top:](#)

<!-- Basic usage -->
## Basic usage

[:top:](#)

<!-- Importing the module -->
### Importing the module

    Import-Module .\PSIdentityManagerUtils -Force

[:top:](#)

<!-- List supported modules for authentication -->
### List supported modules for authentication

After the import, a list of supported authentication modules can be shown. You can find more information about authentication modules in the [documentation](https://support.oneidentity.com/de-de/technical-documents/identity-manager/8.1.3/authorization-and-authentication-guide/17#TOPIC-1480519). Later, [a first session](#a-first-session) can be established by choosing one of the supported authentication modules.

    $connectionString = 'url=https://<URL>/AppServer/'
    $factory = 'QBM.AppServer.Client.ServiceClientFactory'
    Get-Authentifier -ConnectionString $connectionString -FactoryName $factory

[:top:](#)

<!-- A first session -->
### A first session

After the module is imported, a first connection (session) can be established. As this is the first connection, it will take some seconds to generate the internal wrapper functions.

:bangbang: Warning

The function generation for wrapper functions ("```New-```", "```Get-```", "```Set-```" and "```Remove-```") will be skipped for every disabled table / object type. If an object may have disabled columns, these columns either won't be added as possible parameters.
It may happen that errors occur during the function generation ```Function ... cannot be created because function capacity 4096 has been exceeded for this scope.```. This is a limitation by Powershell. You can workaround this error by skipping the function generation for specific modules by using the parameter ```-ModulesToSkip``` during the call of ```New-IdentityManagerSession```. An alternative for that is overwriting the limitation for the maximum function capacity by setting a new value like ```$MaximumFunctionCount = 10000``` just before you import the PSIdentityManagerUtils module.

[:top:](#)

<!-- Direct database connection -->
#### Direct database connection

    $connectionString = "User ID=<DBUser-Name>;initial Catalog=<DB-Name>;Data Source=<Server-Name>;Password=<DBUser-Password>;pooling= 'false'"
    $authenticationString = 'Module=DialogUser;User=viadmin;Password=<Password>'
    New-IdentityManagerSession -ConnectionString $connectionString -AuthenticationString $authenticationString

[:top:](#)

<!-- Application server connection -->
#### Application server connection

    $connectionString = 'url=https://<URL>/AppServer/'
    $factory = 'QBM.AppServer.Client.ServiceClientFactory'
    $authenticationString = 'Module=DialogUser;User=viadmin;Password=<Password>'
    New-IdentityManagerSession -ConnectionString $connectionString -AuthenticationString $authenticationString -FactoryName $factory

:warning: Hint

To deal with special certificate requirements you can provide some extra arguments to the connection string:

    $connectionString = 'url=https://<URL>/AppServer/;AcceptSelfSigned=true;AllowServerNameMismatch=true'

As an example to skip wrapper function generation for certain tables / objects use:

    New-IdentityManagerSession -ConnectionString $connectionString -AuthenticationString $authenticationString -FactoryName $factory -ModulesToSkip 'EBS','CSM','UCI','AAD'

[:top:](#)

<!-- Creating an entity -->
### Creating an entity

[:top:](#)

<!-- Generic option of creating an entity -->
#### Generic option of creating an entity

To create a new entity in a generic way use:

    $person = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Fritz'; 'LastName' = 'Fuchs' }

[:top:](#)

<!-- Typed wrapper function for creation of an entity -->
#### Typed wrapper function for creation of an entity

Next, a first object can be created. In this example we are going to create a person entry by using one of the generated wrapper functions.

    $p1 = New-Person -FirstName 'Fritz' -LastName 'Fuchs'

To get some more details about the person, just call the assigned variable with ```$p1```.
You can get some more details about the available properties by issuing ```Get-Help New-Person```. Also all mandatory fields will be marked by only ```[<parameter>]``` and every optional with ```[[<parameter>]]```.

[:top:](#)

<!-- Entity loading -->
### Entity loading

[:top:](#)

<!-- Generic option of loading an entity -->
#### Generic option of loading an entity

An entity can be loaded directly either by the corresponding ```XObjectKey``` or by its ```UID``` in combination with specifying its type.

    $x = Get-Entity -Identity "<Key><T>Person</T><P>0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b</P></Key>"

    $y = Get-Entity -Identity "0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b" -Type Person

[:top:](#)

<!-- Loading of multiple generic entities -->
#### Loading of multiple generic entities

Instead of loading only one entity, it's also possible to query more of them and get a collection.
In the next example, all entities in the Person table that have the same last name "Lustig" are retrieved.

    Get-Entity -Type 'Person' -Filter "Lastname = 'Lustig'"

:warning: Hint

To limit the number of returned entities, you can specify a value for the Parameter ```-ResultSize```. The default value is 1.000 records.

[:top:](#)

<!-- Typed wrapper function for loading of an entity -->
#### Typed wrapper function for loading of an entity

Beside the generic method of loading entities it's also possible to use the typed wrapper functions.

To load an entity by its unique identity keys (```UID``` or ```XObjectKey```) use:

    $p = Get-Person -Identity '4782235b-f606-4c2b-9e3e-b95727b61456'
    $p.Display

    $p = Get-Person -Identity '<Key><T>Person</T><P>4782235b-f606-4c2b-9e3e-b95727b61456</P></Key>'
    $p.Display

[:top:](#)

<!-- Loading of multiple typed entities -->
#### Loading of multiple typed entities

Also the retrieving of several entities is possible:

    # Retrieve all persons with first name Peter and last name Lustig
    Get-Person -FirstName 'Peter' -LastName 'Lustig' | Sort-Object -Property Display | Format-Table Display

    # Retrieve 15 persons
    Get-Person -ResultSize 15 | Sort-Object -Property Display | Format-Table Display

    # Retrieve all Departments there name starts with letter V
    Get-Department -FilterClause "DepartmentName like 'V%'" | Sort-Object -Property Display | Format-Table Display

:warning: Hint

To limit the number of returned entities, you can specify a value for the Parameter ```-ResultSize```. The default value is 1.000 records.

[:top:](#)

<!-- Modifying an entity -->
### Modifying an entity

[:top:](#)

<!-- Generic option of modifying an entity -->
#### Generic option of modifying an entity

You can modify a value of an entity like that.

    Set-Entity -Type Person -Identity "0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b" -Properties @{'LastName' = 'Schmidt'}

[:top:](#)

<!-- Typed wrapper function for modifying an entity -->
#### Typed wrapper function for modifying an entity

To change or modify an object you have to use the "```Set-```" functions. This can be used for single object operations as well as for pipeline operations.

For example to add a value to column CustomProperty01 of every Department:

    Get-Department |Set-Department -CustomProperty01 'xyz'

[:top:](#)

<!-- Handling of foreign keys -->
#### Handling of foreign keys

Foreign keys can be handled either by the string representation of the primary key or directly with an entity:

    # Assign a manager to a department / the UID_Person must be known
    Get-Department -DepartmentName 'D1' |Set-Department -UID_PersonHead 'a5a169ab-eac3-4292-9b05-20eeba990379'

    # Assign a manager to a department by its entity
    $p1 = Get-Person -CentralAccount 'marada'
    Get-Department -DepartmentName 'D1' |Set-Department -UID_PersonHead $p1

[:top:](#)

<!-- Direct modification of entity values -->
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

[:top:](#)

<!-- Removing an entity -->
### Removing an entity

[:top:](#)

<!-- Generic option of removing an entity -->
#### Generic option of removing an entity

To delete an entity from the database you have to call the ```Remove-Entity``` method. In the first place, this will only mark the entity for deletion and not delete it directly. For a direct deletion you have to specify the parameter ```-IgnoreDeleteDelay``` as well.

    Remove-Entity -Type Person -Identity "0f4de334-38e5-4bdf-bfe0-4ae9690c4f2b"

[:top:](#)

<!-- Typed wrapper function for removing an entity -->
#### Typed wrapper function for removing an entity

Objects can be removed by there corresponding ```Remove-``` function. You have to specify either an identity (UID or XObjectKey) or an entity directly. Pipeline operations are supported.

    Remove-Person -Identity '4307b156-3c48-4153-b0de-89e79bba06ee'
    Remove-Person -Identity '<Key><T>Person</T><P>1b3441fa-c2d3-4a18-9fc2-40d364039234</P></Key>'
    Get-Entity -Type 'Person' -Filter "Lastname = 'Lustig'" |Remove-Person -IgnoreDeleteDelay

[:top:](#)

<!-- Dealing with events -->
### Dealing with events

Both methods support pipelining for entities.

[:top:](#)

<!-- Show possible events for an entity -->
#### Show possible events for an entity

To get a list of possible events to trigger for a specific entity use:

    Get-ImEvent -Entity $p1

<!-- Trigger an event for an entity -->
#### Trigger an event for an entity

After you know the name for the event to trigger, you can fire it like:

    Invoke-ImEvent -Entity $p1 -EventName "CHECK_EXITDATE"

It's possible to pass certain event parameters if needed. Use ```EventParameters``` as hash table for that.

[:top:](#)

<!-- Dealing with methods -->
### Dealing with methods

The identity manager supports object as well as customizer methods. The following functions support the handling of entities within pipelines.

[:top:](#)

<!-- Show possible methods for an entity -->
#### Show possible methods for an entity

    Get-Method -Entity $p1

[:top:](#)

<!-- Run methods for an entity -->
#### Run methods for an entity

    Invoke-EntityMethod -Entity $p1

It's also possible to pass certain method parameters if needed. Use ```Parameters``` for that.

[:top:](#)

<!-- Executing scripts within Identity Manager -->
### Executing scripts within Identity Manager

The Identity Manager allows you to execute scripts.

    Invoke-IdentityManagerScript -Name 'QBM_GetTempPath'

[:top:](#)

<!-- Closing the connection -->
### Closing the connection

It's good practice to close any database session after usage.

    Remove-IdentityManagerSession

[:top:](#)

<!-- Advanced usage -->
## Advanced usage

[:top:](#)

<!-- Using of session variables -->
### Using of session variables

Within Identity Manager the usage of session based variables is supported. You can find more information in the [documentation](https://support.oneidentity.com/de-de/technical-documents/identity-manager/8.1.3/configuration-guide/71#TOPIC-1481129).

:warning: Hint

If you define a custom session variable, you must remove it again afterward. Otherwise it remains for the rest of the session and, in certain circumstances, the wrong processes can be generated.

    # Get the session
    $sessionToUse = $Global:imsessions[$Global:imsessions.Keys[0]].Session

    # Add variable
    $sessionToUse.Variables.Put('Variable_1', 'Value of variable 1')

    # Query a variable
    $sessionToUse.Variables['Variable_1']

    # Remove a variable
    $sessionToUse.Variables.Remove('Variable_1')

[:top:](#)

<!-- Dealing with multiple database sessions -->
### Dealing with multiple database sessions

The Identity Manager powershell utils allows you to deal with multiple database connections at the same time. For every session you have to specify a unique prefix for that specific connection:

    New-IdentityManagerSession -ConnectionString $connectionString -AuthenticationString $authenticationString -Prefix db1

With that, the automatically generated functions will get there prefix as well. E.g.: ```New-Person``` will become ```New-db1Person```.

[:top:](#)

<!-- Contributing -->
## Contributing

[:top:](#)

<!-- General -->
### General

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **highly appreciated**.

1. Fork [this project](https://github.com/OneIdentity/IdentityManager.PoSh)
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

[:top:](#)

<!-- Run Pester tests -->
### Run Pester tests

Tests can be started by the command: ```Invoke-Pester -Output Detailed```

[:top:](#)

<!-- LICENSE -->
## License

Distributed under the One Identity - Open Source License. See [LICENSE](LICENSE.md) for more information.

[:top:](#)