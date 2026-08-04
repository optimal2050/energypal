# Plotting functions are exercised for "does it run and return the right thing"
# rather than for appearance. Output goes to a throwaway device.

with_null_device <- function(code) {
  f <- tempfile(fileext = ".png")
  grDevices::png(f, width = 600, height = 600)
  on.exit({
    grDevices::dev.off()
    unlink(f)
  }, add = TRUE)
  force(code)
}

test_that("a single palette plots and returns exactly what it drew", {
  with_null_device({
    out <- energypal_show("carriers")
    # display defaults to readable labels, unlike energypal()'s canonical ids
    expect_identical(out, energypal("carriers", label_style = "default"))
    expect_identical(unname(out), unname(energypal("carriers")))
  })
})

test_that("several palettes plot and return a named list", {
  with_null_device({
    out <- energypal_show(c("carriers", "ipcc"))
    expect_type(out, "list")
    expect_named(out, c("carriers", "ipcc"))
    # the comparison view keys on canonical ids, not on each source's wording,
    # or the same carrier would land in a different column per palette
    expect_identical(out$ipcc, energypal("ipcc", label_style = "id"))
  })
})

test_that("several continuous palettes draw as stacked ramps", {
  with_null_device({
    cont <- energypal_info()
    cont <- cont$name[cont$builtin & cont$type == "continuous"]
    expect_gt(length(cont), 1)
    out <- energypal_show(cont)
    expect_named(out, cont)
    # ramps are unnamed stop vectors, not entry maps
    for (nm in cont) expect_null(names(out[[nm]]))
  })
})

test_that("a continuous palette drawn beside discrete ones spans its row", {
  # it used to contribute no entries and render as a blank line
  with_null_device({
    out <- energypal_show(c("carriers", "windatlas_speed"))
    expect_named(out, c("carriers", "windatlas_speed"))
    expect_length(out$windatlas_speed, length(energypal("windatlas_speed")))
  })
})

test_that("the comparison view aligns the same carrier across palettes", {
  with_null_device({
    out <- energypal_show(c("carriers", "eia", "owid"), label_style = "default")
    # EIA calls it Petroleum, OWID calls it Oil - same entry either way
    for (p in names(out)) expect_true("FossilOil" %in% names(out[[p]]), info = p)

    # ...and the axis labels come from the first palette that defines each id
    labs <- energypal:::.common_labels(c("carriers", "eia"), "default")
    expect_identical(unname(labs[["FossilOil"]]), "Oil")          # carriers wins
    # an entry only EPA has still gets a label, from EPA
    labs2 <- energypal:::.common_labels(c("carriers", "epa"), "default")
    expect_identical(unname(labs2[["Transportation"]]), "Transportation")
    expect_false("Transportation" %in% names(labs))
  })
})

test_that("every built-in palette can be drawn together", {
  with_null_device({
    out <- energypal_show(energypal_info()$name)
    expect_length(out, nrow(energypal_info()))
  })
})

test_that("display arguments are passed through to energypal", {
  with_null_device({
    expect_length(energypal_show("carriers", n = 5), 5)
    expect_true("Natural Gas" %in% names(energypal_show("carriers", label_style = "long")))
    expect_true("Anthracite" %in% names(energypal_show("carriers", include_subtypes = TRUE)))
  })
})

test_that("a user palette file can be drawn", {
  f <- tempfile(fileext = ".yml")
  energypal_write(energypal_create(c(Coal = "#2C2C2C", Solar = "#FFA500")), f)
  with_null_device({
    out <- energypal_show(file = f)
    expect_length(out, 2)
  })
})

test_that("graphics parameters are restored afterwards", {
  with_null_device({
    before <- graphics::par("mar")
    energypal_show("carriers")
    expect_equal(graphics::par("mar"), before)
  })
})
