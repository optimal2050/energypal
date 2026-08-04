# Register a user palette for this session

Makes a palette file available by name, so it can be used anywhere a
built-in palette name is accepted. The registration lasts for the
session only; to make it permanent, call this from `.Rprofile` or pass
`file =` explicitly.

## Usage

``` r
energypal_register(name, file)
```

## Arguments

- name:

  Name to register the palette under.

- file:

  Path to the palette YAML file.

## Value

Invisibly, the previously registered path for `name`, or `NULL`.

## See also

[`energypal_create()`](https://optimal2050.github.io/energypal/reference/energypal_create.md),
[`energypal_write()`](https://optimal2050.github.io/energypal/reference/energypal_write.md),
[`energypal_info()`](https://optimal2050.github.io/energypal/reference/energypal_info.md)

## Examples

``` r
p <- energypal_create(c(Coal = "#2C2C2C", Solar = "#FFA500"), name = "mine")
f <- tempfile(fileext = ".yml")
energypal_write(p, f)
energypal_register("mine", f)
energypal("mine")
#>      Coal     Solar 
#> "#2C2C2C" "#FFA500" 
```
