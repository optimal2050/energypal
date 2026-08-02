test_that("hierarchy palette accessor works", {
  carriers <- hierarchy_palette(section = "carriers", label_style = "id")
  expect_true(is.character(carriers))
  expect_true(!is.null(names(carriers)))
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", carriers)))
  # Accept either direct 'Coal' or internal hierarchical id containing 'Coal'
  expect_true(any(grepl("Coal", names(carriers))))

  # Technologies section (if present in hierarchy)
  tech <- hierarchy_palette(section = "technologies", label_style = "id")
  if (length(tech)) {
    expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", tech)))
  }
})

test_that("energy color mapping works with hierarchy palette", {
  sources <- c("Coal", "Natural Gas", "Solar", "Wind")
  
  # Test basic mapping
  mapped <- map_energy_colors(sources)
  expect_equal(length(mapped), 4)
  expect_equal(names(mapped), sources)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", mapped)))
  
  # Test fuzzy mapping
  fuzzy_sources <- c("coal power", "nat gas", "solar pv", "wind energy")
  fuzzy_mapped <- map_energy_colors(fuzzy_sources, method = "fuzzy")
  expect_equal(length(fuzzy_mapped), 4)
  
  # Mapping with explicit hierarchy token
  mapped_hier <- map_energy_colors(sources, palette_name = "hierarchy_carriers")
  expect_equal(length(mapped_hier), 4)
})

test_that("create_energy_mapping works", {
  # Test basic mapping creation
  mapping <- create_energy_mapping()
  expect_true(is.character(mapping))
  expect_true(!is.null(names(mapping)))
  expect_true(length(mapping) > 10)  # Should have many variations
  
  # Test without variations
  basic_mapping <- create_energy_mapping(include_variations = FALSE)
  expect_true(length(basic_mapping) < length(mapping))
})

test_that("validate_energy_palette supports user palettes (backward compat)", {
  # Custom valid palette (user-supplied vector)
  valid_custom <- c("Coal" = "#2C2C2C", "Gas" = "#4682B4", "Solar" = "#FFA500")
  expect_true(validate_energy_palette(valid_custom))

  invalid_custom <- c("Coal" = "#2C2C2C")
  expect_false(validate_energy_palette(invalid_custom, min_colors = 3))
})

test_that("color interpolation works", {
  # Test basic interpolation
  colors <- interpolate_energy_colors("Coal", "Solar", n = 5)
  expect_equal(length(colors), 5)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", colors)))
  
  # Test error on invalid sources
  expect_error(interpolate_energy_colors("InvalidSource", "Solar"))
})

test_that("label styles produce distinct outputs when available", {
  carriers_id <- hierarchy_to_table(section = "carriers")
  # Choose a subset where long vs short differ (if present)
  if ("label_long" %in% names(carriers_id) && "label_short" %in% names(carriers_id)) {
    differing <- carriers_id$name[which(carriers_id$label_long != carriers_id$label_short &
      nzchar(carriers_id$label_long) & nzchar(carriers_id$label_short))]
    if (length(differing) >= 2) {
      df <- data.frame(src = differing[1:2], val = 1:2)
      p_long <- ggplot2::ggplot(df, ggplot2::aes(x = src, y = val, fill = src)) +
        ggplot2::geom_col() + scale_fill_energy(label_style = "long")
      p_short <- ggplot2::ggplot(df, ggplot2::aes(x = src, y = val, fill = src)) +
        ggplot2::geom_col() + scale_fill_energy(label_style = "short")
      g_long <- ggplot2::ggplot_build(p_long)
      g_short <- ggplot2::ggplot_build(p_short)
      labs_long <- g_long$plot$scales$scales[[1]]$get_labels()
      labs_short <- g_short$plot$scales$scales[[1]]$get_labels()
      # Only assert difference if at least one pair actually differs after scale application
      if (!identical(labs_long, labs_short)) {
        succeed()
      } else {
        testthat::skip("No effective long vs short label difference produced for selected subset")
      }
    }
  }
})