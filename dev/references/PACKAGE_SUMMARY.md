# energypal Package Summary

## 🎯 Package Overview

The `energypal` package is a comprehensive R package designed specifically for energy-related data visualizations. It provides curated color palettes inspired by major energy organizations (IEA, EPA, EIA) and intelligent functions for mapping energy sources to appropriate colors.

## 📦 Package Structure

```
energypal/
├── DESCRIPTION           # Package metadata and dependencies
├── NAMESPACE            # Exported functions and imports
├── README.md            # Package documentation and examples
├── LICENSE & LICENSE.md # AGPL-3 license files
├── R/                   # Main package code
│   ├── palettes.R       # Core palette definitions and functions
│   ├── mapping.R        # Intelligent color mapping functions
│   ├── scales.R         # ggplot2 scale extensions
│   ├── utils.R          # Utility functions for visualization
│   └── data.R           # Data documentation
├── data/                # Real-world datasets
│   └── owid_energy_mix.rda
├── tests/               # Unit tests
│   ├── testthat.R
│   └── testthat/
│       └── test-palettes.R
├── vignettes/           # Package documentation
│   └── getting-started.Rmd
├── man/                 # Function documentation (auto-generated)
└── docs/                # Package website (pkgdown)
```

## 🎨 Available Palettes

| Palette Name | Source | Description | Use Case |
|--------------|--------|-------------|----------|
| `iea_primary` | IEA World Energy Outlook | Comprehensive energy source colors | General energy analysis |
| `epa_ghg` | EPA GHG Inventory | Greenhouse gas focused palette | Emissions analysis |
| `eia_primary` | EIA Energy Reports | US-focused energy palette | US energy statistics |
| `renewable_focus` | Custom | Emphasizes renewable sources | Renewable energy analysis |
| `fossil_focus` | Custom | Traditional fossil fuel colors | Fossil fuel analysis |
| `technology_focus` | Custom | Energy technology palette | Technology comparisons |

## 🔧 Core Functions

### Palette Management
- `get_energy_palette_names()` - List available palettes
- `get_energy_palette(name)` - Retrieve specific palette
- `display_energy_palette(name)` - Visualize palette
- `add_energy_palette(name, colors)` - Add custom palette
- `validate_energy_palette(palette)` - Validate palette

### Intelligent Mapping
- `map_energy_colors(sources, method="auto")` - Smart color mapping
- `create_energy_mapping(include_variations=TRUE)` - Comprehensive mapping dictionary

### ggplot2 Integration
- `scale_fill_energy(palette)` - Fill scale for energy data
- `scale_color_energy(palette)` - Color scale for energy data
- `scale_fill_energy_manual()` - Manual with fallback

### Utilities
- `show_all_energy_palettes()` - Display all palettes
- `plot_energy_mix()` - Quick energy mix visualization
- `interpolate_energy_colors()` - Color interpolation
- `validate_energy_palette()` - Palette validation

## 📊 Sample Datasets

The package includes real-world energy data:

**`owid_energy_mix`** (1475+ rows)
- Electricity generation by source for major economies (2000-2024)
- Variables: country, iso_code, year, source, generation_twh, percentage, carbon_intensity_gco2_kwh
- Source: Our World in Data (OWID) Global Energy dataset

## 🚀 Key Features

### 1. Intelligent Color Mapping
```r
# Handles messy data automatically
sources <- c("coal power", "nat gas", "solar pv", "wind energy")
colors <- map_energy_colors(sources, method = "fuzzy")
```

### 2. Seamless ggplot2 Integration
```r
ggplot(data, aes(x = year, y = generation, fill = source)) +
  geom_col() +
  scale_fill_energy(palette = "iea_primary")
```

### 3. Multiple Mapping Methods
- **Exact**: Direct name matching
- **Fuzzy**: Partial string matching
- **Regex**: Pattern-based matching  
- **Auto**: Tries all methods sequentially

### 4. Extensible Architecture
- Easy to add new palettes
- Support for custom color schemes
- Validation and quality checks
- Session-based palette storage

## 🎯 Use Cases

### Primary Applications
1. **Fuel Mix Charts** - Electricity generation by source
2. **Capacity Visualizations** - Installed capacity by technology
3. **Energy Flow Diagrams** - Sankey diagrams with consistent colors
4. **Choropleth Maps** - Regional energy data mapping
5. **Time Series Analysis** - Energy trends over time
6. **Technology Comparisons** - Comparing different energy technologies

### Target Audiences
- Energy researchers and analysts
- Policy makers and consultants
- Data visualization specialists
- Academic researchers
- Energy sector professionals

## 📈 Examples

### Basic Energy Mix Chart
```r
library(energypal)
library(ggplot2)

data(owid_energy_mix)
ggplot(owid_energy_mix, aes(x = year, y = percentage, fill = source)) +
  geom_col() +
  scale_fill_energy() +
  facet_wrap(~country) +
  labs(title = "Energy Mix by Country")
```

### Technology Generation Analysis
```r
data(owid_energy_mix)
latest_year <- max(owid_energy_mix$year)
tech_data <- subset(owid_energy_mix, year == latest_year)
ggplot(tech_data, aes(x = country, y = generation_twh, fill = source)) +
  geom_col() +
  scale_fill_energy(palette = "technology_focus") +
  coord_flip()
```

## 🔬 Technical Specifications

### Dependencies
- **Required**: R (>= 3.6.0), ggplot2 (>= 3.3.0), scales, grDevices, utils
- **Suggested**: testthat, knitr, rmarkdown, dplyr, tidyr, sf, maps

### Standards
- Follows CRAN package standards
- Comprehensive documentation with roxygen2
- Unit tests with testthat
- Vignettes for user guidance
- AGPL-3 license for open source use

### Quality Assurance
- Automated testing framework
- Color validation functions
- Accessibility considerations
- Consistent naming conventions
- Error handling and user feedback

## 🔮 Future Enhancements

### Planned Features
1. **More Palettes**: Additional organization-inspired palettes
2. **Accessibility**: Colorblind-friendly palette variants
3. **Interactive Tools**: Shiny app for palette exploration
4. **Data Integration**: Direct connections to energy databases
5. **Continuous Scales**: Support for continuous color mapping
6. **Animation Support**: Colors for animated energy visualizations

### Community Contributions
- User-submitted palettes from energy organizations
- Regional palette variations
- Industry-specific color schemes
- Documentation improvements and translations

## 📞 Support and Resources

- **Documentation**: Comprehensive function documentation and vignettes
- **Examples**: Real-world use cases and code examples
- **Testing**: Extensive unit test suite for reliability
- **Community**: Open to contributions and feedback
- **License**: AGPL-3 for open source compatibility

---

**Created**: September 2025  
**Version**: 0.0.0.9000 (Development)  
**Maintainer**: Energy Developer <developer@example.com>  
**Repository**: https://github.com/optimal2050/energypal