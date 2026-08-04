## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 4.2,
  dpi = 96
)

## ----libs, message = FALSE----------------------------------------------------
library(energypal)
library(ggplot2)

## ----first--------------------------------------------------------------------
d <- subset(owid_energy_mix, year == max(owid_energy_mix$year))
unique(d$source)

ggplot(d, aes(country, percentage, fill = source)) +
  geom_col() +
  scale_fill_energy() +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

## ----palette------------------------------------------------------------------
energypal()

## ----n------------------------------------------------------------------------
energypal("eia", n = 5)

## ----flags--------------------------------------------------------------------
length(energypal("carriers"))
length(energypal("carriers", include_groups = TRUE, include_subtypes = TRUE))

## ----labels-------------------------------------------------------------------
energypal("carriers", n = 4, label_style = "long")

## ----info---------------------------------------------------------------------
energypal_info()[, c("name", "title", "type", "n")]

## ----show, fig.height = 4.5---------------------------------------------------
energypal_show(c("carriers", "eia", "ipcc", "owid"))

## ----match--------------------------------------------------------------------
energypal_match(c("Coal", "natural gas", "Solar PV", "COAL1", "Flux Capacitor"))

## ----orders-------------------------------------------------------------------
energypal_orders("carriers")[, c("order", "kind", "n")]

## ----ordered, fig.height = 3.6------------------------------------------------
for (o in c("carbon_intensity", "merit_order")) {
  print(
    ggplot(d, aes(country, percentage, fill = source)) +
      geom_col() +
      scale_fill_energy(order = o) +
      labs(title = o) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  )
}

## ----caveat-------------------------------------------------------------------
cat(energypal_orders("carriers")$note[1])

## ----continuous, fig.height = 3.2---------------------------------------------
grid <- expand.grid(x = 1:60, y = 1:24)
grid$wind <- 2 + 15 * (sin(grid$x / 9) + cos(grid$y / 5) + 2) / 4

ggplot(grid, aes(x, y, fill = wind)) +
  geom_raster() +
  scale_fill_energy_b(palette = "windatlas") +
  labs(fill = "m/s") +
  theme_minimal()

## ----gradient-----------------------------------------------------------------
energypal_colors(c("COAL1", "COAL2", "COAL3", "SOLAR_NY"), gradient = TRUE)

## ----own----------------------------------------------------------------------
p <- energypal_create(c(Coal = "#4E4E4E", Gas = "#2E86AB", Solar = "#F6AE2D"),
                      name = "myproject")
f <- tempfile(fileext = ".yml")
energypal_write(p, f)
cat(readLines(f), sep = "\n")

## ----own-edit-----------------------------------------------------------------
writeLines(c(
  "meta:",
  "  name: myproject",
  "colors:",
  '  Coal: "#4E4E4E"',
  "  Gas:",
  '    _color: "#2E86AB"',
  "    _long: Natural Gas",
  "    _aliases: [nat gas, NG, methane]"
), f)

energypal_colors(c("Coal", "nat gas", "METHANE"), file = f)

## ----own-register-------------------------------------------------------------
energypal_register("myproject", f)
energypal("myproject")

