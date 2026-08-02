# Recent Energypal Package Improvements

This document summarizes the recent improvements made to the energypal package.

## Summary of Changes

### 1. Default Palette System Improvements
- **Fixed hardcoded defaults**: Replaced all hardcoded "iea_primary" references with `get_default_energy_palette()` calls
- **Consistent behavior**: All functions now respect the user's default palette settings
- **Files modified**: `R/mapping.R`, `R/scales.R`, `R/utils.R`

### 2. Parameter Naming Consistency
- **Renamed parameter**: Changed `mapping_method` to `mapping_function` in all scale functions for better consistency
- **Updated functions**: 
  - `scale_color_energy()`
  - `scale_fill_energy()`
  - `scale_color_energy_mapped()`
  - `scale_fill_energy_mapped()`
- **Files modified**: `R/scales.R`

### 3. New Utility Functions
- **`add_energy_colors()`**: Adds a color column to data frames based on energy source mappings
  - Auto-detects source column names if not specified
  - Supports all mapping options including variations
  - Adds metadata attributes to the result
- **`get_color_mapping_from_data()`**: Extracts color mappings from data frames with color columns
- **Files modified**: `R/utils.R`

### 4. New Scale Identity Functions
- **`scale_fill_energy_identity()`**: For data that already has color column
- **`scale_color_energy_identity()`**: For data that already has color column
- **Use case**: When colors are pre-computed using `add_energy_colors()`
- **Files modified**: `R/scales.R`

### 5. Bug Fixes
- **Fixed logical condition error**: Resolved "length = 3 in coercion to logical(1)" error in fuzzy matching
- **Fixed indexing issue**: Corrected logical vector vs numeric indices issue in mapping functions
- **Removed deprecation warnings**: Removed deprecated `scale_name` parameter from `discrete_scale()` calls
- **Files modified**: `R/mapping.R`, `R/scales.R`

## Functionality Verification

All functionality has been tested and verified:

✅ **Default palette system**: Works correctly with set/get/reset functions  
✅ **Parameter consistency**: All `mapping_function` parameters working  
✅ **Color variations**: Automatic generation for duplicate sources working  
✅ **Utility functions**: Data frame color column operations working  
✅ **ggplot2 integration**: All scale functions working without warnings  
✅ **Fuzzy matching**: Fixed logical condition error, now works correctly  

## API Changes Summary

### Breaking Changes
- `mapping_method` parameter renamed to `mapping_function` in scale functions

### New Functions
- `add_energy_colors()` - Add color column to data frame
- `get_color_mapping_from_data()` - Extract color mappings from data
- `scale_fill_energy_identity()` - Identity scale for pre-colored data
- `scale_color_energy_identity()` - Identity scale for pre-colored data

### Behavioral Changes
- All functions now use default palette instead of hardcoded "iea_primary"
- Auto-detection of source column names in `add_energy_colors()`

## Usage Examples

```r
# 1. Set global default and use across functions
set_default_energy_palette("renewable_focus")
colors <- map_energy_colors(c("Coal", "Solar", "Wind"))
# Uses renewable_focus palette automatically

# 2. Add colors directly to data frame
df <- data.frame(source = c("Coal", "Solar", "Wind"), value = c(30, 45, 25))
df_with_colors <- add_energy_colors(df)  # Auto-detects 'source' column

# 3. Use pre-computed colors in ggplot2
library(ggplot2)
ggplot(df_with_colors, aes(x = source, y = value, fill = energy_color)) +
  geom_col() +
  scale_fill_energy_identity()

# 4. Use renamed parameter in scales
ggplot(df, aes(x = source, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy(mapping_function = "fuzzy", apply_variations = TRUE)
```

## Next Steps

The package is now feature-complete with improved API consistency and robust functionality. All user-requested improvements have been implemented and tested.