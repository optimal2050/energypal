test_that("no colour in any palette collapses, at any n", {
  # The regression this replaces: the old HSV implementation moved lightness
  # upward only and clamped at 1, so Solar (#FFA500) and Nuclear (#FFD700)
  # returned a single colour for every requested variation, silently.
  info <- energypal_info()
  for (p in info$name) {
    cols <- unique(energypal(p, include_groups = TRUE, include_subtypes = TRUE))
    for (cl in cols) {
      for (k in c(2, 3, 5, 7)) {
        got <- energypal_gradient(cl, n = k)
        expect_length(unique(got), k)
      }
    }
  }
})

test_that("the two colours that used to collapse now separate", {
  for (cl in c("#FFA500", "#FFD700")) {          # solar, nuclear
    expect_length(unique(energypal_gradient(cl, n = 5)), 5)
  }
})

test_that("shades are ordered and include the base when n is odd", {
  g <- energypal_gradient("#4682B4", n = 5)
  expect_identical(g[3], "#4682B4")              # centred on the base

  lum <- farver::decode_colour(g, to = "oklab")[, 1]
  expect_identical(order(lum), seq_along(lum))   # dark to light
})

test_that("extremes slide the window instead of clamping", {
  # A near-white base must not produce black, and a near-black base must not
  # produce white; both must still give n distinct shades.
  white <- energypal_gradient("#FEFEFE", n = 4)
  black <- energypal_gradient("#010101", n = 4)
  expect_length(unique(white), 4)
  expect_length(unique(black), 4)

  wl <- farver::decode_colour(white, to = "oklab")[, 1]
  bl <- farver::decode_colour(black, to = "oklab")[, 1]
  expect_true(all(wl > 0.5), info = "near-white stayed light")
  expect_true(all(bl < 0.5), info = "near-black stayed dark")
})

test_that("hue is essentially preserved - the carrier stays recognisable", {
  # Only lightness is varied, so hue is preserved by construction. In practice
  # sRGB gamut clipping rotates it a little for colours near the gamut boundary:
  # lightening #FFA500 pushes it out, and the clip trims `a`. Measured across
  # every colour in every *discrete* palette the median drift is ~1.6 degrees and
  # the worst (pale saturated blues) is ~33. Both bounds are asserted so a
  # regression that made drift typical, rather than exceptional, would fail.
  #
  # Continuous palettes are excluded because gradients never apply to them: a
  # gradient distinguishes repeated instances of one carrier, and a resource ramp
  # has no carriers. Their pale near-neutral bins have unstable hue by nature and
  # would only add noise to this bound.
  hue_drift <- function(cl, n = 5) {
    lab <- farver::decode_colour(energypal_gradient(cl, n = n), to = "oklab")
    if (any(sqrt(lab[, 2]^2 + lab[, 3]^2) < 0.01)) return(NA_real_)
    diff(range(atan2(lab[, 3], lab[, 2])))
  }

  info <- energypal_info()
  discrete <- info$name[info$builtin & info$type == "discrete"]
  cols <- unique(unlist(lapply(discrete, function(p)
    energypal(p, include_groups = TRUE, include_subtypes = TRUE))))
  d <- vapply(cols, hue_drift, numeric(1))
  d <- d[!is.na(d)]

  expect_gt(length(d), 100)
  expect_lt(stats::median(d), 0.10)   # typical case: under 6 degrees
  expect_lt(max(d), 0.65)             # worst case: under 37 degrees
})

test_that("chroma mode varies saturation, not lightness", {
  g <- energypal_gradient("#4682B4", n = 5, along = "chroma")
  expect_length(unique(g), 5)
  hcl <- farver::decode_colour(g, to = "hcl")
  expect_lt(diff(range(hcl[, "l"])), 6)          # lightness roughly held
  expect_gt(diff(range(hcl[, "c"])), 10)         # chroma actually moves
})

test_that("chroma of a grey falls back to lightness rather than repeating", {
  g <- energypal_gradient("#808080", n = 4, along = "chroma")
  expect_length(unique(g), 4)
})

test_that("n = 1 returns the base colour", {
  expect_identical(energypal_gradient("#4682B4", n = 1), "#4682B4")
})

test_that("bad input is refused", {
  expect_error(energypal_gradient(c("#000000", "#FFFFFF")), "single colour")
  expect_error(energypal_gradient("#4682B4", n = 0), "positive")
  expect_error(energypal_gradient("#4682B4", n = -1), "positive")
})

test_that("energypal_colors(gradient = TRUE) shades repeated carriers", {
  got <- energypal_colors(c("COAL1", "COAL2", "COAL3", "SOLAR_NY"), gradient = TRUE)
  expect_length(got, 4)
  expect_length(unique(got[1:3]), 3)             # three distinct coal shades
  expect_identical(unname(got[4]), "#FFA500")    # solar untouched, only one label
})

test_that("gradient groups by carrier, not by colour", {
  # FossilCoal and OtherFossilCoal are both #2C2C2C but are different carriers,
  # so one label each means no shading is applied to either.
  got <- energypal_colors(c("FossilCoal", "OtherFossilCoal"), gradient = TRUE, warn = FALSE)
  expect_identical(unname(got), c("#2C2C2C", "#2C2C2C"))
})

test_that("gradient leaves unresolved labels alone", {
  got <- energypal_colors(c("COAL1", "COAL2", "Flux Capacitor", "Warp Core"),
                       gradient = TRUE, warn = FALSE)
  expect_length(unique(got[1:2]), 2)
  expect_identical(unname(got[3:4]), c("#999999", "#999999"))
})

test_that("gradient = FALSE is the default and changes nothing", {
  labs <- c("COAL1", "COAL2", "COAL3")
  plain <- energypal_colors(labs)
  expect_length(unique(plain), 1)
  expect_identical(plain, energypal_colors(labs, gradient = FALSE))
})
