# Colours for a vector of data labels

Maps the source labels in your data straight to colours, resolving them
against a palette with
[`energypal_match()`](https://optimal2050.github.io/energypal/reference/energypal_match.md).
Labels that cannot be resolved get `unmapped_color`.

## Usage

``` r
energypal_colors(
  sources,
  palette = NULL,
  file = NULL,
  method = "auto",
  unmapped_color = "#999999",
  case_sensitive = FALSE,
  max_distance = 0.4,
  warn = TRUE,
  gradient = FALSE,
  spread = 0.1,
  along = c("lightness", "chroma")
)

energypal_colours(
  sources,
  palette = NULL,
  file = NULL,
  method = "auto",
  unmapped_color = "#999999",
  case_sensitive = FALSE,
  max_distance = 0.4,
  warn = TRUE,
  gradient = FALSE,
  spread = 0.1,
  along = c("lightness", "chroma")
)
```

## Arguments

- sources:

  Character vector of labels from your data. Repeats are allowed; the
  result has one row per distinct label.

- palette:

  Name of a built-in or registered palette. Defaults to the
  `energypal.palette` option, or `"carriers"`.

- file:

  Path to a palette file, taking precedence over `palette`.

- method:

  Stages to apply, in order. `"auto"` (default) uses all of them;
  otherwise any of `"exact"`, `"canonical"`, `"alias"`, `"fuzzy"`,
  `"contains"`.

- unmapped_color:

  Colour for labels that no stage could resolve (default `"#999999"`).

- case_sensitive:

  Logical; if `TRUE` the exact stage respects case (default `FALSE`).
  Later stages are case-insensitive by construction.

- max_distance:

  Maximum normalised edit distance for the fuzzy stage, between 0 and 1
  (default `0.4`).

- warn:

  Logical; warn when a label matches entries of differing colours
  (default `TRUE`).

- gradient:

  Logical; when several labels resolve to the *same* carrier, spread
  them into distinct shades of that carrier's colour instead of drawing
  them identically (default `FALSE`). Grouping is by resolved carrier,
  not by colour, so two carriers that happen to share a hex stay
  separate.

- spread, along:

  Passed to
  [`energypal_gradient()`](https://optimal2050.github.io/energypal/reference/energypal_gradient.md)
  when `gradient = TRUE`.

## Value

A character vector of colours, the same length and order as `sources`,
named by the input labels.

## See also

[`energypal_match()`](https://optimal2050.github.io/energypal/reference/energypal_match.md)
to see how each label was resolved,
[`energypal_gradient()`](https://optimal2050.github.io/energypal/reference/energypal_gradient.md)
for the shading itself,
[`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md)
for the palette.

## Examples

``` r
energypal_colors(c("Coal", "Natural Gas", "Solar", "Wind"))
#>        Coal Natural Gas       Solar        Wind 
#>   "#2C2C2C"   "#4682B4"   "#FFA500"   "#87CEEB" 

# messy labels resolve too
energypal_colors(c("coal power", "nat gas", "solar pv", "COAL1"))
#> coal power    nat gas   solar pv      COAL1 
#>  "#2C2C2C"  "#4682B4"  "#FFA500"  "#2C2C2C" 

# a different published palette, same labels
energypal_colors(c("Coal", "Natural Gas"), palette = "ipcc")
#>        Coal Natural Gas 
#>   "#2E2E2E"   "#1E90FF" 

# several series per carrier: three coal shades, one solar
energypal_colors(c("COAL1", "COAL2", "COAL3", "SOLAR_NY"), gradient = TRUE)
#>     COAL1     COAL2     COAL3  SOLAR_NY 
#> "#141414" "#2C2C2C" "#464646" "#FFA500" 

# anything unresolved is visibly grey rather than silently wrong
energypal_colors(c("Coal", "Flux Capacitor"))
#>           Coal Flux Capacitor 
#>      "#2C2C2C"      "#999999" 
```
