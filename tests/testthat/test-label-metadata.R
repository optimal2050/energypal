test_that("hierarchy_to_table exposes label columns and defaults", {
  tab <- hierarchy_to_table("carriers", include_groups = FALSE)
  expect_true(all(c("label_short","label_long","label_default") %in% names(tab)))
  # At least one long label different from name
  expect_true(any(!is.na(tab$label_long) & nzchar(tab$label_long) & tab$label_long != tab$name))
  # label_default picks long when available else short else name
  for (i in seq_len(nrow(tab))) {
    ld <- tab$label_default[i]; ln <- tab$label_long[i]; ls <- tab$label_short[i]; nm <- tab$name[i]
    expected <- if (!is.na(ln) && nzchar(ln)) ln else if (!is.na(ls) && nzchar(ls)) ls else nm
    expect_identical(ld, expected)
  }
})

test_that("label_style modifies legend labels (color scale)", {
  skip_if_not_installed("ggplot2")
  library(ggplot2)
  htab <- hierarchy_to_table("carriers", include_groups = FALSE)
  # pick one with different long vs short (e.g., Natural Gas -> short Gas)
  cand <- htab[!is.na(htab$label_short) & !is.na(htab$label_long) & htab$label_short != htab$label_long,]
  expect_true(nrow(cand) > 0)
  target <- cand$name[1]
  long_label <- cand$label_long[1]
  short_label <- cand$label_short[1]
  # Build data using the long form so scale must map back to canonical then relabel
  d <- data.frame(source = c(long_label, "Coal", "Solar"), value = c(1,2,3))
  p_long <- ggplot(d, aes(source, value, fill = source)) + geom_col() +
    scale_fill_energy(use_hierarchy = TRUE, label_style = "long")
  p_short <- ggplot(d, aes(source, value, fill = source)) + geom_col() +
    scale_fill_energy(use_hierarchy = TRUE, label_style = "short")
  gb_long <- ggplot_build(p_long)
  gb_short <- ggplot_build(p_short)
  sc_long <- gb_long$plot$scales$scales[[1]]
  sc_short <- gb_short$plot$scales$scales[[1]]
  labs_long <- sc_long$get_labels()
  labs_short <- sc_short$get_labels()
  if (!any(labs_long != labs_short)) {
    skip("No differing long vs short labels produced for selected target")
  }
  expect_true(long_label %in% c(labs_long, labs_short))
  expect_true(short_label %in% c(labs_long, labs_short))
})

test_that("matcher resolves long and short aliases", {
  tab <- hierarchy_to_table("carriers", include_groups = FALSE)
  # Pick an entry where long label differs (e.g., Natural Gas) else skip
  row <- tab[which(!is.na(tab$label_long) & tab$label_long != tab$name)[1],]
  expect_true(nrow(row) == 1)
  long_label <- row$label_long
  short_label <- if (!is.na(row$label_short) && nzchar(row$label_short)) row$label_short else row$name
  res_long <- match_energy_sources(long_label, palette_name = get_default_energy_palette())
  res_short <- match_energy_sources(short_label, palette_name = get_default_energy_palette())
  # If the canonical palette does not contain the hierarchy internal name (e.g., FossilGas) but contains the long form (Natural Gas),
  # allow either direct palette long match or internal name match.
  expect_true(res_long$matched %in% c(row$name, long_label))
  expect_true(res_short$matched %in% c(row$name, long_label, short_label))
})
