# Create example datasets for the energypal package

# Energy generation data
countries <- c("USA", "Germany", "China")
years <- 2018:2022
sources <- c("Coal", "Natural Gas", "Nuclear", "Hydro", "Wind", 
             "Solar", "Oil", "Bioenergy", "Geothermal")

set.seed(42)  # For reproducible data

example_energy_data <- expand.grid(
  country = countries,
  year = years, 
  source = sources,
  stringsAsFactors = FALSE
)

# Add realistic generation values
example_energy_data$generation_twh <- round(
  runif(nrow(example_energy_data), 10, 500) * 
  ifelse(example_energy_data$source == "Coal", 1.2,
  ifelse(example_energy_data$source == "Natural Gas", 1.0,
  ifelse(example_energy_data$source == "Nuclear", 0.8,
  ifelse(example_energy_data$source == "Hydro", 0.6,
  ifelse(example_energy_data$source == "Wind", 0.4,
  ifelse(example_energy_data$source == "Solar", 0.3,
  ifelse(example_energy_data$source == "Oil", 0.2,
  ifelse(example_energy_data$source == "Bioenergy", 0.3, 0.1)))))))), 1
)

# Calculate percentages by country and year
example_energy_data$percentage <- 0
for (ctry in countries) {
  for (yr in years) {
    idx <- example_energy_data$country == ctry & example_energy_data$year == yr
    total_gen <- sum(example_energy_data$generation_twh[idx])
    example_energy_data$percentage[idx] <- round(
      example_energy_data$generation_twh[idx] / total_gen * 100, 1
    )
  }
}

# Capacity data
regions <- c("North America", "Europe", "Asia", "Latin America", "Africa")
technologies <- c("Coal Power", "Gas Turbine", "Nuclear PWR", "Solar PV", 
                 "Wind Turbine", "Hydro Turbine", "Battery Storage")

example_capacity_data <- expand.grid(
  region = regions,
  technology = technologies,
  stringsAsFactors = FALSE
)

example_capacity_data$capacity_gw <- round(
  runif(nrow(example_capacity_data), 1, 100) *
  ifelse(example_capacity_data$technology == "Coal Power", 1.5,
  ifelse(example_capacity_data$technology == "Gas Turbine", 1.2,
  ifelse(example_capacity_data$technology == "Nuclear PWR", 0.8,
  ifelse(example_capacity_data$technology == "Solar PV", 0.6,
  ifelse(example_capacity_data$technology == "Wind Turbine", 0.7,
  ifelse(example_capacity_data$technology == "Hydro Turbine", 0.5, 0.2)))))), 1
)

example_capacity_data$capacity_factor <- round(
  ifelse(example_capacity_data$technology == "Nuclear PWR", 
         runif(nrow(example_capacity_data), 0.85, 0.95),
  ifelse(example_capacity_data$technology == "Coal Power",
         runif(nrow(example_capacity_data), 0.65, 0.85),
  ifelse(example_capacity_data$technology == "Gas Turbine",
         runif(nrow(example_capacity_data), 0.45, 0.65),
  ifelse(example_capacity_data$technology == "Hydro Turbine",
         runif(nrow(example_capacity_data), 0.35, 0.55),
  ifelse(example_capacity_data$technology == "Wind Turbine",
         runif(nrow(example_capacity_data), 0.25, 0.45),
  ifelse(example_capacity_data$technology == "Solar PV",
         runif(nrow(example_capacity_data), 0.15, 0.25),
         runif(nrow(example_capacity_data), 0.05, 0.15))))))), 2
)

# Save datasets in proper R format
save(example_energy_data, file = "data/example_energy_data.rda")
save(example_capacity_data, file = "data/example_capacity_data.rda")

cat("Sample datasets created successfully!\n")
cat("- example_energy_data: ", nrow(example_energy_data), " rows\n")
cat("- example_capacity_data: ", nrow(example_capacity_data), " rows\n")