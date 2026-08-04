# Validate a palette specification

Checks a palette for the problems that would otherwise surface as
confusing behaviour much later: a missing or misnamed `meta` block,
colours that are not hex, an `extends` target that does not exist, and
duplicate entry names.

## Usage

``` r
energypal_validate(x, name = NULL, strict = TRUE)
```

## Arguments

- x:

  A palette specification (from
  [`energypal_spec()`](https://optimal2050.github.io/energypal/reference/energypal_spec.md)
  or
  [`energypal_create()`](https://optimal2050.github.io/energypal/reference/energypal_create.md)),
  or a path to a palette file.

- name:

  Optional expected palette name, checked against `meta$name`.

- strict:

  Also require provenance. `TRUE` by default, since the usual reason to
  call this directly is to check a palette meant for sharing.

## Value

Invisibly `TRUE`. Throws an error describing every problem found.

## Details

Used by the package's own test suite across every built-in palette, and
by
[`energypal_register()`](https://optimal2050.github.io/energypal/reference/energypal_register.md)
before accepting a user file.

## Strict mode

`strict = TRUE` additionally requires provenance: a `meta$license`
saying how the colours were obtained, and, where that licence is a CC BY
variant, the `meta$attribution` it requires. This is the standard every
palette in the package must meet, and what a contributed palette is held
to.

It is *not* applied to palettes you register yourself. Your own colours
need no licence statement, and
[`energypal_register()`](https://optimal2050.github.io/energypal/reference/energypal_register.md)
validates leniently so that a project palette is a two-line file rather
than a paperwork exercise.

## Examples

``` r
# your own colours: structure only
energypal_validate(energypal_create(c(Coal = "#2C2C2C")), strict = FALSE)

# what a shipped palette must satisfy
energypal_validate(energypal_spec("owid"), name = "owid")
```
