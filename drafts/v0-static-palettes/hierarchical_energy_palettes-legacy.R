# Hierarchical Energy Palettes Specification
# Version: 0.1.0
# References:
#   IPCC 2006 Guidelines (Vol.2 Energy) https://www.ipcc-nggip.iges.or.jp/public/2006gl/
#   IEA World Energy Balances https://www.iea.org/data-and-statistics
#   EIA Fuel Categories https://www.eia.gov/
#   IRENA / REN21 Renewable Classifications
#
# Structure:
# top-level keys: carriers, technologies, metadata
# - carriers: primary energy carriers and their subtypes (fuel taxonomy)
# - technologies: power-generation & conversion technologies
# - metadata: references and notes

carriers:
  Coal:
    _color: "#2C2C2C"
    subtypes:
      Anthracite: "#1E1E1E"
      Bituminous: "#343434"
      SubBituminous: "#4A4A4A"
      Lignite: "#5C5C5C"
      Coke: "#3A3A3A"
  Oil:
    _color: "#8B4513"
    subtypes:
      Crude: "#8B4513"
      ResidualFuelOil: "#7A3E12"
      DistillateFuelOil: "#9A4F19"
      MotorGasoline: "#A85A1F"
      JetFuel: "#95501B"
      LPG_NGL: "#B16528"
  Gas:
    _color: "#4682B4"
    subtypes:
      NaturalGas: "#4682B4"
      ShaleGas: "#4F8CBE"
      TightGas: "#5A96C8"
      LNG: "#639FD1"
      AssociatedGas: "#6DA8DB"
  Bioenergy:
    _color: "#228B22"
    subtypes:
      SolidBiomass: "#228B22"
      Biogas: "#32CD32"
      Ethanol: "#3DCB3D"
      Biodiesel: "#40D240"
      Waste: "#4AA04A"
  Nuclear:
    _color: "#FFD700"
    subtypes:
      PWR: "#FFD700"
      BWR: "#E6C300"
      SMR: "#D4B000"
  Hydro:
    _color: "#0080FF"
    subtypes:
      LargeHydro: "#0080FF"
      SmallHydro: "#3399FF"
      RunOfRiver: "#1A8BFF"
      PumpedStorage: "#20B2AA"
  Wind:
    _color: "#87CEEB"
    subtypes:
      Onshore: "#87CEEB"
      Offshore: "#6BB7D6"
  Solar:
    _color: "#FFA500"
    subtypes:
      SolarPV: "#FFA500"
      CSP: "#FFB347"
      SolarThermal: "#FFC166"
  Geothermal:
    _color: "#CD853F"
    subtypes:
      Hydrothermal: "#CD853F"
      EGS: "#B27336"
  OtherRenewables:
    _color: "#32CD32"
    subtypes:
      Wave: "#2EBB2E"
      Tidal: "#28A828"
      OceanThermal: "#249624"
  Storage:
    _color: "#9370DB"
    subtypes:
      Battery: "#9370DB"
      Hydrogen: "#8A67D2"
      ThermalStorage: "#7E5BC6"
  Other:
    _color: "#C0C0C0"
    subtypes: {}

technologies:
  ElectricPower:
    CoalFiredSteam: "#2C2C2C"
    IGCC: "#3A3A3A"
    GasTurbine: "#5A96C8"
    CCGT: "#4682B4"
    NuclearPWR: "#FFD700"
    NuclearBWR: "#E6C300"
    BiomassCombustion: "#228B22"
    WasteToEnergy: "#556B2F"
    HydroTurbine: "#0080FF"
    PumpedStoragePlant: "#20B2AA"
    WindOnshore: "#87CEEB"
    WindOffshore: "#6BB7D6"
    SolarPV: "#FFA500"
    CSPPlant: "#FFB347"
    GeothermalFlash: "#CD853F"
    GeothermalBinary: "#B27336"
    BatteryStorage: "#9370DB"

metadata:
  version: "0.1.0"
  created: "2025-09-15"
  license: "MIT"
  notes: |
    Colors are provisional and designed to maintain visual continuity with existing iea_primary palette.
    Subtype shades are adjusted primarily via lightness shifts; further refinement may include perceptual
    uniformity adjustments (e.g., OKLCH) and color-blind safety evaluation.
  references:
    - IPCC 2006 Guidelines for National Greenhouse Gas Inventories
    - IEA World Energy Balances
    - EIA Fuel Category Definitions
    - IRENA Technology Classifications
    - REN21 Global Status Report
