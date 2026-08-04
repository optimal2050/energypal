# Changelog

## energypal 0.1.0

First release.

### Palettes are data

- Each palette is a YAML file under `inst/extdata/palettes/`, carrying
  its own colours, display labels, aliases, orderings and provenance.
  Adding a palette is a file, not a change to the R source.
- Nine palettes ship: the `carriers` taxonomy and a `technologies` one,
  four approximating published reports (`eia`, `epa`, `ipcc`, `owid`),
  and three continuous resource scales.
- **A palette shows only the colours its own source publishes.**
  `meta.extends` lets a palette inherit the taxonomy — names, labels,
  aliases, hierarchy, orderings — and state only its own colours. It
  never inherits colours. A carrier the source is silent about comes
  back unmapped rather than quietly borrowing the default, and
  [`energypal_match()`](https://optimal2050.github.io/energypal/reference/energypal_match.md)
  reports that as `unpublished` rather than as a failure to recognise
  the label.
- Overrides apply wherever the name occurs in the parent, at any depth.
  Aliases accumulate rather than replace, so a palette adding its
  source’s wording (“Petroleum”, “Nuclear Electric Power”) widens the
  vocabulary the matcher understands instead of narrowing it.
- [`energypal()`](https://optimal2050.github.io/energypal/reference/energypal.md)
  returns a named colour vector; `n` takes the first few, as
  [`RColorBrewer::brewer.pal()`](https://rdrr.io/pkg/RColorBrewer/man/ColorBrewer.html)
  does.
  [`energypal_info()`](https://optimal2050.github.io/energypal/reference/energypal_info.md)
  lists what is available and
  [`energypal_show()`](https://optimal2050.github.io/energypal/reference/energypal_show.md)
  draws it, or draws several palettes as an aligned comparison.

### Matching the labels real data uses

- [`energypal_colors()`](https://optimal2050.github.io/energypal/reference/energypal_colors.md)
  maps data labels to colours, and
  [`energypal_match()`](https://optimal2050.github.io/energypal/reference/energypal_match.md)
  reports which of five stages resolved each one — exact, canonicalised,
  declared alias, fuzzy, or containment.
- Aliases are declared in the palette file rather than in package code,
  so a user palette can teach the matcher its own vocabulary.
- Containment matches must sit at one end of the label. Canonicalising
  strips the separators, so a term found in the middle is usually an
  accident — “other” sits inside “ge**other**mal”, “oil” inside
  “b**oil**er” — while the real cases are all `<carrier><qualifier>` or
  `<qualifier><carrier>`.
- Unresolved labels come back in a visible fallback colour rather than
  silently taking a neighbour’s.

### Ordering

- Palettes declare named orderings — `carbon_intensity`,
  `dispatchability`, `merit_order`, `renewability` — alongside computed
  ones (`alpha`, `hue`, `lightness`, `chroma`).
  [`energypal_orders()`](https://optimal2050.github.io/energypal/reference/energypal_orders.md)
  lists them.
- An ordering declared at carrier level covers the subtypes beneath it:
  an entry the sequence does not name sorts with its nearest named
  ancestor, so each fuel’s family stays together.
- **Orderings, and the numeric properties behind them, are for
  presentation only.** They arrange legends and chart series; they are
  indicative values, not validated figures, and must not be used in
  calculations. Every declared ordering and property carries a note
  saying so,
  [`energypal_validate()`](https://optimal2050.github.io/energypal/reference/energypal_validate.md)
  refuses one that omits it, and the note travels with the data as a
  column attribute.

### ggplot2 scales

- [`scale_fill_energy()`](https://optimal2050.github.io/energypal/reference/scale_energy.md)
  and
  [`scale_colour_energy()`](https://optimal2050.github.io/energypal/reference/scale_energy.md)
  colour discrete data, resolving whatever labels it contains, with
  `order` and `label_style` arguments. A factor’s own level order is
  respected unless `order` is given.
- `scale_*_energy_c()` and `scale_*_energy_b()` handle continuous data,
  the binned form taking its breaks from the palette.
- Passing a continuous palette to a discrete scale, or the reverse, is
  an error rather than a silent half-result.

### Continuous palettes and families

- Continuous palettes are an ordered list of stops that may declare
  canonical break points and a unit. For them, `n` interpolates rather
  than truncating.
- An atlas publishes several quantities and styles each differently, so
  each is a separate palette named `family_measure` (`windatlas_speed`,
  `solaratlas_ghi`), grouped by `meta.family`. They are not
  interchangeable. One member of each family is its default, so the bare
  family name resolves to it.
- The solar scales are extracted from the Global Solar Atlas **poster
  maps**, which are downloadable Works under CC BY. The atlases’ terms
  forbid automated access to their applications, so a poster is the
  permitted route.
  - `solaratlas_ghi` (28 bins) and `solaratlas_pvout` (24 bins), CC BY
    4.0
  - `windatlas_speed` (31 bins), CC BY 4.0 IGO — an **approximation**,
    recovered from the `merra2ools` figure legend so those published
    maps stay reproducible. Reading the scale off the GWA poster
    directly was tried and gave neither the right colours nor the right
    range, so the palette says it approximates the atlas rather than
    claiming to be it. Worth recording: the GWA data downloads contain
    float rasters and no colour table at all, so a published map is the
    only source for a wind scale.

### Shades

- [`energypal_gradient()`](https://optimal2050.github.io/energypal/reference/energypal_gradient.md)
  produces distinct shades of one colour, and
  `energypal_colors(gradient = TRUE)` applies that to labels resolving
  to the same carrier, grouping by carrier rather than by colour.
- Shades are computed in OKLAB and spread symmetrically around the base,
  so a bright carrier separates as well as a dark one.

### Your own palettes

- [`energypal_create()`](https://optimal2050.github.io/energypal/reference/energypal_create.md)
  builds a palette from a named colour vector,
  [`energypal_write()`](https://optimal2050.github.io/energypal/reference/energypal_write.md)
  saves it as editable YAML, and
  [`energypal_register()`](https://optimal2050.github.io/energypal/reference/energypal_register.md)
  makes a file usable by name. Entries start as bare colours and can be
  expanded in place with labels and aliases.
- [`energypal_validate()`](https://optimal2050.github.io/energypal/reference/energypal_validate.md)
  and
  [`energypal_validate_families()`](https://optimal2050.github.io/energypal/reference/energypal_validate_families.md)
  check a palette and the relationships between palettes; both run over
  every built-in palette in the test suite, so a new file is checked
  automatically.
- Validation has a `strict` mode, on by default, that additionally
  requires provenance: a `meta.license` saying how the colours were
  obtained, and the citation a CC BY licence requires. It is *not*
  applied to palettes you register yourself — your own colours need no
  paperwork.

### Licensing and provenance

- The package is Apache 2.0. Palettes are content, so each states its
  own terms in `meta.license`, and `inst/NOTICE` summarises them.
- Palettes named after a published source approximate its appearance for
  compatibility. Titles say so — “IPCC AR6 WGIII energy supply
  (approximation)” — because the title is what gets read every time a
  palette is listed. energypal is not affiliated with, sponsored by, or
  endorsed by any organisation named.
- `carriers` and `technologies` cite their taxonomy source per branch,
  as `_taxonomy_source`, so an entry that is energypal’s own extension
  rather than a published classification is visibly so.
- Three palettes were dropped for not earning their place: `iea`
  differed from `carriers` in **zero** carrier-level entries, because
  `carriers` was seeded from it; `fossil` and `renewable` differed in
  one each and only restyled subtypes. They are kept, with the
  measurements, in `dev/references/`.
- `dev/references/palette-licences.md` records the terms per source and
  is what a contributor reads before adding a palette from a new one.

### Data

- `owid_energy_mix`: electricity generation mix for seven major
  economies over 25 years, curated from the Our World in Data energy
  dataset (CC-BY 4.0), with snapshot provenance attached as a `metadata`
  attribute.
