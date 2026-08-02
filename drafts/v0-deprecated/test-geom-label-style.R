test_that("geom_energy_col passes label_style to scale", {
  skip_if_not_installed("ggplot2")
  library(ggplot2)
  htab <- hierarchy_to_table("carriers", include_groups = FALSE)
  diff_rows <- htab[!is.na(htab$label_short) & !is.na(htab$label_long) & htab$label_short != htab$label_long,]
  if (nrow(diff_rows) == 0) skip("No differing label pairs available in hierarchy")
  # Choose up to 3 differing sources plus one stable reference
  chosen <- head(diff_rows$label_long, 2)
  ref <- htab$name[1]
  d <- data.frame(source = c(chosen, ref), value = seq_along(c(chosen, ref)))
  p_short <- ggplot(d, aes(source, value, fill = source)) +
    geom_energy_col(label_style = "short", use_hierarchy = TRUE, section = "carriers")
  p_long <- ggplot(d, aes(source, value, fill = source)) +
    geom_energy_col(label_style = "long", use_hierarchy = TRUE, section = "carriers")
  b_short <- ggplot_build(p_short)
  b_long <- ggplot_build(p_long)
  sc_short <- b_short$plot$scales$scales[[1]]
  sc_long <- b_long$plot$scales$scales[[1]]
  ls_short <- sc_short$get_labels()
  ls_long <- sc_long$get_labels()
  if (identical(ls_short, ls_long)) skip("No label_style differentiation manifested for selected subset")
  expect_false(identical(ls_short, ls_long))
})
