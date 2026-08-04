# OWID Electricity Generation Mix (Curated Subset)

A curated subset of the Our World in Data (OWID) energy dataset
containing recent electricity generation shares by source for a
selection of major economies. This dataset is included in a reduced form
suitable for examples and lightweight plotting while reflecting
real-world proportions.

## Usage

``` r
owid_energy_mix
```

## Format

A data frame with rows = country \* source \* year (filtered years) and
the following columns:

- country:

  Country name (character)

- iso_code:

  3-letter ISO country code

- year:

  Calendar year (integer)

- source:

  Standardized energy source (character; e.g. Coal, Natural Gas, Wind,
  Solar)

- generation_twh:

  Electricity generation for the source in TWh (numeric)

- percentage:

  Share of total national generation for the year (0-100, numeric)

- carbon_intensity_gco2_kwh:

  Grid carbon intensity (gCO2 per kWh) if available (numeric, may
  contain NA)

## Source

Our World in Data (OWID) Global Energy dataset, CC-BY 4.0.

## Details

The full OWID energy dataset is large and updated frequently, so only
this curated subset ships with the package.
`data-raw/fetch_owid_energy.R` downloads the complete current CSV if you
need it.

Sources are standardized to the energypal canonical set to ensure
palette alignment. Minor or residual categories are mapped to 'Other' or
excluded if below inclusion thresholds during curation.

Countries currently included (subject to change as long as CRAN size
limits are respected): United States, China, India, Germany, France,
Brazil, Australia.

Years: Most recent 1–3 complete years available at curation time (see
`attr(owid_energy_mix, "metadata")` for snapshot information).

## Licensing & Attribution

Data source: Our World in Data – Global Energy dataset
(https://github.com/owid/energy-data), licensed under CC-BY 4.0. Please
cite OWID when using this derived subset in publications.

## Reproducibility

The dataset is generated via a data-raw script:
`data-raw/prepare_owid_energy_mix.R`. Run that script to refresh and
regenerate this subset; then re-document and rebuild the package.

## Examples

``` r
data(owid_energy_mix)
head(owid_energy_mix)
#> # A tibble: 6 × 7
#>   country iso_code  year source generation_twh percentage carbon_intensity_gco…¹
#>   <chr>   <chr>    <int> <chr>           <dbl>      <dbl>                  <dbl>
#> 1 Austra… AUS       2000 Bioen…          0.889       0.41                   806.
#> 2 Austra… AUS       2000 Coal          180.         83.1                    806.
#> 3 Austra… AUS       2000 Hydro          16.5         7.60                   806.
#> 4 Austra… AUS       2000 Natur…         16.8         7.73                   806.
#> 5 Austra… AUS       2000 Nucle…          0           0                      806.
#> 6 Austra… AUS       2000 Oil             2.27        1.05                   806.
#> # ℹ abbreviated name: ¹​carbon_intensity_gco2_kwh
unique(owid_energy_mix$source)
#> [1] "Bioenergy"   "Coal"        "Hydro"       "Natural Gas" "Nuclear"    
#> [6] "Oil"         "Solar"       "Wind"        "Other"      

# Snapshot provenance travels with the data
str(attr(owid_energy_mix, "metadata"))
#> List of 5
#>  $ snapshot_date: Date[1:1], format: "2025-09-14"
#>  $ source_url   : chr "https://raw.githubusercontent.com/owid/energy-data/master/owid-energy-data.csv"
#>  $ countries    : chr [1:7] "United States" "China" "India" "Germany" ...
#>  $ years        : int [1:25] 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 ...
#>  $ license      : chr "CC-BY 4.0"
```
