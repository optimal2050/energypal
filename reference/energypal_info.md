# Available energy palettes

Lists the palettes that can be passed to
[`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md),
`palette =` arguments and the scale functions: the ones shipped with the
package plus any registered in this session with
[`energypal_register()`](https://optimal2050.github.io/energypal/reference/energypal_register.md).

## Usage

``` r
energypal_info(family = NULL)
```

## Arguments

- family:

  Optional family name; return only that family's members.

## Value

A data frame with one row per palette and columns `name`, `title`,
`source`, `family`, `measure`, `default`, `type` (`"discrete"` or
`"continuous"`), `n` (number of colours), `nested` (whether the palette
has a hierarchy), `breaks`, `unit` and `builtin`.

Every colour `n` counts is one the palette file declares itself. A
palette that `extends` another inherits its taxonomy — names, labels,
aliases, hierarchy, orderings — but never its colours.

## Details

This is a function rather than a stored data frame (unlike
[`RColorBrewer::brewer.pal.info`](https://rdrr.io/pkg/RColorBrewer/man/ColorBrewer.html))
so that registered palettes appear in it and so it cannot fall out of
step with the files on disk.

## Families

An atlas publishes several quantities and styles each differently, so
its scales ship as separate palettes grouped by `family` and
distinguished by `measure` — `windatlas_speed`, `windatlas_density` and
so on. They are not interchangeable. One member of each family is its
default, so the bare family name (`"windatlas"`) resolves to the most
common measure.

## See also

[`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md)
to retrieve a palette,
[`energypal_register()`](https://optimal2050.github.io/energypal/reference/energypal_register.md)
to add one.

## Examples

``` r
energypal_info()
#>               name                                             title
#> 1         carriers                                   Energy carriers
#> 2              eia         EIA Annual Energy Outlook (approximation)
#> 3              epa      EPA greenhouse gas inventory (approximation)
#> 4             ipcc      IPCC AR6 WGIII energy supply (approximation)
#> 5             owid      Our World in Data energy mix (approximation)
#> 6   solaratlas_ghi                            Global Solar Atlas GHI
#> 7 solaratlas_pvout                      Global Solar Atlas PV output
#> 8     technologies                   Energy technologies and sectors
#> 9  windatlas_speed Global Wind Atlas mean wind speed (approximation)
#>                                                                                                                                                                                                                                                                                              source
#> 1                                                                                                                                                                                                                              IPCC 2006 Guidelines, IEA World Energy Balances, EIA fuel categories
#> 2                                                                                                                                                                                                                          EIA Annual Energy Outlook 2023, Fig. ES-1 "Energy consumption by source"
#> 3                                                                                                                                                                                              EPA Inventory of U.S. Greenhouse Gas Emissions and Sinks, Ch. 2 "Trends in Greenhouse Gas Emissions"
#> 4                                                                                                                                                                                                                      IPCC AR6 WGIII, Chapter 3, Fig. 3.8 "Energy Supply in Illustrative Pathways"
#> 5                                                                                                                                                                                                                                                Our World in Data, "Energy Mix" interactive charts
#> 6                                                                                                                                                                                                              Global Solar Atlas 2.0 world GHI poster map (World_GHI_poster-map_1500x800mm-300dpi)
#> 7                                                                                                                                                                                                          Global Solar Atlas 2.0 world PVOUT poster map (World_PVOUT_poster-map_1500x800mm-300dpi)
#> 8                                                                                                                                                                                                                           IEA Energy Technology Perspectives, IPCC 2006 Guidelines (Vol.2 Energy)
#> 9 Approximation. Derived from an earlier version of the Global Wind Atlas for the merra2ools package (c. 2020); values recovered by sampling that package's figure legend, the defining object (palette.windatlas) having been lost. Atlas version unconfirmed and not verified against GWA 3 or 4.
#>       family measure default       type  n nested breaks      unit builtin
#> 1       <NA>    <NA>   FALSE   discrete 93   TRUE      0      <NA>    TRUE
#> 2       <NA>    <NA>   FALSE   discrete 12   TRUE      0      <NA>    TRUE
#> 3       <NA>    <NA>   FALSE   discrete 12   TRUE      0      <NA>    TRUE
#> 4       <NA>    <NA>   FALSE   discrete 11   TRUE      0      <NA>    TRUE
#> 5       <NA>    <NA>   FALSE   discrete 12   TRUE      0      <NA>    TRUE
#> 6 solaratlas     ghi    TRUE continuous 28  FALSE     27 kWh/m2/yr    TRUE
#> 7 solaratlas   pvout   FALSE continuous 24  FALSE     23   kWh/kWp    TRUE
#> 8       <NA>    <NA>   FALSE   discrete 80   TRUE      0      <NA>    TRUE
#> 9  windatlas   speed    TRUE continuous 31  FALSE     30       m/s    TRUE

# what a family offers
energypal_info(family = "windatlas")
#>              name                                             title
#> 1 windatlas_speed Global Wind Atlas mean wind speed (approximation)
#>                                                                                                                                                                                                                                                                                              source
#> 1 Approximation. Derived from an earlier version of the Global Wind Atlas for the merra2ools package (c. 2020); values recovered by sampling that package's figure legend, the defining object (palette.windatlas) having been lost. Atlas version unconfirmed and not verified against GWA 3 or 4.
#>      family measure default       type  n nested breaks unit builtin
#> 1 windatlas   speed    TRUE continuous 31  FALSE     30  m/s    TRUE

# just the continuous palettes
i <- energypal_info()
i[i$type == "continuous", c("name", "measure", "unit")]
#>               name measure      unit
#> 6   solaratlas_ghi     ghi kWh/m2/yr
#> 7 solaratlas_pvout   pvout   kWh/kWp
#> 9  windatlas_speed   speed       m/s
```
