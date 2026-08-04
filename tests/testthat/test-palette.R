test_that("the split into carriers.yml/technologies.yml preserved both palettes", {
  # 93 is the pre-split carrier count and must not drift: the split was meant to
  # be content-identical. Asserted against the full table rather than energypal(),
  # whose defaults show only the main level.
  expect_length(energypal("carriers", include_groups = TRUE, include_subtypes = TRUE), 93)

  # technologies was 76 at the split and gained OilFired plus its three subtypes,
  # because oil-fired generation was missing from the taxonomy entirely.
  expect_length(energypal("technologies", include_groups = TRUE, include_subtypes = TRUE), 80)
  expect_true("OilFired" %in% energypal_table("technologies")$name)
})

test_that("the default is the main level only", {
  pal <- energypal("carriers")
  expect_length(pal, 17)
  expect_true("FossilCoal" %in% names(pal))     # a carrier
  expect_false("FossilFuels" %in% names(pal))   # a group, above it
  expect_false("Anthracite" %in% names(pal))    # a subtype, below it
})

test_that("include_ flags widen the selection", {
  base <- energypal("carriers")
  with_groups <- energypal("carriers", include_groups = TRUE)
  with_subs <- energypal("carriers", include_subtypes = TRUE)

  expect_gt(length(with_groups), length(base))
  expect_gt(length(with_subs), length(base))
  expect_true("FossilFuels" %in% names(with_groups))
  expect_true("Anthracite" %in% names(with_subs))

  # groups only, no carriers
  groups_only <- energypal("carriers", include_groups = TRUE, include_carriers = FALSE)
  expect_true("FossilFuels" %in% names(groups_only))
  expect_false("FossilCoal" %in% names(groups_only))
})

test_that("label_style renames without changing colours", {
  ids <- energypal("carriers")
  longs <- energypal("carriers", label_style = "long")
  expect_equal(unname(ids), unname(longs))
  expect_true("FossilGas" %in% names(ids))
  expect_true("Natural Gas" %in% names(longs))
})

test_that("n truncates like brewer.pal and refuses to over-ask", {
  full <- energypal("carriers")
  expect_length(energypal("carriers", n = 5), 5)
  expect_equal(energypal("carriers", n = 5), full[1:5])
  expect_error(energypal("carriers", n = length(full) + 1), "too many")
  expect_error(energypal("carriers", n = 0), "positive")
})

test_that("n draws from carriers, not groups or subtypes", {
  five <- energypal("carriers", n = 5)
  expect_identical(names(five),
                   c("FossilCoal", "FossilOil", "FossilGas", "Bioenergy", "Hydro"))
  # all five are visually distinct, which the subtype shades would not be
  expect_length(unique(unname(five)), 5)
})

test_that("report palettes differ from the default where they should", {
  base <- energypal("carriers")
  for (nm in c("ipcc", "owid", "eia", "epa")) {
    p <- energypal(nm)
    expect_false(identical(p[["FossilCoal"]], base[["FossilCoal"]]),
                 info = paste(nm, "should override FossilCoal"))
  }
})

test_that("a palette shows only the colours it declares", {
  # The point of the store: a report palette states what its source publishes.
  # Inheriting the taxonomy is shared vocabulary; inheriting colour would be a
  # claim the source never made.
  owid <- energypal("owid")
  expect_false("Geothermal" %in% names(owid))     # OWID does not break it out
  expect_true("Geothermal" %in% names(energypal("carriers")))

  # every colour a palette reports is one its own file declares
  info <- energypal_info()
  for (nm in info$name[info$builtin & info$type == "discrete"]) {
    raw <- yaml::read_yaml(energypal:::.palette_file(nm))
    declared <- energypal:::.declared_colors(raw$colors)
    tab <- energypal_table(nm, include_groups = TRUE)
    coloured <- tab$name[!is.na(tab$color) & nzchar(tab$color)]
    expect_true(all(coloured %in% declared), info = nm)
  }
})

test_that("a named vector round-trips through YAML unchanged", {
  x <- c(Coal = "#FF0000", Solar = "#00FF00", Gas = "#0000FF")
  p <- energypal_create(x, name = "mine", title = "My colours")
  f <- tempfile(fileext = ".yml")
  energypal_write(p, f)

  back <- energypal(file = f)
  expect_identical(back, x)

  spec <- energypal_spec(file = f)
  expect_identical(spec$meta$name, "mine")
  expect_identical(spec$meta$title, "My colours")
})

test_that("a flat palette can extend the hierarchy and inherit labels", {
  f <- tempfile(fileext = ".yml")
  writeLines(c("meta:", "  name: mine", "  extends: carriers",
               "colors:", '  FossilCoal: "#FF0000"'), f)
  tab <- energypal_table(file = f)
  row <- tab[tab$name == "FossilCoal", ]
  expect_equal(nrow(row), 1)
  expect_identical(row$color, "#FF0000")
  expect_identical(row$label_long, "Coal")     # inherited
  expect_true(grepl("coal", row$aliases))      # inherited
})

test_that("energypal_create rejects malformed input", {
  expect_error(energypal_create(c("#FF0000")), "named")
  expect_error(energypal_create(c(Coal = "red")), "hex")
  expect_error(energypal_create(c(Coal = "#FF0000", Coal = "#00FF00")), "[Dd]uplicate")
})

test_that("registration makes a palette usable by name and is reversible", {
  x <- c(Coal = "#123456")
  f <- tempfile(fileext = ".yml")
  energypal_write(energypal_create(x, name = "reg1"), f)

  expect_null(energypal_register("reg1", f))
  expect_identical(energypal("reg1"), x)
  expect_true("reg1" %in% energypal_info()$name)
  expect_false(energypal_info()$builtin[energypal_info()$name == "reg1"])

  # re-registering returns the path it replaced
  f2 <- tempfile(fileext = ".yml")
  energypal_write(energypal_create(c(Coal = "#654321"), name = "reg1"), f2)
  expect_identical(normalizePath(energypal_register("reg1", f2), winslash = "/"),
                   normalizePath(f, winslash = "/"))
})

test_that("registering an invalid file fails immediately, not at first use", {
  f <- tempfile(fileext = ".yml")
  writeLines(c("meta:", "  name: bad", "colors:", '  Coal: "octarine"'), f)
  expect_error(energypal_register("bad", f), "hex")
})

test_that("the editing cycle works: save, hand-edit, reload", {
  f <- tempfile(fileext = ".yml")
  energypal_write(energypal_create(c(Gas = "#4682B4"), name = "edited"), f)

  # upgrade the bare colour into a map, as a user would in a text editor
  txt <- readLines(f)
  txt <- sub('^  Gas: "#4682B4"$',
             paste0('  Gas:\n    _color: "#4682B4"\n    _long: Natural Gas\n',
                    '    _aliases: [nat gas, NG]'), txt)
  writeLines(txt, f)

  tab <- energypal_table(file = f)
  expect_identical(tab$color[tab$name == "Gas"], "#4682B4")
  expect_identical(tab$label_long[tab$name == "Gas"], "Natural Gas")
  expect_identical(energypal(file = f, label_style = "long")[["Natural Gas"]], "#4682B4")
})
