# Orderings available for a palette

Lists the orderings that can be passed to `order` in
[`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md),
[`energypal_table()`](https://optimal2050.github.io/energypal/reference/energypal_table.md)
and the scale functions, together with the note and source recorded for
each.

## Usage

``` r
energypal_orders(palette = NULL, file = NULL)
```

## Arguments

- palette:

  Name of a built-in or registered palette. Defaults to the
  `energypal.palette` option, or `"carriers"`.

- file:

  Path to a palette file, taking precedence over `palette`.

## Value

A data frame with one row per available ordering and columns `order`,
`kind` (`"declared"`, `"property"` or `"computed"`), `n`, `note`,
`source` and `url`.

## Presentation only

Orderings arrange legends and chart series. They are **not** model
inputs. The sequences, and the numeric properties some of them derive
from, are indicative values chosen so that charts read sensibly; they
are not validated figures and must not be used in calculations. Every
declared ordering carries a note saying so, printed by this function.

## See also

[`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md),
[`energypal_table()`](https://optimal2050.github.io/energypal/reference/energypal_table.md)

## Examples

``` r
energypal_orders("carriers")
#>              order     kind  n
#> 1 carbon_intensity declared  9
#> 2  dispatchability declared 10
#> 3      merit_order declared  8
#> 4     renewability declared 10
#> 5             spec computed 93
#> 6            alpha computed 93
#> 7              hue computed 93
#> 8        lightness computed 93
#> 9           chroma computed 93
#>                                                                                                                                                                                                               note
#> 1 Presentation only. Orders chart series and legends; NOT a model input and not to be used in calculations. Lifecycle medians vary widely with fuel quality, plant vintage, capacity factor and system boundary.\n
#> 2                        Presentation only. Conventional order for drawing a generation stack, dispatchable first and variable last. Not an operational ranking; real flexibility is plant- and system-specific.\n
#> 3                     Presentation only. Indicative short-run marginal cost order for drawing dispatch stacks. Real merit order is system- and time-specific and must come from the model, never from this file.\n
#> 4                                                                       Presentation only. Groups by origin - fossil, then other non-renewable, then renewable - as most published energy-mix charts stack them.\n
#> 5                                                                                                                                                             Computed from the palette itself. Presentation only.
#> 6                                                                                                                                                             Computed from the palette itself. Presentation only.
#> 7                                                                                                                                                             Computed from the palette itself. Presentation only.
#> 8                                                                                                                                                             Computed from the palette itself. Presentation only.
#> 9                                                                                                                                                             Computed from the palette itself. Presentation only.
#>                                                         source
#> 1 IPCC AR5 WGIII, Annex III, Table A.III.2 (lifecycle medians)
#> 2        IEA World Energy Outlook generation-stack conventions
#> 3        Conventional dispatch-stack ordering; indicative only
#> 4                     IEA / IRENA energy-mix chart conventions
#> 5                                                         <NA>
#> 6                                                         <NA>
#> 7                                                         <NA>
#> 8                                                         <NA>
#> 9                                                         <NA>
#>                                                                          url
#> 1 https://www.ipcc.ch/site/assets/uploads/2018/02/ipcc_wg3_ar5_annex-iii.pdf
#> 2                                                                       <NA>
#> 3                                                                       <NA>
#> 4                                                                       <NA>
#> 5                                                                       <NA>
#> 6                                                                       <NA>
#> 7                                                                       <NA>
#> 8                                                                       <NA>
#> 9                                                                       <NA>

# the note travels with the ordering
energypal_orders("carriers")$note[1]
#> [1] "Presentation only. Orders chart series and legends; NOT a model input and not to be used in calculations. Lifecycle medians vary widely with fuel quality, plant vintage, capacity factor and system boundary.\n"
```
