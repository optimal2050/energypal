cont_pals <- {
  i <- energypal_info()
  i$name[i$builtin & i$type == "continuous"]
}

test_that("the resource palettes are recognised as continuous", {
  expect_setequal(cont_pals, c("windatlas_speed", "solaratlas_ghi",
                               "solaratlas_pvout"))
  for (nm in cont_pals) {
    expect_identical(.palette_type(energypal_spec(nm)), "continuous")
  }
})

test_that("n interpolates along a continuous palette rather than truncating", {
  stops <- energypal("windatlas_speed")
  expect_length(stops, 31)

  expect_length(energypal("windatlas_speed", n = 5), 5)
  expect_length(energypal("windatlas_speed", n = 50), 50)   # more than the stops

  # endpoints are preserved by interpolation
  for (k in c(2, 5, 50)) {
    got <- energypal("windatlas_speed", n = k)
    expect_identical(got[1], stops[1])
    expect_identical(got[k], stops[length(stops)])
  }
  # and it is not a head()
  expect_false(identical(energypal("windatlas_speed", n = 5), stops[1:5]))
})

test_that("continuous palettes return unnamed colours, like viridis(n)", {
  for (nm in cont_pals) {
    expect_null(names(energypal(nm)))
    expect_null(names(energypal(nm, n = 10)))
  }
})

test_that("direction reverses a continuous ramp", {
  for (nm in cont_pals) {
    expect_identical(rev(energypal(nm)), energypal(nm, direction = -1))
  }
})

test_that("declared breaks are monotonic and one fewer than the stops", {
  for (nm in cont_pals) {
    spec <- energypal_spec(nm)
    brk <- as.numeric(unlist(spec$breaks))
    stops <- energypal(nm)
    expect_gt(length(brk), 0)
    expect_identical(brk, sort(brk), info = nm)
    expect_false(anyDuplicated(brk) > 0, info = nm)
    # n bins from n-1 internal breaks
    expect_identical(length(stops), length(brk) + 1L, info = nm)
  }
})

test_that("the table view of a continuous palette describes its bins", {
  tab <- energypal_table("windatlas_speed")
  n <- nrow(tab)
  expect_identical(n, length(energypal("windatlas_speed")))
  expect_true(all(c("position", "color", "break_min", "break_max") %in% names(tab)))
  expect_true(is.na(tab$break_min[1]))            # open below
  expect_true(is.na(tab$break_max[n]))            # open above
  # each bin's upper bound is the next bin's lower bound
  expect_identical(tab$break_max[-n], tab$break_min[-1])
})

test_that("every stop is a valid hex colour", {
  for (nm in cont_pals) {
    expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", energypal(nm))), info = nm)
  }
})

test_that("wind and solar are different palettes, not one reused", {
  w <- energypal("windatlas_speed")
  s <- energypal("solaratlas_ghi")
  expect_false(identical(length(w), length(s)))
  # resampled to a common length, they still share no colour position-for-position
  wn <- energypal("windatlas_speed", n = 20)
  sn <- energypal("solaratlas_ghi", n = 20)
  expect_equal(sum(wn == sn), 0)
})

test_that("continuous palettes carry a unit and honest provenance", {
  info <- energypal_info()
  for (nm in cont_pals) {
    row <- info[info$name == nm, ]
    expect_false(is.na(row$unit))
    expect_false(is.na(row$source))
  }
})

test_that("the atlas palettes carry the citation their licence requires", {
  # Both atlases publish under CC BY, and the GWA terms add a binding condition
  # naming the World Bank and ESMAP. Extracting their scales is only permitted
  # with that citation attached, so it must travel with the palette.
  for (nm in c("windatlas_speed", "solaratlas_ghi", "solaratlas_pvout")) {
    m <- energypal_spec(nm)$meta
    expect_match(m$license, "CC BY", info = nm)
    expect_true(nzchar(m$attribution %||% ""), info = nm)
    # the licence asks for a URI to itself, not just its name
    expect_match(m$license, "https://creativecommons.org/licenses/", info = nm)
  }
  expect_match(energypal_spec("windatlas_speed")$meta$attribution, "World Bank")
  expect_match(energypal_spec("windatlas_speed")$meta$attribution, "ESMAP")

  # the wind scale states plainly that it approximates the atlas
  expect_match(energypal_spec("windatlas_speed")$meta$source, "Approximation")
  expect_match(energypal_spec("windatlas_speed")$meta$source, "unconfirmed")
  expect_match(energypal_spec("windatlas_speed")$meta$title, "approximation")
})

test_that("meta$type is validated", {
  bad <- list(meta = list(name = "x", type = "sequential"),
              colors = list("#000000"))
  expect_error(.palette_type(bad), "discrete.*continuous")
})

test_that("an unnamed colors block implies continuous without declaring it", {
  f <- tempfile(fileext = ".yml")
  writeLines(c("meta:", "  name: implied", "colors:",
               '  - "#000000"', '  - "#FFFFFF"'), f)
  expect_identical(.palette_type(energypal_spec(file = f)), "continuous")
  expect_length(energypal(file = f, n = 3), 3)
})

test_that("continuous palettes are drawn as a ramp", {
  p <- tempfile(fileext = ".png")
  grDevices::png(p, width = 600, height = 300)
  on.exit({ grDevices::dev.off(); unlink(p) }, add = TRUE)
  out <- energypal_show("windatlas_speed")
  expect_length(out, length(energypal("windatlas_speed")))
})
