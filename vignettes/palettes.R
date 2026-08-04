## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  dpi = 96
)

## ----libs, message = FALSE----------------------------------------------------
library(energypal)
library(ggplot2)

## ----info---------------------------------------------------------------------
knitr::kable(energypal_info()[, c("name", "title", "type", "n", "unit")])

## ----overview, fig.height = 5.5-----------------------------------------------
info <- energypal_info()
energypal_show(info$name[info$type == "discrete"])

## ----declared-only------------------------------------------------------------
setdiff(names(energypal("carriers")), names(energypal("owid")))

# OWID publishes no geothermal series, and says so
energypal_match("Geothermal", palette = "owid", warn = FALSE)

# ...while the inherited alias vocabulary still resolves
energypal_colors("nat gas", palette = "owid", warn = FALSE)

## ----discrete, results = "asis", fig.height = 4.6-----------------------------
for (nm in info$name[info$type == "discrete"]) {
  spec <- energypal_spec(nm)
  m <- spec$meta

  cat("\n### ", if (is.null(m$title)) nm else m$title, "  \n", sep = "")
  cat("`", nm, "`\n\n", sep = "")
  if (!is.null(m$source)) cat("**Source** ", m$source, "  \n", sep = "")
  if (!is.null(m$url))    cat("**URL** <", m$url, ">  \n", sep = "")
  if (!is.null(m$extends)) cat("**Extends** `", m$extends, "`  \n", sep = "")
  if (!is.null(m$license)) cat("\n> **Licence** ", m$license, "\n", sep = "")
  if (!is.null(m$attribution)) {
    cat("\n> **Attribution** ", m$attribution, "\n", sep = "")
  }
  cat("\n")

  energypal_show(nm, label_style = "default")
  cat("\n\n")
}

## ----continuous, results = "asis", fig.height = 2.4---------------------------
for (nm in info$name[info$type == "continuous"]) {
  spec <- energypal_spec(nm)
  m <- spec$meta
  brk <- as.numeric(unlist(spec$breaks))

  cat("\n### ", if (is.null(m$title)) nm else m$title, "  \n", sep = "")
  cat("`", nm, "` — family `", m$family, "`, measure `", m$measure,
      "`, unit `", m$unit, "`  \n", sep = "")
  cat(length(energypal(nm)), " stops, ", length(brk), " breaks from ",
      min(brk), " to ", max(brk), "  \n", sep = "")
  if (!is.null(m$source)) cat("**Source** ", m$source, "  \n", sep = "")
  if (!is.null(m$license)) cat("\n> **Licence** ", m$license, "\n", sep = "")
  if (!is.null(m$attribution)) {
    cat("\n> **Attribution** ", m$attribution, "\n", sep = "")
  }
  cat("\n")

  energypal_show(nm)
  cat("\n\n")
}

## ----family-------------------------------------------------------------------
identical(energypal("windatlas"), energypal("windatlas_speed"))
energypal_info(family = "windatlas")[, c("name", "measure", "default", "unit")]

## ----orders-------------------------------------------------------------------
knitr::kable(energypal_orders("carriers")[, c("order", "kind", "n", "source")])

## ----ordering-demo, fig.height = 3.4------------------------------------------
d <- subset(owid_energy_mix, year == max(owid_energy_mix$year))
for (o in c("carbon_intensity", "merit_order", "renewability")) {
  print(
    ggplot(d, aes(country, percentage, fill = source)) +
      geom_col() +
      scale_fill_energy(order = o) +
      labs(title = o, x = NULL, y = "%") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  )
}

## ----subtypes-----------------------------------------------------------------
head(energypal_table("carriers", order = "carbon_intensity")[, c("name", "type")], 10)

## ----caveat-------------------------------------------------------------------
tab <- energypal_table("carriers")
attr(tab$carbon_intensity, "note")
attr(tab$carbon_intensity, "source")

## ----comparison, fig.height = 3.4---------------------------------------------
for (p in c("carriers", "eia", "ipcc", "owid")) {
  print(
    ggplot(d, aes(country, percentage, fill = source)) +
      geom_col() +
      scale_fill_energy(palette = p) +
      labs(title = p, x = NULL, y = "%") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  )
}

