test_that("auto variations generate distinct colors for duplicates when enabled", {
  skip_if_not_installed("ggplot2")
  library(ggplot2)
  # Use duplicated fuzzy names mapping to same base (e.g., solar variants)
  sources <- c("Solar", "Solar Power", "Solar PV", "Photovoltaic")
  old_opts <- set_energy_options(enable_auto_variations = TRUE, variation_type = "lightness", variation_intensity = 0.5)
  on.exit(do.call(set_energy_options, old_opts), add = TRUE)
  mapped <- map_energy_colors(sources, method = "fuzzy")
  expect_equal(length(mapped), length(sources))
  uniq_cols <- unique(unname(mapped))
  # Expect more than 1 distinct color if variations applied
  expect_gt(length(uniq_cols), 1)
})

test_that("duplicate mappings warn when variations disabled", {
  skip_if_not_installed("ggplot2")
  sources <- c("Solar", "Solar Power")
  old_opts <- set_energy_options(enable_auto_variations = FALSE, warn_duplicate_mappings = TRUE)
  on.exit(do.call(set_energy_options, old_opts), add = TRUE)
  expect_warning(map_energy_colors(sources, method = "fuzzy"), "Multiple sources mapped")
})

# palette_direction behavior covered in geom-energy test
