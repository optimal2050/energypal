## R CMD check results

0 errors | 0 warnings | 1 note

```
* checking CRAN incoming feasibility ... NOTE
Maintainer: 'Oleg Lugovoy <olugovoy@optimalsolution.dev>'

New submission
```

* This is a new release, so the "New submission" note is expected.

## Test environments

* local Windows 11, R 4.5.3
* GitHub Actions: ubuntu-latest (devel, release, oldrel-1), macOS-latest
  (release), windows-latest (release)

## Notes for the reviewer

**Organisation names in palette names and titles.** Several palettes are named
after the published source whose colour conventions they follow — `eia`, `epa`,
`ipcc`, `owid`, `windatlas_speed`, `solaratlas_ghi`. This follows existing CRAN
practice (`ggthemes::theme_wsj`, `RColorBrewer`, `scico`).

No endorsement is implied, and the package says so in three places: each
palette's `meta.title` is qualified where the colours are approximate (for
example "IPCC AR6 WGIII energy supply (approximation)"), each palette file
carries a no-affiliation line in its header, and `inst/NOTICE` states it for the
package as a whole.

**Third-party content.** The palettes are data rather than code, and each records
its own terms in `meta.license`, with `meta.attribution` where a licence requires
a citation:

* Global Wind Atlas scales — CC BY 4.0 IGO, extracted from the published poster
  maps. The licence adds a binding condition naming the World Bank and ESMAP,
  reproduced verbatim in the palette.
* Global Solar Atlas scales — CC BY 4.0, likewise from the poster maps.
* EIA and EPA — approximated from US federal agency figures, public domain
  (17 U.S.C. 105).
* Our World in Data — approximated from published charts, CC BY 4.0.
* IPCC — approximated from a published figure; IPCC material may be reproduced
  with acknowledgement.

`inst/NOTICE` summarises all of this, as Apache 2.0 §4(d) provides for. It is
under `inst/` rather than at the top level so as not to trip the
non-standard-files check.

The bundled dataset `owid_energy_mix` is from Our World in Data under CC BY 4.0,
with its snapshot provenance attached as a `metadata` attribute.
