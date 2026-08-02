# Options System Migration - Energypal Package

## Migration from Package Environment to R `options()`

I've migrated the energypal package from using a private package environment (`.energypal_env`) to the standard R `options()` system. Here's why this is a significant improvement:

## Benefits of Using R `options()`

### 1. **Discoverability**
```r
# Users can now discover energypal options easily
options()  # Shows all options including energypal.* options

# Before: Hidden in package environment
# After: Visible in global options list
```

### 2. **Standard R Conventions**
```r
# Follows standard R package patterns used by:
# - ggplot2 (ggplot2.discrete.colour, etc.)
# - dplyr (dplyr.summarise.inform, etc.)  
# - knitr (knitr.table.format, etc.)
```

### 3. **Familiar User Experience**
```r
# Users expect package options to be in options()
getOption("energypal.default_palette")        # Standard approach
options(energypal.default_palette = "epa_ghg") # Direct setting

# Works with existing R workflows
.GlobalEnv$my_palette <- getOption("energypal.default_palette")
```

### 4. **Better Integration**
```r
# Integrates with R's option management
# - R CMD check compliance
# - Standard documentation patterns
# - Works with option restoration patterns

# Example: Temporary option changes with on.exit()
old_opts <- options(energypal.default_palette = "renewable_focus")
on.exit(options(old_opts))
```

## Implementation Details

### Prefixed Option Names
```r
# All options are prefixed to avoid naming conflicts
energypal.default_palette
energypal.enable_auto_variations  
energypal.variation_type
energypal.variation_intensity
# etc.
```

### Initialization on Package Load
```r
# Options are set when package loads (.onLoad)
# Only sets defaults if options don't already exist
# Preserves user's existing settings
```

### Backward Compatible API
```r
# Same user-facing functions work exactly the same
set_default_energy_palette("renewable_focus")
get_default_energy_palette()
set_energy_options(enable_auto_variations = TRUE)
get_energy_options("variation_type")

# Users don't need to change any code
```

## Comparison: Before vs After

### Before (Package Environment)
```r
# Hidden from users
.energypal_env$default_palette

# Not discoverable
options()  # No energypal options visible

# Package-specific access only
get_default_energy_palette()  # Only way to access
```

### After (R options())
```r
# Discoverable by users
options()  # Shows energypal.* options

# Standard R patterns
getOption("energypal.default_palette")
options(energypal.default_palette = "new_value")

# Still works with package functions
get_default_energy_palette()  # Convenience wrapper
```

## User Benefits

1. **Transparency**: Users can see all energypal settings
2. **Control**: Direct access to options if needed
3. **Integration**: Works with existing R option workflows
4. **Standards**: Follows R package conventions
5. **Documentation**: Options appear in help and can be documented

## Example Usage

```r
library(energypal)

# Check what energypal options are available
energypal_opts <- options()[grepl("^energypal\\.", names(options()))]
str(energypal_opts)

# Use standard R option patterns
old_palette <- getOption("energypal.default_palette") 
options(energypal.default_palette = "renewable_focus")
# ... do work ...
options(energypal.default_palette = old_palette)

# Or use the convenience functions
restore <- set_temporary_energy_palette("epa_ghg")
# ... do work ...
restore()
```

This migration makes energypal more professional, discoverable, and aligned with R package best practices while maintaining full backward compatibility for user code.