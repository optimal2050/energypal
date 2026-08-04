# Shades of a single colour

Produces `n` visually distinct shades of one colour, for when several
data series share a carrier and would otherwise be drawn identically.

## Usage

``` r
energypal_gradient(
  color,
  n = 3,
  spread = 0.1,
  along = c("lightness", "chroma")
)
```

## Arguments

- color:

  A single colour, as hex or any name
  [`grDevices::col2rgb()`](https://rdrr.io/r/grDevices/col2rgb.html)
  accepts.

- n:

  Number of shades to return (default `3`).

- spread:

  How far to spread, roughly in OKLAB lightness units either side of the
  base (default `0.10`). Larger values are more distinguishable but
  drift further from the carrier's identity.

- along:

  What to vary: `"lightness"` (default) or `"chroma"`. Hue is never
  varied — it is what makes the colour recognisable as that carrier.

## Value

A character vector of `n` hex colours, dark to light.

## Details

Shades are spread symmetrically around the base colour in OKLAB, a
perceptually uniform space, so a given `spread` looks like the same step
whether the colour is near-black coal or bright yellow nuclear. The base
colour is always among the results when `n` is odd.

Hue is held fixed, which is what keeps the shades reading as one
carrier. Colours already close to the edge of the sRGB gamut are the
exception: making them lighter pushes them outside it, and the clip back
into sRGB rotates the hue slightly. Across the built-in palettes the
typical rotation is under two degrees, with pale saturated blues the
worst at around thirty. Proper gamut mapping is planned but not
implemented.

## See also

[`energypal_colors()`](https://optimal2050.github.io/energypal/reference/energypal_colors.md)
with `gradient = TRUE`, which applies this automatically to labels that
share a carrier.

## Examples

``` r
# bright colours no longer collapse
energypal_gradient("#FFD700", n = 5)   # nuclear yellow
#> [1] "#DCB400" "#ECC400" "#FDD500" "#FFE52E" "#FFF648"
energypal_gradient("#2C2C2C", n = 5)   # coal near-black
#> [1] "#141414" "#202020" "#2C2C2C" "#393939" "#464646"

# vary saturation instead
energypal_gradient("#4682B4", n = 3, along = "chroma")
#> [1] "#5F819E" "#4682B4" "#1E82C9"
```
