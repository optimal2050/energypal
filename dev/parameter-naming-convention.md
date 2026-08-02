# Parameter Naming Convention - Energypal Package

## Final Parameter Naming

The energypal package now uses consistent and descriptive parameter names that reflect their actual data types and usage:

### Standard Scale Functions
**For character string-based mapping methods:**

- `scale_color_energy(mapping_method = "auto")`
- `scale_fill_energy(mapping_method = "fuzzy")`
- `scale_color_energy_mapped(mapping_method = "exact")`
- `scale_fill_energy_mapped(mapping_method = "regex")`

**Valid `mapping_method` values:**
- `"auto"` - Try exact, then fuzzy, then regex matching
- `"exact"` - Only exact string matches
- `"fuzzy"` - Partial string matching (substrings)
- `"regex"` - Regular expression matching

### Custom Scale Functions
**For actual function objects:**

- `scale_color_energy_custom(mapping_function = my_function)`
- `scale_fill_energy_custom(mapping_function = my_function)`

**`mapping_function` requirements:**
- Must be a function that takes `sources` as first argument
- Must return a named character vector of colors
- Can accept additional parameters via `...`

## Rationale

1. **`mapping_method`** clearly indicates this parameter expects a **method name** (character string)
2. **`mapping_function`** clearly indicates this parameter expects an actual **function object**
3. **Semantic clarity**: The parameter name reflects the data type and usage pattern
4. **Consistency**: Standard scales use `method`, custom scales use `function`
5. **Error prevention**: Different names reduce confusion about which parameter accepts what

## Examples

### Standard Mapping Methods
```r
library(ggplot2)

# Using character string methods
ggplot(energy_data, aes(x = year, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy(mapping_method = "fuzzy")
```

### Custom Mapping Functions
```r
# Define custom function
my_custom_mapper <- function(sources, boost_solar = TRUE) {
  colors <- map_energy_colors(sources)
  if (boost_solar && "Solar" %in% names(colors)) {
    colors["Solar"] <- "#FFD700"
  }
  return(colors)
}

# Use function object
ggplot(energy_data, aes(x = year, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy_custom(mapping_function = my_custom_mapper, boost_solar = TRUE)
```

## Migration from Previous Versions

If upgrading from a version that used `mapping_function` for character strings:

**Before:**
```r
scale_fill_energy(mapping_function = "auto")
```

**After:**
```r
scale_fill_energy(mapping_method = "auto")
```

The old parameter name will generate a helpful error message directing users to the correct function and parameter.

This naming convention provides clear semantic distinction between method names and function objects, making the API more intuitive and self-documenting.