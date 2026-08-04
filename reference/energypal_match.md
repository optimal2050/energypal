# Match data labels to palette entries

Resolves the source labels found in real datasets to the canonical
entries of a palette, and reports how each was resolved. Use this when
you want to see or audit the mapping; use
[`energypal_colors()`](https://optimal2050.github.io/energypal/reference/energypal_colors.md)
when you just want the colours.

## Usage

``` r
energypal_match(
  sources,
  palette = NULL,
  file = NULL,
  method = "auto",
  case_sensitive = FALSE,
  max_distance = 0.4,
  warn = TRUE,
  include_full_palette = FALSE
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

- case_sensitive:

  Logical; if `TRUE` the exact stage respects case (default `FALSE`).
  Later stages are case-insensitive by construction.

- max_distance:

  Maximum normalised edit distance for the fuzzy stage, between 0 and 1
  (default `0.4`).

- warn:

  Logical; warn when a label matches entries of differing colours
  (default `TRUE`).

- include_full_palette:

  Logical; append palette entries that nothing in `sources` matched
  (default `FALSE`).

## Value

A data frame with one row per distinct source and columns `original`,
`matched` (entry name, or `NA`), `color`, `method` (which stage resolved
it) and `candidates` (`;`-separated, when the match was ambiguous).

## Details

Matching proceeds in stages and stops at the first that succeeds for a
given label: exact, canonicalised (case, spacing, punctuation and digits
removed), declared alias, fuzzy (string distance), and finally
containment, which catches labels like `"Coal_Plant_2"`.

Aliases are declared in the palette file, so a project that supplies its
own palette can teach the matcher its own vocabulary without any code.

## See also

[`energypal_colors()`](https://optimal2050.github.io/energypal/reference/energypal_colors.md)
for colours directly,
[`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md)
for the palette.

## Examples

``` r
energypal_match(c("Coal", "natural gas", "Solar PV", "COAL1"))
#>      original    matched   color    method candidates
#> 1        Coal FossilCoal #2C2C2C     alias       <NA>
#> 2 natural gas NaturalGas #4682B4 canonical       <NA>
#> 3    Solar PV    SolarPV #FFA500 canonical       <NA>
#> 4       COAL1 FossilCoal #2C2C2C     alias       <NA>

# every label the bundled dataset uses resolves
energypal_match(unique(owid_energy_mix$source))
#>      original    matched   color    method candidates
#> 1   Bioenergy  Bioenergy #228B22     exact       <NA>
#> 2        Coal FossilCoal #2C2C2C     alias       <NA>
#> 3       Hydro      Hydro #0080FF     exact       <NA>
#> 4 Natural Gas NaturalGas #4682B4 canonical       <NA>
#> 5     Nuclear    Nuclear #FFD700     exact       <NA>
#> 6         Oil  FossilOil #8B4513     alias       <NA>
#> 7       Solar      Solar #FFA500     exact       <NA>
#> 8        Wind       Wind #87CEEB     exact       <NA>
#> 9       Other      Other #C0C0C0     exact       <NA>

# restrict to strict matching only
energypal_match(c("Coal", "nat gas"), method = c("exact", "canonical"))
#>   original matched color method candidates
#> 1     Coal    <NA>  <NA>   <NA>       <NA>
#> 2  nat gas    <NA>  <NA>   <NA>       <NA>
```
