# Script to prepare curated owid_energy_mix dataset
# Run manually (not executed on install) to refresh the dataset.

library(utils)

url <- "https://raw.githubusercontent.com/owid/energy-data/master/owid-energy-data.csv"
message("Downloading OWID full dataset ...")
tmp <- tempfile(fileext = ".csv")
download.file(url, tmp)

raw <- read.csv(tmp, check.names = FALSE)

# Country selection (adjustable)
keep_countries <- c("United States", "China", "India", "Germany", "France", "Brazil", "Australia")
raw <- subset(raw, country %in% keep_countries)

# Keep recent years (last 3 available with non-missing electricity shares)
share_cols <- c("coal_share_elec","gas_share_elec","oil_share_elec","nuclear_share_elec",
               "hydro_share_elec","wind_share_elec","solar_share_elec","biofuel_share_elec",
               "other_renewables_share_elec_exc_biofuel")
raw$complete_row <- apply(raw[share_cols], 1, function(r) all(!is.na(r)))
complete_years <- sort(unique(raw$year[raw$complete_row]), decreasing = TRUE)
keep_years <- head(complete_years, 25)
raw <- subset(raw, year %in% keep_years)

# Gather generation shares -> tidy format
library(tidyr)
library(dplyr)

shares_long <- raw |>
  select(country, iso_code, year, any_of(share_cols), carbon_intensity_elec) |>
  tidyr::pivot_longer(all_of(share_cols), names_to = "variable", values_to = "percentage")

# Map variable names to canonical sources
map_source <- c(
  coal_share_elec = "Coal",
  gas_share_elec = "Natural Gas",
  oil_share_elec = "Oil",
  nuclear_share_elec = "Nuclear",
  hydro_share_elec = "Hydro",
  wind_share_elec = "Wind",
  solar_share_elec = "Solar",
  biofuel_share_elec = "Bioenergy",
  other_renewables_share_elec_exc_biofuel = "Other"
)

shares_long$source <- unname(map_source[shares_long$variable])

# Remove rows with NA percentage
shares_long <- shares_long |> filter(!is.na(percentage))

# Compute pseudo generation TWh from share * total_electricity if available
if ("electricity_generation" %in% names(raw)) {
  totals <- raw |> select(country, year, electricity_generation)
  shares_long <- shares_long |> left_join(totals, by = c("country","year"))
  shares_long$generation_twh <- round(shares_long$percentage/100 * shares_long$electricity_generation, 3)
} else {
  shares_long$generation_twh <- NA_real_
}

# Slim columns
final <- shares_long |> select(country, iso_code, year, source, generation_twh, percentage, carbon_intensity_gco2_kwh = carbon_intensity_elec)

# Order for convenience
final <- final |> arrange(country, year, source)

attr(final, "metadata") <- list(
  snapshot_date = Sys.Date(),
  source_url = url,
  countries = keep_countries,
  years = sort(unique(final$year)),
  license = "CC-BY 4.0"
)

# Save
owid_energy_mix <- final
usethis::use_data(owid_energy_mix, overwrite = TRUE, compress = "xz")
message("Saved owid_energy_mix (rows: ", nrow(owid_energy_mix), ")")
