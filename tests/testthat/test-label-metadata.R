test_that("energypal_table exposes label columns and defaults", {
  tab <- energypal_table("carriers", include_groups = FALSE)
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

# Two further tests lived here, covering scale_fill_energy(label_style = ) and
# alias resolution via get_default_energy_palette(). Both functions were removed
# in the move to the YAML hierarchy, so the tests errored rather than skipped.
# They are kept verbatim in drafts/v0-deprecated/test-label-metadata.R and are
# reinstated against the new API when the scales return.
