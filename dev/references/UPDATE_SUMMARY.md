# energypal Package Updates - September 2025

## Major Improvements Implemented

### 1. Color Ordering by Carbon Intensity and Intermittency

All palettes have been reordered to follow energy sector logic:

**Carbon Intensity Hierarchy (High → Low)**:
- Coal (1000+ kg CO2/MWh) 
- Oil (800-900 kg CO2/MWh)
- Natural Gas (400-500 kg CO2/MWh)
- Nuclear (10-20 kg CO2/MWh)
- Renewables (0-50 kg CO2/MWh)

**Within Categories - Dispatchability Order**:
- Dispatchable sources first (controllable output)
- Variable sources last (weather-dependent)

**Example - IEA Primary Palette Order**:
Coal → Oil → Natural Gas → Nuclear → Bioenergy → Geothermal → Hydro → Other Renewables → Wind → Solar

This creates intuitive visual progressions in stacked charts where the visual flow represents the energy transition from high-carbon to low-carbon sources.

### 2. Dark Theme Compatibility

Enhanced display functions with solid background support:

- `display_energy_palette()` - Added `background_color` parameter
- `show_all_energy_palettes()` - Added background and contrast support
- Automatic text color adjustment (black on white, white on dark)
- Semi-transparent background boxes for label readability

**Usage**:
```r
# Light theme (default)
display_energy_palette("iea_primary")

# Dark theme
display_energy_palette("iea_primary", background_color = "#2D2D2D")
```

### 3. Comprehensive Palettes Vignette

Created `vignettes/palettes.Rmd` with complete documentation:

- Visual display of all six palettes
- Individual palette details with source attribution
- Color ordering principles explanation
- Usage examples with both light and dark themes
- Accessibility guidelines
- Best practices for palette selection

### 4. Documentation Cleanup

Removed emoji characters from all documentation files:

- `README.md` - Professional appearance for academic/corporate use
- `SOURCES_QUICK_REF.md` - Clean reference format
- All markdown files - Consistent professional tone

### 5. Enhanced Source Attribution

Each palette now includes detailed inline comments:

```r
# IEA-inspired palette (World Energy Outlook style)
# Source: IEA World Energy Outlook 2023, Figure 1.6 "Global electricity generation by source"
# URL: https://www.iea.org/reports/world-energy-outlook-2023
# Ordered by carbon intensity: high to low, then by intermittency
iea_primary = c(
  "Coal" = "#2C2C2C",     # Highest carbon intensity
  "Oil" = "#8B4513",      # High carbon intensity
  # ... (continues in logical order)
  "Solar" = "#FFA500"     # Lowest carbon, highest intermittency
)
```

## Technical Benefits

### Visual Consistency
- Stacked charts naturally show energy transition story
- Color progression indicates environmental impact
- Intuitive ordering for energy sector audiences

### Professional Quality
- Clean documentation suitable for academic papers
- Corporate-friendly appearance without distracting elements
- Comprehensive source citations for credibility

### Accessibility
- Dark theme support for modern web interfaces
- High contrast text overlays for readability
- Professional color choices tested for accessibility

### User Experience
- Logical color ordering requires no manual reordering
- Background compatibility works out-of-the-box
- Comprehensive vignette provides all needed information

## Package Structure After Updates

```
energypal/
├── R/
│   ├── palettes.R       # ✓ Reordered palettes with source comments
│   ├── mapping.R        # ✓ Unchanged (working correctly)
│   ├── scales.R         # ✓ Unchanged (working correctly)
│   ├── utils.R          # ✓ Enhanced with background support
│   └── data.R           # ✓ Unchanged (working correctly)
├── vignettes/
│   ├── getting-started.Rmd  # ✓ Basic usage guide
│   └── palettes.Rmd         # ✓ NEW: Comprehensive palette reference
├── tests/               # ✓ Working correctly
├── data/               # ✓ Sample datasets ready
├── README.md           # ✓ Clean, professional documentation
├── COLOR_REFERENCES.md # ✓ Detailed source documentation
└── SOURCES_QUICK_REF.md # ✓ Quick reference without emoji
```

## Usage Examples

### Basic Ordered Visualization
```r
library(energypal)
library(ggplot2)

# The color order now tells the energy transition story
ggplot(data, aes(x = year, y = generation, fill = source)) +
  geom_col() +
  scale_fill_energy(palette = "iea_primary") +
  labs(subtitle = "Colors ordered from high-carbon (bottom) to low-carbon (top)")
```

### Dark Theme Compatible
```r
# Automatic dark theme support
show_all_energy_palettes(background_color = "#2D2D2D")
```

### Professional Documentation
All visualizations can now be used in:
- Academic papers (clean, source-cited)
- Corporate reports (professional appearance)
- Web applications (dark theme support)
- Policy documents (credible source attribution)

## Quality Assurance

All changes tested and verified:
- ✓ Palette ordering functions correctly
- ✓ Display functions work with backgrounds
- ✓ Documentation is clean and professional
- ✓ Source attribution is comprehensive
- ✓ Package loads and functions operate correctly

The `energypal` package now provides a professional, well-documented, and visually consistent solution for energy data visualization that follows industry best practices and energy sector conventions.