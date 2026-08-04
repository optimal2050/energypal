# energypal — working notes

Colour palettes for energy data visualisation. Palettes are **data, not
code**: they live as YAML files under `inst/extdata/palettes/`, one file
per palette, and adding one should never require touching R.

## Layout

    R/                      package code
      palettes.R            palette store: loading, extends-merge, registry, validation
      energypal.R           flattening a palette into a table, and into a colour vector
      order.R               ordering resolution and energypal_orders()
      mapping.R             matching data labels to palette entries
      display.R             energypal_show()
      zzz.R                 package-local cache environment
    inst/extdata/palettes/  the palettes themselves - see below
    dev/references/         palette provenance: sources, colour rationale, known gaps
    drafts/                 archived code, kept for reference, excluded from the build

`dev/` and `drafts/` are in `.Rbuildignore`; they are documentation and
history, not package content.

## Palette files

A palette is a `meta:` block plus a `colors:` block. Nesting lives
*inside* a file; there is deliberately no second lookup dimension (no
`section`, no `variant`) — one name, one palette. `family` and `measure`
are discovery metadata that shape the *name*, not a second key to look
up by.

``` yaml
meta:
  name: ipcc              # must match the filename
  title: "..."
  source: "..."           # where the colours came from
  url: "..."
  license: "..."          # REQUIRED: how the colours were obtained
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

Reserved keys are `_color`, `_short`, `_long`, `_aliases` and
`subtypes`. **Any other `_`-prefixed key is a property** and becomes a
column in
[`energypal_table()`](https://optimal2050.github.io/energypal/reference/energypal_table.md).

An entry is either a bare colour (`Coal: "#2C2C2C"`) or a map. Flat and
nested palettes use the same grammar, so a user’s named vector
round-trips through
[`energypal_create()`](https://optimal2050.github.io/energypal/reference/energypal_create.md)
→
[`energypal_write()`](https://optimal2050.github.io/energypal/reference/energypal_write.md)
→ hand-edit → `energypal(file =)` without restructuring.

### extends

Overrides are written flat but applied wherever the name occurs in the
parent, **at any depth**, including inside `subtypes`. A bare colour
over a full node changes the colour and keeps the labels and aliases.
`orders:` and `properties:` are inherited too — if they were not, a
child would inherit property *values* while losing the note that
qualifies them.

### Families

An atlas publishes several quantities and styles each differently. Those
are separate palettes named `family_measure`, grouped by `meta.family`
and distinguished by `meta.measure`. They are **not interchangeable**.
One member carries `meta.default: true`, which makes the bare family
name resolve to it (`energypal("windatlas")` → `windatlas_speed`).

### Continuous palettes

`meta.type: continuous` (or an unnamed `colors:` sequence). Stops are
ordered low to high and may declare `breaks:`, with the convention
`n_colors == n_breaks + 1`. For a continuous palette `n`
**interpolates** rather than truncating, and the result is unnamed, as
with `viridis(n)`.

## Rules that are enforced, and why

- **Orderings and numeric properties are presentation only.** They
  arrange legends and chart series. They are indicative values, not
  validated figures, and must not be used in calculations. Every
  declared ordering and property carries a `_note` saying so;
  [`energypal_validate()`](https://optimal2050.github.io/energypal/reference/energypal_validate.md)
  **fails** a declaration that omits it. The note also travels as a
  column attribute (`attr(tab$carbon_intensity, "note")`) so it is
  answerable at the point of use. Do not add an ordering or property
  without one.
- **A palette shows only what its own source publishes.** `extends`
  inherits the taxonomy — names, labels, aliases, hierarchy, orderings —
  and never colours. A carrier the source is silent about comes back
  unmapped, reported as `unpublished` by
  [`energypal_match()`](https://optimal2050.github.io/energypal/reference/energypal_match.md).
  Do not “fill in” a palette from the default; that is a claim its
  source never made.
- **Do not invent colours.** The value of this store is provenance.
  [`energypal_validate()`](https://optimal2050.github.io/energypal/reference/energypal_validate.md)
  **fails** a palette with no `meta.license`, and one declaring CC BY
  with no `meta.attribution`. If colours cannot be traced, say so
  plainly rather than implying an official scheme — see
  `windatlas_speed.yml`, which says plainly that it approximates the
  atlas. Where provenance is unusable the palette does not ship:
  `drafts/v0-palettes/merra2ools_ghi.yml` was measured against the
  official GSA poster, found not to be it, and archived. Missing
  measures belong in `dev/references/resource-palettes-todo.md`, not
  guessed at.
- **Read `dev/references/palette-licences.md` before adding a palette
  from a new source.** The permissive sources are not the ones you would
  expect: the World Bank atlases are CC BY, the IEA is restrictive. Both
  atlases forbid automated access to their applications, so a scale must
  come from a downloadable Work — and the GWA data downloads contain no
  colour table at all.
- **Archive, do not delete.** Superseded code moves to `drafts/`.
  `drafts/v0-static-palettes/` and `drafts/v0-deprecated/` both contain
  a `palettes.R` and **they are not the same file** — the former holds
  the real pre-2025 palette definitions, the latter is the tombstone
  (`energy_palettes <- NULL`). Do not let one shadow the other when
  moving things around.

## Adding a palette

One new YAML file. No R changes, no registration, no test edits — the
validator tests iterate over the directory, so a new file is picked up
automatically and checked for: `meta.name` matching the filename, valid
hex, `extends` resolving, monotonic breaks, family rules, and the
`_note` requirement.

## Development

``` r

devtools::document()        # after any roxygen change
devtools::load_all()
devtools::test()
devtools::check()           # target: no more than the "New submission" NOTE
```

`R CMD check --as-cran` should stay at **1 NOTE** (“New submission”),
which a first submission cannot avoid. Anything else is a regression.

Version runs as `0.1.0.9000` during development; the `.9000` suffix
comes off only at release.

### Tests

Tests iterate over
[`energypal_info()`](https://optimal2050.github.io/energypal/reference/energypal_info.md)
rather than hard-coding palette names, so they cover new files
automatically. Where a test does name a palette, it is because the
assertion is about that palette specifically.

Regressions worth knowing about, each pinned by a test:

- Every `unique(owid_energy_mix$source)` must resolve to a colour in
  `carriers` and `technologies`, and must at minimum be *recognised* in
  every palette — the answer is a colour or an explicit `unpublished`,
  never a shrug. The package could not colour its own example dataset
  for a while.
- A colourless entry must not outrank an alias that has a colour.
  “Natural Gas” names a subtype `ipcc` gives no colour; it must still
  reach `FossilGas`.
- Containment matches must be anchored at one end. “other” is a
  substring of “geothermal”.
- `energy_gradient()` must yield `n` distinct colours for every carrier.
  The previous HSV implementation silently collapsed bright colours —
  Solar and Nuclear gave one colour for five.
- Ordering must permute without changing the colour assigned to any
  carrier.
- `windatlas_speed` and `solaratlas_ghi` must share no colour
  position-for-position.
