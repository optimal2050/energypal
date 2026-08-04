test_that("the built-in families are structurally sound", {
  # exactly one default per multi-member family, unique measures, no name clash
  expect_silent(energypal_validate_families())
})

test_that("a bare family name resolves to its default member", {
  expect_identical(energypal("windatlas"), energypal("windatlas_speed"))
  expect_identical(energypal("solaratlas"), energypal("solaratlas_ghi"))

  # and it is the same file, not a coincidence of equal colours
  expect_identical(energypal_spec("windatlas")$meta$name, "windatlas_speed")
  expect_identical(energypal_spec("solaratlas")$meta$name, "solaratlas_ghi")
})

test_that("family metadata is reported", {
  info <- energypal_info()
  expect_true(all(c("family", "measure", "default") %in% names(info)))

  w <- info[info$name == "windatlas_speed", ]
  expect_identical(w$family, "windatlas")
  expect_identical(w$measure, "speed")
  expect_true(w$default)

  # discrete report palettes declare no family
  expect_true(is.na(info$family[info$name == "owid"]))
  expect_false(info$default[info$name == "owid"])
})

test_that("a measure is unique within its family", {
  clash <- list(meta = list(name = "fam_x", family = "fam", measure = "x"),
                colors = list(Coal = "#2C2C2C"))
  expect_silent(energypal_validate(clash, strict = FALSE))
  # the cross-file rule is what catches a repeat; see energypal_validate_families()
  expect_identical(anyDuplicated(energypal_info(family = "solaratlas")$measure), 0L)
})

test_that("energypal_info filters by family", {
  got <- energypal_info(family = "windatlas")
  expect_gt(nrow(got), 0)
  expect_true(all(got$family == "windatlas"))
  expect_true("windatlas_speed" %in% got$name)
  expect_false("solaratlas_ghi" %in% got$name)
  expect_error(energypal_info(family = "nope"), "unknown palette family")
})

test_that("a palette naming a family must name its measure and follow the convention", {
  no_measure <- list(meta = list(name = "fam_x", family = "fam"),
                     colors = list(Coal = "#2C2C2C"))
  expect_error(energypal_validate(no_measure), "measure")

  bad_name <- list(meta = list(name = "wrong", family = "fam", measure = "x"),
                   colors = list(Coal = "#2C2C2C"))
  expect_error(energypal_validate(bad_name), "family convention")

  ok <- list(meta = list(name = "fam_x", family = "fam", measure = "x"),
             colors = list(Coal = "#2C2C2C"))
  expect_silent(energypal_validate(ok, strict = FALSE))

})

test_that("a palette with no family is unaffected", {
  plain <- list(meta = list(name = "plain"), colors = list(Coal = "#2C2C2C"))
  expect_silent(energypal_validate(plain, strict = FALSE))
  expect_true(is.na(energypal_info()$family[energypal_info()$name == "carriers"]))
})

test_that("family members are separate palettes, not interchangeable", {
  # the two families style different quantities in different units
  info <- energypal_info()
  w <- info[info$name == "windatlas_speed", ]
  s <- info[info$name == "solaratlas_ghi", ]
  expect_false(identical(w$family, s$family))
  expect_false(identical(w$measure, s$measure))
  expect_false(identical(w$unit, s$unit))
})

test_that("an unknown name mentions the available families", {
  err <- tryCatch(energypal("windatlas_nope"), error = conditionMessage)
  expect_match(err, "unknown palette")
  expect_match(err, "families")
  expect_match(err, "windatlas")
})

test_that("every family member declares a unit, since the quantities differ", {
  info <- energypal_info()
  fam_rows <- info[!is.na(info$family), ]
  expect_gt(nrow(fam_rows), 0)
  expect_false(any(is.na(fam_rows$unit)))
  expect_false(any(is.na(fam_rows$measure)))
})
