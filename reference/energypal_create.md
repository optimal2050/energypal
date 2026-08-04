# Build a palette from a named colour vector

Turns a named character vector of hex colours into a palette object that
can be written to YAML with
[`energypal_write()`](https://optimal2050.github.io/energypal/reference/energypal_write.md),
registered with
[`energypal_register()`](https://optimal2050.github.io/energypal/reference/energypal_register.md),
or used directly.

## Usage

``` r
energypal_create(x, name = "custom", title = NULL, extends = NULL)
```

## Arguments

- x:

  Named character vector of hex colours, e.g. `c(Coal = "#2C2C2C")`.

- name:

  Palette name. Defaults to `"custom"`.

- title:

  Human-readable title. Defaults to `name`.

- extends:

  Optional name of a palette to inherit labels and aliases from.

## Value

A palette specification list, with class `energypal_create`.

## Details

This is the quickest way in: start from a vector, save it, then edit the
YAML to add labels and aliases where they earn their keep.

## See also

[`energypal_write()`](https://optimal2050.github.io/energypal/reference/energypal_write.md),
[`energypal_register()`](https://optimal2050.github.io/energypal/reference/energypal_register.md)

## Examples

``` r
p <- energypal_create(c(Coal = "#2C2C2C", Solar = "#FFA500"), name = "mine")
p$meta$name
#> [1] "mine"
names(p$colors)
#> [1] "Coal"  "Solar"
```
