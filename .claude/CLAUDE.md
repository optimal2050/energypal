# energypal — working notes

Colour palettes for energy data visualisation. Palettes are **data, not code**: they live as YAML
files under `inst/extdata/palettes/`, one file per palette, and adding one should never require
touching R. Nine ship.

The package is Apache 2.0. Palettes are content and each states its own terms; `inst/NOTICE`
summarises them.

## Layout

```
R/                      package code
  palettes.R            palette store: loading, extends-merge, registry, validation
  energypal.R           flattening a palette into a table, and into a colour vector
  order.R               ordering resolution and energypal_orders()
  mapping.R             matching data labels to palette entries
  gradient.R            OKLAB shades of one colour
  scales.R              ggplot2 scales: discrete, _c (smooth), _b (binned)
  display.R             energypal_show()
  data.R                owid_energy_mix documentation
  zzz.R                 package-local cache environment
inst/extdata/palettes/  the palettes themselves - see below
inst/NOTICE             third-party terms and the no-affiliation statement
pkgdown/extra.scss      site CSS overrides - see Traps
```

`dev/`, `drafts/` and `data-raw/` are **git-ignored and `.Rbuildignore`d**: local working material,
not repo content and not package content. Anything under them is invisible to a reader, so **nothing
that ships may reference them** — a test in `test-palette-files.R` enforces that. `data-raw/` holds
~19 GB of atlas downloads and the script that reads them; neither is required by any licence.

## Palette files

A palette is a `meta:` block plus a `colors:` block. Nesting lives *inside* a file; there is
deliberately no second lookup dimension (no `section`, no `variant`) — one name, one palette.
`family` and `measure` are discovery metadata that shape the *name*, not a second key to look up by.

```yaml
meta:
  name: ipcc              # must match the filename
  title: "..."            # says "(approximation)" when the colours are not official
  source: "..."           # where the colours came from
  url: "..."
  license: "..."          # REQUIRED: how the colours were obtained; CC BY needs an https:// deed link
  attribution: "..."      # REQUIRED if the licence is CC BY: the citation it demands
  extends: carriers       # optional: inherit the TAXONOMY, never the colours
colors:
  FossilFuels:
    FossilCoal:
      _color: "#2E2E2E"
      _short: Coal
      _long: Coal
      _aliases: [coal, hard coal]
      subtypes: {Anthracite: "#1E1E1E"}
```

Reserved keys are `_color`, `_short`, `_long`, `_aliases` and `subtypes`. **Any other `_`-prefixed
key is a property** and becomes a column in `energypal_table()`. Numeric properties are orderable;
text ones (`_taxonomy_source`) are provenance and are deliberately *not* offered as orderings.

An entry is either a bare colour (`Coal: "#2C2C2C"`) or a map. Flat and nested palettes use the same
grammar, so a user's named vector round-trips through `energypal_create()` →
`energypal_write()` → hand-edit → `energypal(file =)` without restructuring.

### extends

Overrides are written flat but applied wherever the name occurs in the parent, **at any depth**,
including inside `subtypes`. A bare colour over a full node changes the colour and keeps the labels
and aliases. `orders:` and `properties:` are inherited too — if they were not, a child would inherit
property *values* while losing the note that qualifies them.

**`_aliases` accumulate rather than replace.** A palette adding its source's wording ("Petroleum",
"Nuclear Electric Power") is widening the vocabulary the matcher understands; overwriting would
quietly drop "natural gas" from a palette that happens to call gas "Gas".

### Families

An atlas publishes several quantities and styles each differently. Those are separate palettes named
`family_measure`, grouped by `meta.family` and distinguished by `meta.measure`. They are **not
interchangeable**. One member carries `meta.default: true`, which makes the bare family name resolve
to it (`energypal("windatlas")` → `windatlas_speed`).

### Continuous palettes

`meta.type: continuous` (or an unnamed `colors:` sequence). Stops are ordered low to high and may
declare `breaks:`, with the convention `n_colors == n_breaks + 1` — the two extra bins are the
open-ended ones below the first break and above the last. For a continuous palette `n`
**interpolates** rather than truncating, and the result is unnamed, as with `viridis(n)`.

## Rules that are enforced, and why

- **Orderings and numeric properties are presentation only.** They arrange legends and chart series.
  They are indicative values, not validated figures, and must not be used in calculations. Every
  declared ordering and property carries a `_note` saying so; `energypal_validate()` **fails**
  a declaration that omits it. The note also travels as a column attribute
  (`attr(tab$carbon_intensity, "note")`) so it is answerable at the point of use. Do not add an
  ordering or property without one.
- **A palette shows only what its own source publishes.** `extends` inherits the taxonomy — names,
  labels, aliases, hierarchy, orderings — and never colours. A carrier the source is silent about
  comes back unmapped, reported as `unpublished` by `energypal_match()`. Do not "fill in" a palette
  from the default; that is a claim its source never made.
- **Do not invent colours.** The value of this store is provenance. In strict mode (the default)
  `energypal_validate()` **fails** a palette with no `meta.license`, and one declaring CC BY without
  both `meta.attribution` and an `https://` link to the licence deed. `strict = FALSE` skips those
  rules and is what `energypal_register()` uses — your own colours need no paperwork.
  If colours cannot be traced, say so plainly rather than implying an official scheme: see
  `windatlas_speed.yml`, which states that it approximates the atlas. Where provenance is unusable
  the palette does not ship — `drafts/v0-palettes/merra2ools_ghi.yml` was measured against the
  official GSA poster, found not to be it, and archived.
- **Check the licence before adding a palette from a new source.** The permissive sources are not
  the ones you would expect: the World Bank atlases are CC BY, the IEA is restrictive. Both atlases
  forbid automated access to their applications, so a scale must come from a downloadable Work — and
  the GWA data downloads contain no colour table at all, only float rasters. The full per-source
  notes are in `dev/references/palette-licences.md`, which is local-only; do not cite that path from
  anything that ships.
- **Archive, do not delete.** Superseded code moves to `drafts/`. `drafts/v0-static-palettes/` and
  `drafts/v0-deprecated/` both contain a `palettes.R` and **they are not the same file** — the
  former holds the real pre-2025 palette definitions, the latter is the tombstone
  (`energy_palettes <- NULL`). Do not let one shadow the other when moving things around.

## Traps that have already bitten

- **`energypal_table()` returns duplicate names.** Six entries exist twice — `Nuclear`, `Other`,
  `Electricity`, `Heat`, `Hydrogen`, `Storage` are each a group *and* the single carrier inside it.
  Any join on `name` must `filter()`/`distinct()` first or it fans the data out. This produced a
  silent many-to-many in the README's carbon-intensity ranking.
- **Do not rebuild the binned scale on `scale_*_stepsn()`.** That function treats `colours` as a
  gradient to *sample by data position*, so the palette's declared bins only appear when the data
  happens to span exactly the declared breaks. `scales.R` uses `binned_scale()` with an identity
  `rescaler`, so bin midpoints arrive in data units and `.bin_palette()` indexes them by
  `findInterval()`. Before that fix, 20 m/s and 27 m/s both drew as the 25th of 31 stops.
- **pkgdown does not re-knit an article when only a palette changes.** It compares the `.Rmd`, not
  what the code reads, so editing a YAML leaves stale figures on the site. After any palette change
  rebuild with `pkgdown::build_site(lazy = FALSE)`.
- **pkgdown inverts plots in dark mode** (`filter: invert(100%) hue-rotate(180deg)` on `img.r-plt`),
  which is fatal for a colour reference — every swatch would render as something else.
  `pkgdown/extra.scss` overrides it to `filter: none`. Do not remove that file.
- **The README uses non-CRAN packages** (`merra2sample`, `merra2ools`, for the real MERRA-2 resource
  map). That is safe only because `README.Rmd` is `.Rbuildignore`d and pkgdown builds the home page
  from the committed `README.md`. Do not move that example into a vignette, which *is* checked.

## Style

Prose and examples follow the tidyverse conventions used across optimal2050: `dplyr` verbs and the
native pipe in vignettes and the README, not `[` subsetting or `match()`. Select palettes by name
and print the vector before using it, rather than inlining `info$name[info$type == "discrete"]`.

## Adding a palette

One new YAML file. No R changes, no registration, no test edits — the validator tests iterate over
the directory, so a new file is picked up automatically and checked for: `meta.name` matching the
filename, valid hex, `extends` resolving, monotonic breaks, family rules, the `_note` requirement,
and the licence rules above.

## Development

```r
devtools::document()        # after any roxygen change
devtools::load_all()
devtools::test()
devtools::check()           # target: no more than the "New submission" NOTE
devtools::build_readme()    # after any change a README figure depends on
pkgdown::build_site(lazy = FALSE)
```

`R CMD check --as-cran` should stay at **1 NOTE** ("New submission"), which a first submission
cannot avoid. Anything else is a regression.

Version runs as `0.1.0.9000` during development; the `.9000` suffix comes off only at release.

### Tests

Tests iterate over `energypal_info()` rather than hard-coding palette names, so they cover new
files automatically. Where a test does name a palette, it is because the assertion is about that
palette specifically.

Regressions worth knowing about, each pinned by a test:

- Every `unique(owid_energy_mix$source)` must resolve to a colour in `carriers` and `technologies`,
  and must at minimum be *recognised* in every palette — the answer is a colour or an explicit
  `unpublished`, never a shrug. The package could not colour its own example dataset for a while.
- A colourless entry must not outrank an alias that has a colour. "Natural Gas" names a subtype
  `ipcc` gives no colour; it must still reach `FossilGas`.
- Containment matches must be anchored at one end. "other" is a substring of "geothermal".
- Plant-level names must resolve: `CCGT_Pembroke`, `Wind_DoggerBank`, `Solar_Shotwick`.
- `energypal_gradient()` must yield `n` distinct colours for every carrier. The previous HSV
  implementation silently collapsed bright colours — Solar and Nuclear gave one colour for five.
- Ordering must permute without changing the colour assigned to any carrier.
- The binned scale must give every bin its own declared colour, in order, with out-of-range values
  taking the first and last.
- `windatlas_speed` and `solaratlas_ghi` must share no colour position-for-position.
- No shipped file may reference `dev/`, `drafts/` or `data-raw/`.
