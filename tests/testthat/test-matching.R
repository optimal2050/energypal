discrete_pals <- {
  i <- energypal_info()
  i$name[i$builtin & i$type == "discrete"]
}

test_that("every label in the bundled dataset resolves, in the taxonomy palettes", {
  # The regression that motivated the rewrite: the package could not colour its
  # own example data, because energypal_colors() used a dead code path.
  src <- unique(owid_energy_mix$source)
  for (p in c("carriers", "technologies")) {
    cols <- energypal_colors(src, palette = p, warn = FALSE)
    unresolved <- names(cols)[cols == "#999999"]
    expect_length(unresolved, 0)
    expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", cols)), info = p)
  }
})

test_that("every label in the bundled dataset is recognised, in every palette", {
  # A report palette need not colour every carrier - it publishes what its
  # source publishes. What it must never do is fail to recognise a label: the
  # answer is either a colour or an explicit "the source does not publish this",
  # never a shrug.
  src <- unique(owid_energy_mix$source)
  for (p in discrete_pals) {
    m <- energypal_match(src, palette = p, warn = FALSE)
    expect_false(any(is.na(m$matched)), info = p)
    expect_true(all(is.na(m$color) == (m$method == "unpublished")), info = p)
  }
})

test_that("a carrier the source does not publish comes back unmapped, not borrowed", {
  # OWID's energy-mix charts have no geothermal series. Before colour
  # inheritance was removed this silently returned the default palette's brown.
  m <- energypal_match("Geothermal", palette = "owid", warn = FALSE)
  expect_identical(m$method, "unpublished")
  expect_identical(m$matched, "Geothermal")
  expect_identical(energypal_colors("Geothermal", palette = "owid", warn = FALSE)[[1]],
                   "#999999")

  # ...while the inherited alias vocabulary still resolves, because the taxonomy
  # is shared and only the colour claim is not
  expect_identical(energypal_colors("nat gas", palette = "owid", warn = FALSE)[[1]],
                   energypal("owid")[["FossilGas"]])
})

test_that("each matching stage does its job", {
  expect_identical(energypal_match("Wind")$method, "exact")
  # exact is case-insensitive by default, so canonical is what strips punctuation
  expect_identical(energypal_match("Solar PV")$method, "canonical")
  expect_identical(energypal_match("Solar-PV")$method, "canonical")
  expect_identical(energypal_match("Coal")$method, "alias")          # -> FossilCoal
  expect_identical(energypal_match("Coal_Plant_2")$method, "contains")

  # fuzzy catches a typo that nothing else would
  got <- energypal_match("Geotherml", method = c("exact", "canonical", "fuzzy"))
  expect_identical(got$method, "fuzzy")
  expect_identical(got$matched, "Geothermal")
})

test_that("stages can be restricted", {
  # "Coal" needs the alias stage; without it there is no match
  strict <- energypal_match("Coal", method = c("exact", "canonical"))
  expect_true(is.na(strict$matched))
  expect_false(is.na(energypal_match("Coal", method = "alias")$matched))
  expect_error(energypal_match("Coal", method = "telepathy"), "unknown matching method")
})

test_that("aliases come from the palette file, so a user palette teaches the matcher", {
  f <- tempfile(fileext = ".yml")
  writeLines(c("meta:", "  name: mine",
               "colors:",
               "  Widget:",
               '    _color: "#FF0000"',
               "    _aliases: [sprocket, doohickey]"), f)
  got <- energypal_match(c("sprocket", "DOOHICKEY"), file = f)
  expect_identical(got$matched, c("Widget", "Widget"))
  expect_identical(unname(energypal_colors("sprocket", file = f)), "#FF0000")
})

test_that("unresolvable labels are visibly grey rather than silently wrong", {
  cols <- energypal_colors(c("Coal", "Flux Capacitor"), warn = FALSE)
  expect_identical(unname(cols[2]), "#999999")
  expect_identical(names(cols), c("Coal", "Flux Capacitor"))

  m <- energypal_match("Flux Capacitor", warn = FALSE)
  expect_true(is.na(m$matched))
  expect_true(is.na(m$color))
})

test_that("energypal_colors preserves input length, order and repeats", {
  src <- c("Coal", "Solar", "Coal", "Wind", "Solar")
  cols <- energypal_colors(src)
  expect_length(cols, 5)
  expect_identical(names(cols), src)
  expect_identical(unname(cols[1]), unname(cols[3]))   # same label, same colour
  expect_identical(unname(cols[2]), unname(cols[5]))
})

test_that("energypal_match returns one row per distinct label", {
  m <- energypal_match(c("Coal", "Coal", "Solar"))
  expect_identical(nrow(m), 2L)
  expect_setequal(m$original, c("Coal", "Solar"))
})

test_that("switching palette changes the colour, and resolves to the same branch", {
  labs <- c("Coal", "Natural Gas", "Solar")
  base <- energypal_match(labs, palette = "carriers")
  ipcc <- energypal_match(labs, palette = "ipcc")

  expect_false(identical(base$color[1], ipcc$color[1]))  # different colours

  # The matched *entry* may differ in depth: `carriers` colours the NaturalGas
  # subtype, IPCC does not, so IPCC settles on the coloured parent. What must
  # agree is which part of the taxonomy the label landed in.
  branch_of <- function(m, pal) {
    tab <- energypal_table(pal, include_groups = TRUE)
    tab$branch[match(m$matched, tab$name)]
  }
  expect_identical(branch_of(base, "carriers"), branch_of(ipcc, "ipcc"))
})

test_that("a colourless entry does not outrank an alias that has a colour", {
  # "Natural Gas" names a subtype IPCC gives no colour. That must not stop the
  # search: FossilGas is declared, and its alias reaches it.
  m <- energypal_match("Natural Gas", palette = "ipcc", warn = FALSE)
  expect_identical(m$matched, "FossilGas")
  expect_false(is.na(m$color))
})

test_that("plant-level unit names resolve", {
  # How fleet data actually names things. CCGT/OCGT were missing from the
  # carriers vocabulary and drew as unmapped grey in a worked example.
  units <- c("Coal_Ratcliffe", "CCGT_Pembroke", "OCGT_Peaker",
             "Wind_DoggerBank", "Solar_Shotwick")
  m <- energypal_match(units, warn = FALSE)
  expect_false(any(is.na(m$color)))
  expect_identical(m$matched,
                   c("FossilCoal", "FossilGas", "FossilGas", "Wind", "Solar"))

  # and each cluster gets its own shades, grouped by resolved carrier
  cols <- energypal_colors(c("Coal_1", "Coal_2", "CCGT_A", "CCGT_B"),
                           gradient = TRUE, warn = FALSE)
  expect_length(unique(cols), 4)
})

test_that("a substring match must sit at a boundary", {
  # "other" is a substring of "geothermal" and "oil" of "boiler". Both matched
  # before the contains stage required an anchor.
  expect_identical(energypal_match("Coal_Plant_2")$method, "contains")
  got <- energypal_match("Geothermal", palette = "owid",
                         method = c("exact", "contains"), warn = FALSE)
  expect_false(identical(got$matched, "Other"))
})

test_that("a name appearing at two levels resolves to the specific entry, quietly", {
  # `Other` exists as both a group (#808080) and the carrier inside it (#C0C0C0).
  # That is a structural artifact, not user-facing ambiguity, so it must not warn.
  expect_silent(m <- energypal_match("Other"))
  expect_identical(m$matched, "Other")
  expect_identical(m$color, "#C0C0C0")                  # the carrier, not the group
  expect_true(is.na(m$candidates))
})

test_that("entries sharing a colour are not treated as ambiguous", {
  # Nuclear is a group and the carrier inside it, both #FFD700
  expect_silent(m <- energypal_match("Nuclear"))
  expect_identical(m$color, "#FFD700")
  expect_true(is.na(m$candidates))
})

test_that("containment prefers the longest match", {
  # "biogas" must not be taken for "gas"
  expect_identical(energypal_match("Biogas")$matched, "Biogas")
})

test_that("short aliases do not match as substrings", {
  # "re" (Renewable), "pv", "ng" and friends are legitimate whole labels but
  # occur inside ordinary words. "warp core" contains "re"; "boiler" contains
  # "oil". Neither may resolve.
  for (junk in c("Warp Core", "Flux Capacitor", "Storey", "Rename")) {
    expect_true(is.na(energypal_match(junk, warn = FALSE)$matched), info = junk)
  }
  # ...while the short alias still works as a whole label
  expect_identical(energypal_match("RE")$matched, "Renewable")
  # "PV" is an alias of Solar in `carriers`, and an entry in its own right in
  # `technologies` - the palette decides, which is the point of the alias layer
  expect_identical(energypal_match("PV")$matched, "Solar")
  expect_identical(energypal_match("PV", palette = "technologies")$matched, "PV")
  # ...and long terms still match inside a label
  expect_identical(energypal_match("Coal_Plant_2")$matched, "FossilCoal")
})

test_that("include_full_palette appends the unmatched entries", {
  without <- energypal_match("Coal")
  with <- energypal_match("Coal", include_full_palette = TRUE)
  expect_gt(nrow(with), nrow(without))
  expect_true(any(with$method == "palette_fill"))
  expect_true(all(is.na(with$original[with$method == "palette_fill"])))
})

test_that("case sensitivity is opt-in", {
  expect_false(is.na(energypal_match("wind")$matched))
  # with case_sensitive the exact stage is strict, but later stages still resolve it
  got <- energypal_match("wind", method = "exact", case_sensitive = TRUE)
  expect_true(is.na(got$matched))
})

test_that("technology labels resolve against the technologies palette", {
  got <- energypal_match(c("CCGT", "Coal", "Oil", "offshore wind"),
                              palette = "technologies")
  expect_identical(got$matched, c("GasFired", "CoalFired", "OilFired", "Wind"))
})

test_that("empty and NA input are handled", {
  expect_length(energypal_colors(character(0)), 0)
  expect_identical(nrow(energypal_match(character(0))), 0L)
  expect_identical(unname(energypal_colors(NA_character_, warn = FALSE)), "#999999")
})
