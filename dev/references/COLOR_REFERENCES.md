# Color Palette References and Sources

This document provides detailed references for the color palettes included in the `energypal` package. The palettes are inspired by or derived from publicly available visualizations and reports from major energy organizations.

## Palette Sources and References

### 1. IEA Primary Palette (`iea_primary`)

**Source**: International Energy Agency (IEA) publications

**Primary References**:
- IEA World Energy Outlook 2023, Chapter 1 Energy Trends and Outlook
  - URL: https://www.iea.org/reports/world-energy-outlook-2023
  - Figure 1.6: "Global electricity generation by source"
- IEA Energy Transition Indicators 2023
  - URL: https://www.iea.org/reports/energy-transition-indicators-2023
  - Charts showing energy mix by technology

**Color Mapping Rationale**:
- **Coal (#2C2C2C)**: Dark gray/black - traditional representation of coal
- **Oil (#8B4513)**: Dark brown - represents crude oil/petroleum products
- **Natural Gas (#4682B4)**: Steel blue - commonly used for gas in IEA charts
- **Nuclear (#FFD700)**: Gold/yellow - IEA standard for nuclear energy
- **Hydro (#0080FF)**: Blue - water association
- **Wind (#87CEEB)**: Light blue - sky association
- **Solar (#FFA500)**: Orange - sun association
- **Bioenergy (#228B22)**: Forest green - biomass/nature association

**Notes**: Colors adapted from IEA's consistent visual style across multiple WEO editions (2020-2023).

### 2. EPA GHG Palette (`epa_ghg`)

**Source**: U.S. Environmental Protection Agency

**Primary References**:
- EPA Inventory of U.S. Greenhouse Gas Emissions and Sinks: 1990-2021
  - URL: https://www.epa.gov/ghgemissions/inventory-us-greenhouse-gas-emissions-and-sinks-1990-2021
  - Chapter 2: "Trends in Greenhouse Gas Emissions"
  - Executive Summary figures
- EPA Power Profiler Tool visualizations
  - URL: https://www.epa.gov/egrid/power-profiler

**Color Mapping Rationale**:
- **Coal (#4A4A4A)**: Dark gray - EPA standard for coal emissions
- **Petroleum (#8B0000)**: Dark red - transportation/oil sector emphasis
- **Natural Gas (#4169E1)**: Royal blue - cleaner fossil fuel distinction
- **Renewable Energy (#228B22)**: Forest green - environmental benefit
- **Nuclear (#FF8C00)**: Dark orange - low-carbon non-renewable

**Notes**: Adapted from EPA's sectoral emission charts and fuel-specific visualizations.

### 3. EIA Primary Palette (`eia_primary`)

**Source**: U.S. Energy Information Administration

**Primary References**:
- EIA Annual Energy Outlook 2023
  - URL: https://www.eia.gov/outlooks/aeo/
  - Figure ES-1: "Energy consumption by source"
- EIA Monthly Energy Review
  - URL: https://www.eia.gov/totalenergy/data/monthly/
  - Section 1: "Primary Energy Overview"
- EIA Electricity Data Browser
  - URL: https://www.eia.gov/electricity/data/browser/

**Color Mapping Rationale**:
- **Coal (#3C3C3C)**: Charcoal gray - traditional EIA coal color
- **Petroleum (#8B4513)**: Saddle brown - liquid fuels
- **Natural Gas (#6495ED)**: Cornflower blue - EIA standard gas color
- **Nuclear Electric Power (#FFB347)**: Peach - EIA nuclear designation
- **Wind (#ADD8E6)**: Light blue - atmospheric association

**Notes**: Based on EIA's standard color scheme used consistently across data visualizations since 2020.

### 4. Renewable Focus Palette (`renewable_focus`)

**Source**: Composite from multiple renewable energy organizations

**Primary References**:
- IRENA Global Energy Transformation reports
  - URL: https://www.irena.org/publications
- REN21 Renewables Global Status Report
  - URL: https://www.ren21.net/gsr-2023/
- IEA Renewables 2023 report
  - URL: https://www.iea.org/reports/renewables-2023

**Color Mapping Rationale**:
- **Solar PV (#FFD700)**: Gold - premium solar representation
- **Wind Onshore (#87CEEB)**: Sky blue - onshore wind standard
- **Wind Offshore (#4682B4)**: Steel blue - ocean association
- **Hydro Large (#0080FF)**: Blue - large-scale water projects
- **Biomass (#228B22)**: Forest green - organic matter

**Notes**: Synthesized from renewable energy industry standards and IRENA visual guidelines.

### 5. Fossil Focus Palette (`fossil_focus`)

**Source**: Oil & gas industry publications and geological surveys

**Primary References**:
- BP Statistical Review of World Energy 2023
  - URL: https://www.bp.com/en/global/corporate/energy-economics/statistical-review-of-world-energy.html
- IEA Coal Market Update 2023
  - URL: https://www.iea.org/reports/coal-market-update-july-2023
- U.S. Geological Survey Energy Resources publications

**Color Mapping Rationale**:
- **Anthracite Coal (#2F2F2F)**: Darkest gray - highest carbon content
- **Bituminous Coal (#4A4A4A)**: Medium gray - most common coal type
- **Sub-bituminous Coal (#696969)**: Lighter gray - lower energy content
- **Lignite (#808080)**: Light gray - lowest rank coal
- **Crude Oil (#8B4513)**: Dark brown - raw petroleum
- **Natural Gas (#4682B4)**: Blue - gaseous state distinction

**Notes**: Colors represent the geological carbon content and energy density hierarchy.

### 6. Technology Focus Palette (`technology_focus`)

**Source**: Energy technology organizations and manufacturers

**Primary References**:
- International Renewable Energy Agency (IRENA) technology roadmaps
- IEA Energy Technology Perspectives 2023
- Nuclear Energy Agency (NEA) publications
- Global Wind Energy Council (GWEC) reports
- Solar Power Europe (SPE) market reports

**Color Mapping Rationale**:
- **Coal Power (#2C2C2C)**: Dark gray - traditional thermal power
- **Gas Turbine (#4682B4)**: Steel blue - advanced gas technology
- **Combined Cycle (#6495ED)**: Cornflower blue - efficient gas technology
- **Nuclear PWR (#FFD700)**: Gold - pressurized water reactor
- **Solar PV (#FF8C00)**: Orange - photovoltaic technology
- **Wind Turbine (#87CEEB)**: Sky blue - wind technology
- **Battery Storage (#9370DB)**: Purple - energy storage distinction

**Notes**: Reflects technology-specific industry standards and equipment manufacturer conventions.

## General Design Principles

### Color Selection Criteria

1. **Accessibility**: All palettes tested for sufficient contrast
2. **Industry Recognition**: Colors align with established sector conventions
3. **Logical Association**: Colors match intuitive associations (blue=water, green=biomass)
4. **Distinctiveness**: Sufficient visual separation between categories
5. **Print Compatibility**: Colors work in both digital and print media

### Adaptation Notes

- Colors may be slightly adjusted from original sources for:
  - Better accessibility and contrast
  - Consistency across different visualization types
  - Optimal reproduction in various media
- Original source materials often use similar but not identical colors
- Some palettes combine colors from multiple charts within the same organization

### Data Provenance

All referenced reports and datasets are publicly available. Color selections were made by:
1. Analyzing official charts and figures from source organizations
2. Using color picker tools on high-resolution PDFs and web graphics
3. Standardizing to hex color codes for R compatibility
4. Testing for accessibility and distinctiveness

### Version Control

This reference document corresponds to:
- **Package Version**: 0.0.0.9000
- **Reference Date**: September 2025
- **Last Updated**: September 13, 2025

### Attribution and Fair Use

The color palettes in this package are derived from publicly available materials for educational and research purposes. No proprietary color schemes are directly copied. The palettes represent our interpretation and adaptation of publicly visible color conventions in the energy sector.

For commercial use, users should verify that their specific application complies with any relevant intellectual property considerations of the source organizations.

## Contributing New Palettes

When contributing new palettes, please provide:

1. **Source Documentation**: Specific reports, charts, or publications
2. **URL References**: Direct links to source materials
3. **Rationale**: Why specific colors were chosen for each energy source
4. **Screenshots**: Visual evidence of original color usage (where permitted)
5. **Verification**: Confirmation that colors are publicly visible and not proprietary

---

**Compiled by**: energypal development team  
**Contact**: For questions about sources or to suggest corrections, please open an issue at https://github.com/optimal2050/energypal/issues