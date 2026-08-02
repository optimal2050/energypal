# Custom Mapping Function Support in Energypal

## Overview

The energypal package now supports custom mapping functions through dedicated scale functions, allowing users to implement their own color mapping logic while leveraging the package's infrastructure.

## New Functions

### `scale_color_energy_custom()` and `scale_fill_energy_custom()`

These functions allow users to provide custom mapping functions that will be called with energy source names and can return custom color mappings.

## Usage Pattern

```r
library(ggplot2)
library(energypal)

# Define a custom mapping function
my_custom_mapper <- function(sources, intensity = 0.4, boost_renewables = TRUE) {
  # Start with standard energy color mapping
  colors <- map_energy_colors(sources, apply_variations = TRUE, 
                             variation_intensity = intensity)
  
  # Apply custom modifications
  if (boost_renewables && "Solar" %in% names(colors)) {
    colors["Solar"] <- "#FFD700"  # Make solar gold
  }
  
  if ("Coal" %in% names(colors)) {
    colors["Coal"] <- "#1a1a1a"  # Make coal darker
  }
  
  return(colors)
}

# Use in ggplot2
ggplot(energy_data, aes(x = year, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy_custom(
    mapping_function = my_custom_mapper,
    intensity = 0.6,
    boost_renewables = TRUE
  )
```

## Function Signature

```r
scale_fill_energy_custom(
  mapping_function,      # Required: function(sources, ...)
  data = NULL,          # Optional: data frame to extract sources from
  source_column = "source", # Column name if using data
  fallback_palette = NULL,  # Fallback if function fails
  guide = "legend",     # Legend guide type
  ...                   # Additional arguments passed to mapping_function
)
```

## Custom Function Requirements

Your custom mapping function must:

1. **Take `sources` as the first argument**: A character vector of energy source names
2. **Return a named character vector**: Colors with names matching the source names
3. **Handle any number of sources**: The function may be called with different source combinations

Example function signature:
```r
my_mapper <- function(sources, custom_param1 = "default", custom_param2 = 123) {
  # Your logic here
  colors <- c("Coal" = "#2C2C2C", "Solar" = "#FFA500", "Wind" = "#87CEEB")
  return(colors[sources])  # Return only requested sources
}
```

## Error Handling

- If the custom function fails, the scale will fall back to the specified `fallback_palette`
- If a function is passed to the standard `scale_*_energy()` functions, it will throw an informative error directing users to the custom scale functions

## Alternative Approaches

### 1. Pre-compute colors with `add_energy_colors()`
```r
# Pre-compute colors
data_with_colors <- add_energy_colors(energy_data, source_column = "source")

# Apply custom modifications
custom_colors <- my_custom_mapper(unique(energy_data$source))
data_with_colors$custom_colors <- custom_colors[data_with_colors$source]

# Use identity scale
ggplot(data_with_colors, aes(x = year, y = value, fill = custom_colors)) +
  geom_col() +
  scale_fill_identity()
```

### 2. Use with existing mapping infrastructure
```r
my_mapper <- function(sources, palette_name = "renewable_focus", ...) {
  # Leverage existing energypal functions
  return(map_energy_colors(sources, palette_name = palette_name, ...))
}
```

## Benefits

1. **Maximum flexibility**: Implement any color mapping logic
2. **Integration with existing tools**: Can use `map_energy_colors()` and other energypal functions
3. **Parameter passing**: Pass custom parameters through `...`
4. **Error safety**: Automatic fallback if custom function fails
5. **Clean API**: Dedicated functions for custom vs. standard mapping

This feature enables advanced users to implement sophisticated color mapping strategies while maintaining the simplicity of the standard scales for common use cases.