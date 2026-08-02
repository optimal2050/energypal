# Quick Reference Guide for energypal Color Sources

## Primary Sources by Palette

### IEA Primary (`iea_primary`)
- **Source**: IEA World Energy Outlook 2023
- **Key Document**: Figure 1.6 "Global electricity generation by source"
- **URL**: https://www.iea.org/reports/world-energy-outlook-2023

### EPA GHG (`epa_ghg`)  
- **Source**: EPA Inventory of U.S. Greenhouse Gas Emissions and Sinks: 1990-2021
- **Key Document**: Chapter 2 "Trends in Greenhouse Gas Emissions"
- **URL**: https://www.epa.gov/ghgemissions/inventory-us-greenhouse-gas-emissions-and-sinks-1990-2021

### EIA Primary (`eia_primary`)
- **Source**: EIA Annual Energy Outlook 2023
- **Key Document**: Figure ES-1 "Energy consumption by source"  
- **URL**: https://www.eia.gov/outlooks/aeo/

### Renewable Focus (`renewable_focus`)
- **Source**: IRENA Global Energy Transformation + REN21 Global Status Report
- **Key Documents**: Various renewable energy technology reports
- **URLs**: https://www.irena.org/publications + https://www.ren21.net/gsr-2023/

### Fossil Focus (`fossil_focus`)
- **Source**: BP Statistical Review of World Energy 2023
- **Key Document**: Energy mix and resource classifications
- **URL**: https://www.bp.com/en/global/corporate/energy-economics/statistical-review-of-world-energy.html

### Technology Focus (`technology_focus`)
- **Source**: IEA Energy Technology Perspectives 2023
- **Key Document**: Technology-specific analyses and roadmaps
- **URL**: https://www.iea.org/reports/energy-technology-perspectives-2023

## How Colors Were Selected

1. **Visual Analysis**: Examined official charts and figures from source organizations
2. **Color Extraction**: Used color picker tools on high-resolution PDFs and web graphics  
3. **Standardization**: Converted to hex codes for R compatibility
4. **Validation**: Tested for accessibility, contrast, and distinctiveness
5. **Industry Alignment**: Verified colors match established sector conventions

## Legal and Attribution Notes

- All sources are publicly available documents
- Colors extracted from publicly visible charts and figures
- No proprietary color schemes directly copied
- Represents interpretation of established industry conventions
- Suitable for academic, research, and commercial use

## Quick Usage Examples

```r
library(energypal)

# View source info for a palette
get_energy_palette("iea_primary")
# Colors based on IEA World Energy Outlook 2023

# Use in ggplot with source attribution
ggplot(data, aes(x = year, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy(palette = "iea_primary") +
  labs(caption = "Colors adapted from IEA World Energy Outlook 2023")
```

## For More Details

See the complete [`COLOR_REFERENCES.md`](COLOR_REFERENCES.md) file for:
- Detailed methodology
- Specific figure references  
- Color selection rationale
- Fair use considerations
- Contribution guidelines

---

**Quick Tip**: When citing your visualizations, you can reference both the `energypal` package and the original source organization to provide full attribution!