# Plot energy palettes

Draws a palette so you can look at it. Given several palette names it
draws them as aligned rows instead, one row per palette and one column
per entry, which is the quickest way to see how two published colour
schemes differ.

## Usage

``` r
energypal_show(
  palette = NULL,
  n = NULL,
  file = NULL,
  label_style = c("default", "id", "short", "long"),
  include_groups = FALSE,
  include_subtypes = FALSE,
  show_hex = TRUE
)
```

## Arguments

- palette:

  Palette name, or a character vector of names to compare. Defaults to
  the `energypal.palette` option, or `"carriers"`. Pass
  `energypal_info()$name` to see everything at once.

- n:

  Number of colours to show from each palette. `NULL` shows all.

- file:

  Path to a palette file, taking precedence over `palette`. Only
  meaningful for a single palette.

- label_style:

  How to label entries: `"default"`, `"id"`, `"short"` or `"long"`. See
  [`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md).

- include_groups, include_subtypes:

  Passed to
  [`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md);
  both `FALSE` by default, matching the plotting palette.

- show_hex:

  Logical; show the hex code alongside the name in the single-palette
  view (default `TRUE`).

## Value

Invisibly, the palette(s) drawn: a named colour vector for a single
palette, or a named list of them.

## See also

[`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md)
for the colours themselves,
[`energypal_info()`](https://optimal2050.github.io/energypal/reference/energypal_info.md)
for the list of palettes.

## Examples

``` r
energypal_show("carriers")


# Compare published schemes
energypal_show(c("carriers", "eia", "ipcc", "owid"))


# Everything the package ships
energypal_show(energypal_info()$name)
```
