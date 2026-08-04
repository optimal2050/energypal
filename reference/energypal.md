# Energy colour palette

Returns a named vector of colours from a palette, in the style of
[`RColorBrewer::brewer.pal()`](https://rdrr.io/pkg/RColorBrewer/man/ColorBrewer.html).
The first argument selects the palette by name;
[`energypal_info()`](https://optimal2050.github.io/energypal/reference/energypal_info.md)
lists what is available.

## Usage

``` r
energypal(
  palette = NULL,
  n = NULL,
  file = NULL,
  order = NULL,
  direction = 1,
  include_groups = FALSE,
  include_carriers = TRUE,
  include_subtypes = FALSE,
  label_style = c("id", "short", "long", "default"),
  drop_na_colors = TRUE,
  unique_names = TRUE
)
```

## Arguments

- palette:

  Name of a built-in or registered palette. Defaults to the
  `energypal.palette` option, or `"carriers"`.

- n:

  Number of colours to return. `NULL` (default) returns all of them;
  otherwise the first `n`, and it is an error to ask for more than the
  palette holds.

- file:

  Path to a palette file, taking precedence over `palette`.

- order:

  How to sequence the colours. `NULL` or `"spec"` keeps file order;
  otherwise the name of an ordering declared in the palette
  (`"carbon_intensity"`, `"dispatchability"`, `"merit_order"`,
  `"renewability"`), the name of a numeric property (sorted descending),
  one of the computed orderings `"alpha"`, `"hue"`, `"lightness"`,
  `"chroma"`, or an explicit character vector of entry names. See
  [`energypal_orders()`](https://optimal2050.github.io/energypal/reference/energypal_orders.md).

  **Presentation only.** Orderings, and the numeric properties behind
  them, exist to arrange legends and chart series. They are indicative
  values, not validated figures, and must not be used in calculations.

- direction:

  `1` (default) or `-1` to reverse the chosen order.

- include_groups:

  Logical; include aggregate group entries such as `FossilFuels`
  (default `FALSE`).

- include_carriers:

  Logical; include carrier or technology entries — the main level of the
  palette (default `TRUE`).

- include_subtypes:

  Logical; include subtype entries such as `Anthracite` (default
  `FALSE`).

- label_style:

  How to name the returned vector: `"id"` (canonical identifier, the
  default), `"short"`, `"long"`, or `"default"` (long if present, else
  short, else id).

- drop_na_colors:

  Logical; drop entries with no colour (default `TRUE`).

- unique_names:

  Logical; make the returned names unique by appending a numeric suffix
  to duplicates (default `TRUE`).

## Value

A named character vector of hex colours.

## Details

By default you get the palette's main level only — the carriers or
technologies themselves, 17 of them for `"carriers"`. The aggregate
groups above them (`FossilFuels`, `Renewable`) and the subtypes below
(`Anthracite`, `Lignite`) are available through `include_groups` and
`include_subtypes`, but are off by default because a plotting palette
wants distinct colours, and adjacent subtypes are deliberately
near-identical.

Palettes are plain YAML files, so a project can supply its own via
`file =` or
[`energypal_register()`](https://optimal2050.github.io/energypal/reference/energypal_register.md)
and use it everywhere a built-in name works.

## See also

[`energypal_info()`](https://optimal2050.github.io/energypal/reference/energypal_info.md)
to list the available palettes,
[`energypal_table()`](https://optimal2050.github.io/energypal/reference/energypal_table.md)
for the underlying table, and
[`energypal_colors()`](https://optimal2050.github.io/energypal/reference/energypal_colors.md)
to map data labels to colours.

## Examples

``` r
# The default carrier palette: 17 colours, one per carrier
energypal()
#>          FossilCoal           FossilOil           FossilGas           Bioenergy 
#>           "#2C2C2C"           "#8B4513"           "#4682B4"           "#228B22" 
#>               Hydro                Wind               Solar          Geothermal 
#>           "#0080FF"           "#87CEEB"           "#FFA500"           "#CD853F" 
#>     OtherRenewables             Nuclear         Electricity                Heat 
#>           "#32CD32"           "#FFD700"           "#1F4BA8"           "#CC5500" 
#>            Hydrogen HydrogenDerivatives      SyntheticFuels             Storage 
#>           "#00B5E2"           "#008FB4"           "#B5651D"           "#9370DB" 
#>               Other 
#>           "#C0C0C0" 

# A published report's colours, same identifiers
energypal("ipcc")
#>           FossilCoal            FossilOil            FossilGas 
#>            "#2E2E2E"            "#8B4000"            "#1E90FF" 
#>            Bioenergy              Nuclear        FossilCoalCCS 
#>            "#006400"            "#FFD700"            "#4D4D4D" 
#>         FossilOilCCS         FossilGasCCS         BioenergyCCS 
#>            "#A05A2C"            "#4682B4"            "#228B22" 
#> NonBiomassRenewables 
#>            "#98FB98" 

# Brewer-style: just the first few
energypal("eia", n = 5)
#> FossilCoal  FossilOil  FossilGas  Bioenergy      Hydro 
#>  "#3C3C3C"  "#8B4513"  "#6495ED"  "#90EE90"  "#00CED1" 

# Readable names for legends
energypal("carriers", label_style = "long")
#>                 Coal                  Oil          Natural Gas 
#>            "#2C2C2C"            "#8B4513"            "#4682B4" 
#>            Bioenergy  Hydroelectric Power                 Wind 
#>            "#228B22"            "#0080FF"            "#87CEEB" 
#>                Solar           Geothermal     Other Renewables 
#>            "#FFA500"            "#CD853F"            "#32CD32" 
#>              Nuclear          Electricity                 Heat 
#>            "#FFD700"            "#1F4BA8"            "#CC5500" 
#>             Hydrogen Hydrogen Derivatives      Synthetic Fuels 
#>            "#00B5E2"            "#008FB4"            "#B5651D" 
#>       Energy Storage                Other 
#>            "#9370DB"            "#C0C0C0" 

# The full hierarchy, groups and fuel subtypes included
length(energypal("carriers", include_groups = TRUE, include_subtypes = TRUE))
#> [1] 93

# What is available
energypal_info()$name
#> [1] "carriers"         "eia"              "epa"              "ipcc"            
#> [5] "owid"             "solaratlas_ghi"   "solaratlas_pvout" "technologies"    
#> [9] "windatlas_speed" 
```
