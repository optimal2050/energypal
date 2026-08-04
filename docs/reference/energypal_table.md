# Flatten a palette into a table

Returns one row per palette entry, with its colour, position in the
hierarchy, display labels and aliases. This is the form the matcher and
the scale functions work from, and the most convenient way to inspect a
palette.

## Usage

``` r
energypal_table(
  palette = NULL,
  file = NULL,
  include_groups = TRUE,
  order = NULL,
  direction = 1
)
```

## Arguments

- palette:

  Name of a built-in or registered palette. Defaults to the
  `energypal.palette` option, or `"carriers"`. See
  [`energypal_info()`](https://optimal2050.github.io/energypal/reference/energypal_info.md).

- file:

  Path to a palette file, taking precedence over `palette`.

- include_groups:

  Logical; include the aggregate group rows (default `TRUE`).

- order:

  How to sequence the rows. `NULL` or `"spec"` keeps file order;
  otherwise the name of an ordering declared in the palette, the name of
  a numeric property (sorted descending), one of the computed orderings
  `"alpha"`, `"hue"`, `"lightness"`, `"chroma"`, or an explicit
  character vector of entry names. See
  [`energypal_orders()`](https://optimal2050.github.io/energypal/reference/energypal_orders.md).

  **Presentation only** — orderings arrange visuals and are not model
  inputs.

- direction:

  `1` (default) or `-1` to reverse the chosen order.

## Value

A data frame with columns `name`, `level`, `parent`, `color`, `type`,
`path`, `branch`, `label_short`, `label_long`, `aliases`,
`label_default` and `palette`, plus one column per numeric property the
palette declares. Property columns carry their `note`, `source`, `url`
and `unit` as attributes.

## See also

[`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md)
for a colour vector,
[`energypal_orders()`](https://optimal2050.github.io/energypal/reference/energypal_orders.md)
for the available orderings,
[`energypal_info()`](https://optimal2050.github.io/energypal/reference/energypal_info.md)
for the palette list.

## Examples

``` r
tab <- energypal_table("carriers")
head(tab[, c("name", "level", "type", "color", "label_default")])
#>            name level    type   color label_default
#> 1   FossilFuels     1   group #555555  Fossil Fuels
#> 2    FossilCoal     2 carrier #2C2C2C          Coal
#> 3    Anthracite     3 subtype #1E1E1E    Anthracite
#> 4    Bituminous     3 subtype #343434    Bituminous
#> 5 SubBituminous     3 subtype #4A4A4A SubBituminous
#> 6       Lignite     3 subtype #5C5C5C       Lignite

# Only the carrier-level rows
nrow(energypal_table("carriers", include_groups = FALSE))
#> [1] 85

# Declared properties become columns, and carry their caveat with them
tab <- energypal_table("carriers", include_groups = FALSE)
attr(tab$carbon_intensity, "note")
#> [1] "Presentation only - for ordering and shading. NOT a model input. These are indicative lifecycle medians across a wide reported range; use figures from your own scenario or inventory for any calculation.\n"
attr(tab$carbon_intensity, "unit")
#> [1] "gCO2eq/kWh"
```
