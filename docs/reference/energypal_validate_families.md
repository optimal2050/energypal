# Check the family structure of the built-in palettes

Validates relationships *between* palette files, which
[`energypal_validate()`](https://optimal2050.github.io/energypal/reference/energypal_validate.md)
cannot see because it inspects one file at a time: each family must have
exactly one default member, and `measure` must be unique within a
family.

## Usage

``` r
energypal_validate_families()
```

## Value

Invisibly `TRUE`. Throws an error listing every problem found.

## See also

[`energypal_validate()`](https://optimal2050.github.io/energypal/reference/energypal_validate.md),
[`energypal_info()`](https://optimal2050.github.io/energypal/reference/energypal_info.md)

## Examples

``` r
energypal_validate_families()
```
