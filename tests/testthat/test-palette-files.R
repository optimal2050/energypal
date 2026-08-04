# The palette store is a set of independent YAML files. Nothing stops one of
# them drifting from the others except these checks, so they run over every
# built-in file rather than a fixed list.

pal_names <- energypal_info()$name[energypal_info()$builtin]

test_that("every built-in palette is valid", {
  expect_gt(length(pal_names), 0)
  for (nm in pal_names) {
    spec <- energypal_spec(nm)
    expect_silent(energypal_validate(spec, name = nm))
  }
})

test_that("every built-in palette yields usable colours", {
  for (nm in pal_names) {
    pal <- energypal(nm)
    expect_gt(length(pal), 0)
    expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", pal)),
                info = paste(nm, "has non-hex colours"))
    expect_false(any(duplicated(names(pal))),
                 info = paste(nm, "has duplicate names"))
    expect_false(any(is.na(names(pal))), info = paste(nm, "has NA names"))
  }
})

test_that("meta$name matches the file name", {
  for (nm in pal_names) {
    expect_identical(energypal_spec(nm)$meta$name, nm)
  }
})

test_that("every palette declares its provenance", {
  info <- energypal_info()
  info <- info[info$builtin, ]
  expect_false(any(is.na(info$title)))
  expect_false(any(is.na(info$source)))
})

test_that("strict validation enforces the licence obligations", {
  base <- list(meta = list(name = "x"), colors = list(Coal = "#2C2C2C"))

  # a palette must say how its colours were obtained
  expect_error(energypal_validate(base), "meta\\$license")
  expect_silent(energypal_validate(base, strict = FALSE))

  # CC BY needs the citation it requires...
  cc <- utils::modifyList(base, list(meta = list(
    name = "x", license = "CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)")))
  expect_error(energypal_validate(cc), "attribution")

  # ...and a link to the licence, which naming it is not
  named_only <- utils::modifyList(base, list(meta = list(
    name = "x", license = "CC BY 4.0", attribution = "After Someone, CC BY 4.0.")))
  expect_error(energypal_validate(named_only), "links no licence deed")

  ok <- utils::modifyList(base, list(meta = list(
    name = "x",
    license = "CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)",
    attribution = "After Someone, CC BY 4.0.")))
  expect_silent(energypal_validate(ok))

  # a non-CC licence needs neither
  pd <- utils::modifyList(base, list(meta = list(
    name = "x", license = "Public domain (17 U.S.C. 105).")))
  expect_silent(energypal_validate(pd))
})

test_that("no shipped file points at a path that is not published", {
  # dev/ and drafts/ are git-ignored and .Rbuildignore'd, so a cross-reference
  # into them from a palette or a vignette leads nowhere for any reader.
  shipped <- c(list.files("../../inst/extdata/palettes", full.names = TRUE),
               list.files("../../vignettes", pattern = "[.]Rmd$", full.names = TRUE))
  shipped <- shipped[file.exists(shipped)]
  skip_if(!length(shipped), "running outside the source tree")

  for (f in shipped) {
    txt <- readLines(f, warn = FALSE)
    hit <- grep("dev/references|drafts/|data-raw/", txt, value = TRUE)
    expect_length(hit, 0)
  }
})

test_that("extends resolves and overrides in place, not by appending", {
  # ipcc overrides FossilCoal, which lives nested under FossilFuels in carriers.
  # A naive merge would add a second top-level FossilCoal instead.
  tab <- energypal_table("ipcc")
  expect_equal(sum(tab$name == "FossilCoal"), 1)
  expect_identical(tab$color[tab$name == "FossilCoal"], "#2E2E2E")

  # ...and the inherited metadata survives the override
  expect_identical(tab$label_long[tab$name == "FossilCoal"], "Coal")
  expect_true(grepl("coal", tab$aliases[tab$name == "FossilCoal"]))

  # entries with no equivalent in the parent are added
  expect_true("FossilCoalCCS" %in% tab$name)
})

test_that("circular inheritance is refused", {
  # A cycle cannot be registered outright, since registration validates that the
  # extends target exists. It can still be created by editing files that are
  # already registered, which is what this reproduces.
  d <- tempfile(); dir.create(d)
  a <- file.path(d, "a.yml"); b <- file.path(d, "b.yml")
  writeLines(c("meta:", "  name: a", "colors:", '  X: "#000000"'), a)
  writeLines(c("meta:", "  name: b", "colors:", '  Y: "#FFFFFF"'), b)
  energypal_register("a", a)
  energypal_register("b", b)

  writeLines(c("meta:", "  name: a", "  extends: b", "colors:", '  X: "#000000"'), a)
  writeLines(c("meta:", "  name: b", "  extends: a", "colors:", '  Y: "#FFFFFF"'), b)
  expect_error(energypal_spec("a"), "[Cc]ircular")
})

test_that("an unknown palette name reports what is available", {
  expect_error(energypal("no-such-palette"), "carriers")
})
