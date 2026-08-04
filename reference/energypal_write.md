# Write a palette to a YAML file

Serialises a palette so it can be edited by hand and reloaded. Entries
are written in the simple `Name: "#RRGGBB"` form; any entry can then be
expanded in place into a map with `_color`, `_short`, `_long` and
`_aliases` without restructuring the rest of the file.

## Usage

``` r
energypal_write(pal, file)
```

## Arguments

- pal:

  A palette from
  [`energypal_create()`](https://optimal2050.github.io/energypal/reference/energypal_create.md),
  or any named colour vector.

- file:

  Path to write to.

## Value

Invisibly, `file`.

## See also

[`energypal_create()`](https://optimal2050.github.io/energypal/reference/energypal_create.md),
[`energypal_register()`](https://optimal2050.github.io/energypal/reference/energypal_register.md)

## Examples

``` r
p <- energypal_create(c(Coal = "#2C2C2C", Solar = "#FFA500"), name = "mine")
f <- tempfile(fileext = ".yml")
energypal_write(p, f)
cat(readLines(f), sep = "\n")
#> # energypal palette
#> #
#> # Each entry may be a bare colour, or a map with _color, _short, _long and
#> # _aliases. Add detail to individual entries as needed; the rest can stay simple.
#> 
#> meta:
#>   name: mine
#>   title: mine
#>   version: 0.1.0
#> 
#> colors:
#>   Coal: "#2C2C2C"
#>   Solar: "#FFA500"
```
