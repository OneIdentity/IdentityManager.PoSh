# CHANGELOG

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