discrete_pals <- {
  i <- energypal_info()
  i$name[i$builtin & i$type == "discrete"]
}

test_that("declared orderings reference only entries the palette defines", {
  for (nm in discrete_pals) {
    spec <- energypal_spec(nm)
    known <- energypal_table(nm)$name
    for (o in names(spec$orders)) {
      seq_ids <- if (is.character(spec$orders[[o]])) spec$orders[[o]] else
        as.character(unlist(spec$orders[[o]][["_order"]]))
      expect_true(all(seq_ids %in% known),
                  info = sprintf("%s / %s: unknown ids %s", nm, o,
                                 paste(setdiff(seq_ids, known), collapse = ", ")))
    }
  }
})

test_that("ordering permutes without changing any carrier's colour", {
  base <- energypal("carriers")
  for (o in c("carbon_intensity", "dispatchability", "merit_order", "renewability",
              "alpha", "hue", "lightness", "chroma")) {
    got <- energypal("carriers", order = o)
    expect_setequal(names(got), names(base))
    expect_identical(base[names(got)], got, info = o)   # same colour per carrier
    expect_length(got, length(base))                     # nothing dropped or added
    expect_false(anyDuplicated(names(got)) > 0)
  }
})

test_that("at least one ordering actually changes the sequence", {
  base <- energypal("carriers")
  changed <- vapply(c("carbon_intensity", "merit_order", "alpha"), function(o) {
    !identical(names(energypal("carriers", order = o)), names(base))
  }, logical(1))
  expect_true(all(changed))
})

test_that("direction reverses whichever order was chosen", {
  for (o in list(NULL, "carbon_intensity", "alpha")) {
    fwd <- energypal("carriers", order = o)
    rev_ <- energypal("carriers", order = o, direction = -1)
    expect_identical(rev(fwd), rev_)
  }
})

test_that("an ordering keeps each family together", {
  # Orderings are declared at carrier level - carbon_intensity names nine
  # entries out of 93 - so every subtype must sort with its parent rather than
  # being dumped at the end, which would scatter each fuel's family.
  tab <- energypal_table("carriers", order = "carbon_intensity")
  pos <- function(x) match(x, tab$name)

  coal <- c("FossilCoal", "Anthracite", "Bituminous", "SubBituminous", "Lignite", "Coke")
  expect_identical(pos(coal), seq(pos("FossilCoal"), length.out = length(coal)))

  # the parent leads its own subtypes
  for (p in c("FossilCoal", "FossilOil", "FossilGas")) {
    kids <- tab$name[!is.na(tab$parent) & tab$parent == p]
    expect_true(all(pos(kids) > pos(p)), info = p)
  }

  # and the declared carriers still lead, in the declared order
  carriers <- c("FossilCoal", "FossilOil", "FossilGas")
  expect_identical(pos(carriers), sort(pos(carriers)))
})

test_that("subtypes inherit a numeric property from their parent", {
  # Anthracite has no _carbon_intensity of its own; without inheritance it would
  # sort behind every entry that does.
  tab <- energypal_table("carriers", order = "carbon_intensity")
  expect_lt(match("Anthracite", tab$name), match("Wind", tab$name))
  expect_lt(match("NaturalGas", tab$name), match("Solar", tab$name))
})

test_that("an explicit id vector also carries its subtypes", {
  tab <- energypal_table("carriers", order = c("Solar", "FossilCoal"))
  expect_identical(tab$name[1], "Solar")
  solar_kids <- tab$name[!is.na(tab$parent) & tab$parent == "Solar"]
  expect_true(all(match(solar_kids, tab$name) < match("FossilCoal", tab$name)))
})

test_that("a partial ordering leaves the remainder in file order", {
  spec_order <- names(energypal("carriers"))
  got <- names(energypal("carriers", order = c("Solar", "Wind")))
  expect_identical(got[1:2], c("Solar", "Wind"))
  expect_identical(got[-(1:2)], setdiff(spec_order, c("Solar", "Wind")))
})

test_that("an explicit vector may name entries the palette lacks", {
  got <- names(energypal("carriers", order = c("NotAThing", "Solar")))
  expect_identical(got[1], "Solar")
  expect_length(got, length(energypal("carriers")))
})

test_that("a declared ordering wins over a like-named property", {
  # carriers declares both orders$carbon_intensity and properties$carbon_intensity
  spec <- energypal_spec("carriers")
  expect_true("carbon_intensity" %in% names(spec$orders))
  expect_true("carbon_intensity" %in% names(spec$properties))

  declared <- as.character(unlist(spec$orders$carbon_intensity[["_order"]]))
  got <- names(energypal("carriers", order = "carbon_intensity"))
  expect_identical(got[seq_along(declared)], declared)
})

test_that("declared values still run high to low", {
  tab <- energypal_table("carriers", include_groups = FALSE,
                              order = "carbon_intensity")
  present <- tab$carbon_intensity[!is.na(tab$carbon_intensity)]
  expect_identical(present, sort(present, decreasing = TRUE))
})

test_that("inheritance affects the sort, not the reported values", {
  # A subtype sorts with its parent, but must not be given the parent's figure:
  # the column reports what the palette actually declares, and Anthracite
  # declares no carbon intensity of its own.
  tab <- energypal_table("carriers", order = "carbon_intensity")
  expect_true(is.na(tab$carbon_intensity[tab$name == "Anthracite"]))
  expect_identical(tab$carbon_intensity[tab$name == "FossilCoal"], 820)

  # ...yet it sorts immediately after its parent rather than at the end
  expect_identical(match("Anthracite", tab$name), match("FossilCoal", tab$name) + 1L)
})

test_that("property columns carry their provenance", {
  tab <- energypal_table("carriers", include_groups = FALSE)
  ci <- tab$carbon_intensity
  expect_true(is.numeric(ci))
  expect_match(attr(ci, "note"), "[Pp]resentation only")
  expect_match(attr(ci, "note"), "NOT a model input", fixed = TRUE)
  expect_match(attr(ci, "source"), "IPCC")
  expect_identical(attr(ci, "unit"), "gCO2eq/kWh")
})

test_that("provenance survives filtering and reordering", {
  for (args in list(list(), list(include_groups = FALSE),
                    list(order = "alpha"), list(order = "carbon_intensity",
                                                direction = -1))) {
    tab <- do.call(energypal_table, c(list("carriers"), args))
    expect_match(attr(tab$carbon_intensity, "note"), "[Pp]resentation only")
  }
})

test_that("energypal_orders lists declared, property and computed orderings", {
  o <- energypal_orders("carriers")
  expect_true(all(c("order", "kind", "n", "note", "source", "url") %in% names(o)))
  expect_true(all(c("carbon_intensity", "dispatchability", "merit_order",
                    "renewability") %in% o$order[o$kind == "declared"]))
  expect_true(all(c("spec", "alpha", "hue", "lightness", "chroma") %in%
                    o$order[o$kind == "computed"]))
})

test_that("text properties are data, not orderings", {
  # `_taxonomy_source` records which classification each branch follows. It is
  # queryable through the table, but sorting a legend by it is meaningless, so
  # it must not appear as an ordering.
  o <- energypal_orders("carriers")
  expect_false("taxonomy_source" %in% o$order)
  expect_true("taxonomy_source" %in% names(energypal_table("carriers")))
})

test_that("every declared ordering states it is presentation only", {
  for (nm in discrete_pals) {
    o <- energypal_orders(nm)
    dec <- o[o$kind %in% c("declared", "property"), ]
    if (!nrow(dec)) next
    expect_false(any(is.na(dec$note)), info = nm)
    expect_true(all(nzchar(dec$note)), info = nm)
    expect_true(all(grepl("presentation only", dec$note, ignore.case = TRUE)),
                info = sprintf("%s: %s", nm, paste(dec$order, collapse = ", ")))
  }
})

test_that("validation refuses a declared ordering or property with no note", {
  no_note_order <- list(meta = list(name = "x"), colors = list(Coal = "#2C2C2C"),
                        orders = list(mine = list(`_order` = "Coal")))
  expect_error(energypal_validate(no_note_order, strict = FALSE), "_note")

  no_note_prop <- list(meta = list(name = "x"), colors = list(Coal = "#2C2C2C"),
                       properties = list(mine = list(`_unit` = "kg")))
  expect_error(energypal_validate(no_note_prop, strict = FALSE), "_note")

  no_seq <- list(meta = list(name = "x"), colors = list(Coal = "#2C2C2C"),
                 orders = list(mine = list(`_note` = "presentation only")))
  expect_error(energypal_validate(no_seq, strict = FALSE), "_order")

  # a bare vector claims nothing, so it needs no note
  bare <- list(meta = list(name = "x"), colors = list(Coal = "#2C2C2C"),
               orders = list(mine = "Coal"))
  expect_silent(energypal_validate(bare, strict = FALSE))
})
