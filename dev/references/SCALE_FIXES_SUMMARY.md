# Summary of Scale Fixes Applied

## Issues Fixed

### 1. **Removed Hardcoded Source Lists** 
**Problem**: The `scale_fill_energy()` and `scale_color_energy()` functions were using a hardcoded list of `common_sources` that included sources like "Coal", "Oil", "Natural Gas", etc., regardless of what was actually present in the user's data. This caused legends to show unused sources.

**Solution**: 
- Removed the hardcoded `common_sources` list
- Made the scale completely data-driven by creating a dynamic palette function when no data is provided
- When data is provided, the scale only works with sources actually present in that data
- The scale now uses the mapping function to guess source-to-color mappings dynamically

### 2. **Fixed Default Carbon Intensity Ordering**
**Problem**: The default `direction = 1` parameter meant that when using carbon intensity ordering, coal (highest carbon) appeared at the top of stacked charts instead of at the bottom.

**Solution**: 
- Changed default `direction` parameter from `1` to `-1` in both `scale_fill_energy()` and `scale_color_energy()`
- This ensures that when using `order_method = "carbon_intensity"`, coal appears at the bottom of stacked charts by default
- High-carbon sources (coal) stack from bottom, low-carbon sources (renewables) stack on top

## Technical Changes Made

### In `scale_fill_energy()`:
1. **Removed hardcoded logic**:
   ```r
   # OLD (removed):
   common_sources <- c("Coal","Oil","Natural Gas","Nuclear","Hydro","Wind","Solar",...)
   all_mapped <- map_energy_colors(common_sources, ...)
   combined_colors <- c(base_palette, all_mapped)
   
   # NEW: Dynamic data detection only
   present_sources <- NULL
   if (!is.null(data) && is.data.frame(data)) {
     # Detect sources from actual data
   }
   ```

2. **Added dynamic palette function**:
   - When no data is provided, creates a function that determines sources at plot time
   - When data is provided, works only with detected sources
   - Uses `map_energy_colors()` to intelligently map sources to colors

3. **Changed default direction**:
   ```r
   # OLD:
   direction = 1,
   
   # NEW:
   direction = -1,
   ```

### In `scale_color_energy()`:
- Applied identical changes as above for consistency

## Behavior Changes

### Before the Fix:
- **Legend Issue**: Legends showed all predefined sources (Coal, Oil, Gas, Nuclear, Hydro, Wind, Solar, etc.) even if only 2-3 were in the actual data
- **Ordering Issue**: Coal appeared at top of stacked charts by default when using carbon intensity ordering

### After the Fix:
- **Legend Fixed**: Legends only show sources that are actually present in the user's data
- **Ordering Fixed**: Coal appears at bottom of stacked charts by default, with low-carbon sources stacking on top
- **Fully Data-Driven**: Scales no longer depend on package assumptions about what sources might exist

## Backward Compatibility
- All existing function parameters remain the same
- Users can still override the default `direction = -1` by explicitly setting `direction = 1`
- The change only affects the default behavior, making it more intuitive

## Testing
The fixes ensure that:
1. `scale_fill_energy()` and `scale_color_energy()` only show legend entries for sources present in the data
2. Carbon intensity ordering puts coal at the bottom by default
3. The scale uses mapping functions to guess source-to-color mappings dynamically without depending on hardcoded lists