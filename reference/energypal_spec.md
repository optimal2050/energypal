# Load a palette specification

Reads a palette YAML file and returns its parsed contents, resolving
`meta.extends` against the palette it inherits from. The result is
cached on the file's path and modification time, so editing a palette
during development invalidates the entry on its own.

## Usage

``` r
energypal_spec(palette = NULL, file = NULL, force = FALSE)
```

## Arguments

- palette:

  Name of a built-in or registered palette. Defaults to the
  `energypal.palette` option, or `"carriers"`.

- file:

  Path to a palette file, taking precedence over `palette`.

- force:

  Logical; if `TRUE`, re-read even when cached.

## Value

A list with `meta` and `colors` elements.

## See also

[`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md)
for a colour vector,
[`energypal_table()`](https://optimal2050.github.io/energypal/reference/energypal_table.md)
for a data frame.

## Examples

``` r
spec <- energypal_spec("carriers")
names(spec)
#> [1] "meta"       "orders"     "properties" "colors"     "metadata"  
spec$meta$title
#> [1] "Energy carriers"
```
