# CHANGELOG

## [0.0.20] - 2024-10-23

### Fixes

### Testing

- Add tests for Test-Entity method
- More tests for modification of entities

### Miscellaneous

- Add Test-Entity method to check existence of entities
- Remove parameter FactoryName from New-IdentityManagerSession. It can be detected automatically from connectionstring.
- Minor improvements for FillDbWithFakeData.ps1

## [0.0.19] - 2024-06-18

### Fixes

- Better detection for unsupported PowerShell version
- Code cleanup

### Testing

### Miscellaneous

## [0.0.18] - 2024-05-22

### Fixes

- Fix reloading of entities

### Testing

- Fix performance tests
- More tests for Resolve-Exception

### Miscellaneous

## [0.0.17] - 2024-04-30

### Fixes

- Fix reloading of entities

### Testing

### Miscellaneous

- Add contribute script to populate a database with some fake data

## [0.0.16] - 2024-04-10

### Fixes

- Fix issues with duplicate session closing

### Testing

- Add some performance tests

### Miscellaneous

- Fix some typos
- Improve bulk operations

## [0.0.15] - 2023-11-28

### Fixes

### Testing

### Miscellaneous

- Turn off debug messages and add hint into README.md

## [0.0.14] - 2023-11-28

### Fixes

- Hotfix for missing variable assignment in v0.0.13

### Testing

### Miscellaneous

## [0.0.13] - 2023-11-28

### Fixes

- Fix issue #22: How to deal with multiple DB's in different versions
- Fix issue #23: Cant create application server connection

### Testing

- Add more tests for New-IdentityManagerSession
- Minor cleanup

### Miscellaneous

- Minor cleanup
- Introduce new parameter ModulesToAdd to New-IdentityManagerSession and wrapper functions to control function creation
- Introduce new parameter ProductFilePath to Get-Authentifier and New-IdentityManagerSession to allow specification of assembly path

## [0.0.12] - 2023-07-25

### Fixes

- Fix issue #19: Can't set attributes to empty

### Testing

- Add tests for Set-EntityColumnValue

### Miscellaneous

## [0.0.11] - 2023-03-23

### Fixes

- Fix typos

### Testing

### Miscellaneous

## [0.0.10] - 2021-10-08

### Fixes

- Add method ```Get-TableCount```

### Testing

- Add tests for method ```Get-TableCount```

### Miscellaneous

## [0.0.9] - 2021-10-08

### Fixes

- Rename ```Get-Method``` to ```Get-EntityMethod```

### Testing

### Miscellaneous

## [0.0.8] - 2021-10-08

### Fixes

- Reload entities to allow further updates
- Don't try to load an entity if it already passed

### Testing

- First typed wrapper tests

### Miscellaneous

- Major improvements for [README.md](README.md)
- Add new script [handle_deps.ps1](handle_deps.ps1) to allow easy handling of external product DLLs
- Rename License file to [LICENSE.md](LICENSE.md)

## [0.0.7] - 2021-01-13

### Fixes

### Testing

### Miscellaneous

## [0.0.6] - 2021-01-04

### Fixes

- Fix [#7](https://github.com/OneIdentity/IdentityManager.PoSh/issues/7) New-Entity fails with error: "Resolve-Exception : The term 'Add-s' is not recognized as the name of a cmdlet..."

### Testing

### Miscellaneous

## [0.0.5] - 2020-11-19

### Fixes

- Fix missing $ in [README.md](README.md)
- Fix missing DLLs in [README.md](README.md)

### Features

- Better error handling during module loading

### Testing

### Miscellaneous

## [0.0.4] - 2020-11-05

### Fixes

- Rename functions ```Get-Event``` / ```Invoke-Event``` to ```Get-ImEvent``` / ```Invoke-ImEvent``` because of ambiguous overwriting of default methods

### Features

- Introduce tests

### Testing

- Introduce Pester tests

### Miscellaneous