## Colour gradients for repeated carriers
#
# When several series map to one carrier - COAL1, COAL2, COAL_OLD - they all get
# the same colour and become indistinguishable. This spreads them into shades of
# that carrier's colour, keeping the family recognisable.
#
# The spread is done in OKLAB, symmetrically around the base colour. The earlier
# implementation moved HSV `value` upward only, clamped at 1, so any bright
# carrier collapsed: Solar (#FFA500) and Nuclear (#FFD700) returned one colour
# for every requested variation, silently. Symmetry is what fixes it - there is
# always room in at least one direction.

# Usable OKLAB lightness range. Outside this, 8-bit sRGB rounding starts folding
# neighbouring values together.
.L_LO <- 0.04
.L_HI <- 0.98

# Smallest lightness step that survives the round trip to an 8-bit hex.
.L_STEP <- 0.015

# Place a window of the requested width around `centre`, then slide it - never
# squash it - so that it fits inside [lo, hi]. Sliding is what keeps a near-white
# or near-black base usable: clamping instead would fold the outer shades onto
# each other, which is the bug this replaces.
.fit_window <- function(centre, width, lo, hi) {
  width <- min(width, hi - lo)
  from <- centre - width / 2
  to <- centre + width / 2
  if (from < lo) { to <- to + (lo - from); from <- lo }
  if (to > hi)   { from <- from - (to - hi); to <- hi }
  c(max(from, lo), min(to, hi))
}

.shift_lightness <- function(lab, n, spread) {
  width <- max(2 * spread, (n - 1L) * .L_STEP)
  w <- .fit_window(lab[, 1], width, .L_LO, .L_HI)
  vapply(seq(w[1], w[2], length.out = n), function(l) {
    m <- lab
    m[, 1] <- l
    farver::encode_colour(m, from = "oklab")
  }, character(1))
}

.shift_chroma <- function(lab, n, spread) {
  # scale a and b together, which changes saturation and leaves hue alone
  factors <- seq(max(0.15, 1 - spread * 4), 1 + spread * 4, length.out = n)
  vapply(factors, function(f) {
    m <- lab
    m[, 2:3] <- m[, 2:3] * f
    farver::encode_colour(m, from = "oklab")
  }, character(1))
}

#' Shades of a single colour
#'
#' Produces `n` visually distinct shades of one colour, for when several data
#' series share a carrier and would otherwise be drawn identically.
#'
#' Shades are spread symmetrically around the base colour in OKLAB, a
#' perceptually uniform space, so a given `spread` looks like the same step
#' whether the colour is near-black coal or bright yellow nuclear. The base
#' colour is always among the results when `n` is odd.
#'
#' Hue is held fixed, which is what keeps the shades reading as one carrier.
#' Colours already close to the edge of the sRGB gamut are the exception: making
#' them lighter pushes them outside it, and the clip back into sRGB rotates the
#' hue slightly. Across the built-in palettes the typical rotation is under two
#' degrees, with pale saturated blues the worst at around thirty. Proper gamut
#' mapping is planned but not implemented.
#'
#' @param color A single colour, as hex or any name [grDevices::col2rgb()] accepts.
#' @param n Number of shades to return (default `3`).
#' @param spread How far to spread, roughly in OKLAB lightness units either side
#'   of the base (default `0.10`). Larger values are more distinguishable but
#'   drift further from the carrier's identity.
#' @param along What to vary: `"lightness"` (default) or `"chroma"`. Hue is
#'   never varied — it is what makes the colour recognisable as that carrier.
#'
#' @return A character vector of `n` hex colours, dark to light.
#' @examples
#' # bright colours no longer collapse
#' energypal_gradient("#FFD700", n = 5)   # nuclear yellow
#' energypal_gradient("#2C2C2C", n = 5)   # coal near-black
#'
#' # vary saturation instead
#' energypal_gradient("#4682B4", n = 3, along = "chroma")
#' @seealso [energypal_colors()] with `gradient = TRUE`, which applies this
#'   automatically to labels that share a carrier.
#' @export
energypal_gradient <- function(color, n = 3, spread = 0.10,
                               along = c("lightness", "chroma")) {
  along <- match.arg(along)
  if (length(color) != 1L || is.na(color)) {
    stop("`color` must be a single colour.", call. = FALSE)
  }
  if (!is.numeric(n) || length(n) != 1L || n < 1) {
    stop("`n` must be a single positive number.", call. = FALSE)
  }
  n <- as.integer(n)
  lab <- farver::decode_colour(color, to = "oklab")
  if (n == 1L) return(farver::encode_colour(lab, from = "oklab"))

  # Varying the chroma of a grey is meaningless - there is none to vary - so
  # fall back to lightness rather than returning n copies of the input.
  if (along == "chroma" && sqrt(sum(lab[, 2:3]^2)) < 1e-4) along <- "lightness"

  out <- switch(along,
    lightness = .shift_lightness(lab, n, spread),
    chroma = .shift_chroma(lab, n, spread)
  )

  # Chroma has no equivalent of the sliding window: a colour can run out of
  # saturation. Widening once is usually enough; failing that, fall back to
  # lightness, which can always separate n shades.
  if (anyDuplicated(out)) out <- .shift_chroma(lab, n, spread * 2)
  if (anyDuplicated(out)) out <- .shift_lightness(lab, n, spread)
  out
}

# Spread each group of labels sharing a carrier into shades of its colour.
# Grouping is by matched carrier id, not by hex: FossilCoal and OtherFossilCoal
# are both #2C2C2C but are different carriers and must not be merged.
.apply_gradient <- function(cols, matched, spread, along) {
  ok <- !is.na(matched)
  if (!any(ok)) return(cols)
  for (id in unique(matched[ok])) {
    idx <- which(matched == id & ok)
    if (length(idx) < 2L) next
    cols[idx] <- energypal_gradient(cols[idx][1], n = length(idx),
                                    spread = spread, along = along)
  }
  cols
}
