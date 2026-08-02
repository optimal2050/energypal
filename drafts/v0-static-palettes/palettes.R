#' Energy Color Palettes
#'
#' A collection of color palettes designed for energy-related data visualizations,
#' inspired by and adapted from palettes used by major energy organizations.
#'
#' @format A named list of color palettes, where each palette is a named vector
#'   of hex color codes with names corresponding to energy sources or categories.
#'
#' @details
#' The palettes are organized by theme and source:
#' \itemize{
#'   \item \code{iea_primary}: Based on IEA World Energy Outlook 2023 color scheme
#'   \item \code{epa_ghg}: Adapted from EPA GHG Inventory reports (1990-2021)
#'   \item \code{eia_primary}: Based on EIA Annual Energy Outlook and Monthly Energy Review
#'   \item \code{renewable_focus}: Synthesized from IRENA and REN21 publications
#'   \item \code{fossil_focus}: Adapted from BP Statistical Review and geological classifications
#'   \item \code{technology_focus}: Based on IEA Energy Technology Perspectives and industry standards
#' }
#'
#' @source
#' Detailed references and sources for each palette are documented in the package's
#' COLOR_REFERENCES.md file. Key sources include:
#' \itemize{
#'   \item IEA World Energy Outlook 2023: \url{https://www.iea.org/reports/world-energy-outlook-2023}
#'   \item EPA GHG Inventory: \url{https://www.epa.gov/ghgemissions/inventory-us-greenhouse-gas-emissions-and-sinks-1990-2021}
#'   \item EIA Annual Energy Outlook: \url{https://www.eia.gov/outlooks/aeo/}
#'   \item IRENA Publications: \url{https://www.irena.org/publications}
#'   \item BP Statistical Review: \url{https://www.bp.com/en/global/corporate/energy-economics/statistical-review-of-world-energy.html}
#' }
#'
#' @examples
#' # View all available palettes
#' names(energy_palettes)
#'
#' # Get a specific palette
#' energy_palettes$iea_primary
#'
#' # Use with ggplot2
#' \dontrun{
#' library(ggplot2)
#' ggplot(data, aes(x = year, y = value, fill = source)) +
#'   geom_col() +
#'   scale_fill_manual(values = energy_palettes$iea_primary)
#' }
#'
#' @export
energy_palettes <- list(

  # IEA-inspired palette (World Energy Outlook style)
  # Source: IEA World Energy Outlook 2023, Figure 1.6 "Global electricity generation by source"
  # URL: https://www.iea.org/reports/world-energy-outlook-2023
  # Ordered by carbon intensity: high to low, then by intermittency
  iea_primary = c(
    "Coal" = "#2C2C2C",
    "Oil" = "#8B4513",
    "Natural Gas" = "#4682B4",
    "Nuclear" = "#FFD700",
    "Bioenergy" = "#228B22",
    "Geothermal" = "#CD853F",
    "Hydro" = "#0080FF",
    "Other Renewables" = "#32CD32",
    "Wind" = "#87CEEB",
    "Solar" = "#FFA500",
    "Other" = "#C0C0C0"
  ),

  # EPA GHG-inspired palette
  # Source: EPA Inventory of U.S. Greenhouse Gas Emissions and Sinks: 1990-2021
  # URL: https://www.epa.gov/ghgemissions/inventory-us-greenhouse-gas-emissions-and-sinks-1990-2021
  # Ordered by carbon intensity and sector impact
  epa_ghg = c(
    "Coal" = "#4A4A4A",
    "Petroleum" = "#8B0000",
    "Transportation" = "#DC143C",
    "Industrial" = "#708090",
    "Natural Gas" = "#4169E1",
    "Electricity" = "#FFD700",
    "Residential" = "#DDA0DD",
    "Nuclear" = "#FF8C00",
    "Biomass" = "#8FBC8F",
    "Renewable Energy" = "#228B22"
  ),

  # EIA-inspired palette
  # Source: EIA Annual Energy Outlook 2023, Monthly Energy Review
  # URL: https://www.eia.gov/outlooks/aeo/
  # Ordered by carbon intensity: fossil fuels first, renewables last
  eia_primary = c(
    "Coal" = "#3C3C3C",
    "Petroleum" = "#8B4513",
    "Natural Gas" = "#6495ED",
    "Nuclear Electric Power" = "#FFB347",
    "Biomass" = "#90EE90",
    "Geothermal" = "#D2691E",
    "Hydroelectric Power" = "#00CED1",
    "Wind" = "#ADD8E6",
    "Solar" = "#FF8C00",
    "Other" = "#C0C0C0"
  ),

  # Renewable energy focused palette
  # Source: Synthesized from IRENA Global Energy Transformation reports and REN21 Global Status Report
  # URL: https://www.irena.org/publications, https://www.ren21.net/gsr-2023/
  # Ordered by dispatchability: firm renewables first, variable renewables last
  renewable_focus = c(
    "Fossil Fuels" = "#696969",
    "Biomass" = "#228B22",
    "Biogas" = "#32CD32",
    "Geothermal" = "#CD853F",
    "Hydro Large" = "#0080FF",
    "Hydro Small" = "#ADD8E6",
    "Wave & Tidal" = "#008B8B",
    "Wind Offshore" = "#4682B4",
    "Wind Onshore" = "#87CEEB",
    "Solar Thermal" = "#FFA500",
    "Solar PV" = "#FFD700"
  ),

  # Fossil fuel focused palette
  # Source: BP Statistical Review of World Energy 2023, IEA Coal Market Update
  # URL: https://www.bp.com/en/global/corporate/energy-economics/statistical-review-of-world-energy.html
  # Ordered by carbon content: coal types by rank, then oil products, then gas
  fossil_focus = c(
    "Anthracite Coal" = "#2F2F2F",
    "Bituminous Coal" = "#4A4A4A",
    "Sub-bituminous Coal" = "#696969",
    "Lignite" = "#808080",
    "Crude Oil" = "#8B4513",
    "Refined Petroleum" = "#A0522D",
    "Shale Gas" = "#6495ED",
    "Natural Gas" = "#4682B4",
    "LNG" = "#87CEEB",
    "Renewables" = "#228B22"
  ),

  # Technology-focused palette
  # Source: IEA Energy Technology Perspectives 2023, Nuclear Energy Agency publications
  # URL: https://www.iea.org/reports/energy-technology-perspectives-2023
  # Ordered by carbon intensity and dispatchability: thermal plants first, storage last
  technology_focus = c(
    "Coal Power" = "#2C2C2C",
    "Gas Turbine" = "#4682B4",
    "Combined Cycle" = "#6495ED",
    "Nuclear PWR" = "#FFD700",
    "Nuclear BWR" = "#FFA500",
    "Fuel Cell" = "#32CD32",
    "Hydro Turbine" = "#0080FF",
    "Pumped Storage" = "#20B2AA",
    "Wind Turbine" = "#87CEEB",
    "Solar PV" = "#FF8C00",
    "Battery Storage" = "#9370DB"
  )
)

#' Get Available Energy Palettes
#'
#' Returns a character vector of all available energy palette names.
#'
#' @return A character vector of palette names
#' @export
#'
#' @examples
#' get_energy_palette_names()
get_energy_palette_names <- function() {
  names(energy_palettes)
}

#' Get Energy Palette
#'
#' Retrieve a specific energy color palette by name.
#'
#' @param palette_name Character string specifying the palette name
#' @param reverse Logical, whether to reverse the color order (default: FALSE)
#'
#' @return A named vector of hex color codes
#' @export
#'
#' @examples
#' # Get IEA primary palette
#' get_energy_palette("iea_primary")
#'
#' # Get palette in reverse order
#' get_energy_palette("renewable_focus", reverse = TRUE)
get_energy_palette <- function(palette_name, reverse = FALSE) {
  if (!is.character(palette_name) || length(palette_name) != 1) {
    stop("palette_name must be a single character string.")
  }
  if (length(palette_name) != 1) {
    stop("palette_name must be a single string.")
  }
  if (!(palette_name %in% names(energy_palettes))) {
    stop("Palette '", palette_name, "' not found. Available palettes: ",
         paste(names(energy_palettes), collapse = ", "))
  }

  palette <- energy_palettes[[palette_name]]

  if (reverse) {
    palette <- rev(palette)
  }

  return(palette)
}

#' Display Energy Palette
#'
#' Visualize an energy color palette using the same viridis-style image() approach
#' as show_all_energy_palettes() for consistent presentation. Features full-width
#' color bars, minimal margins, and center-justified labels by default for
#' professional palette visualization.
#'
#' @param palette_name Character string specifying the palette name
#' @param n_colors Integer, number of colors to display (default: all)
#' @param background_color Character, background color for the plot (default: "white")
#' @param show_labels Logical, whether to show energy source labels over color bar (default: TRUE)
#' @param label_angle Numeric, angle for labels in degrees (default: 90)
#' @param compact Logical, whether to use minimal margins for maximum color display (default: TRUE)
#' @param labels_color Character, color for the labels (default: "white")
#' @param show_variations Logical, whether to demonstrate color variations (default: FALSE)
#' @param n_variations Integer, number of variations to show for each base color when show_variations=TRUE (default: 3)
#' @param variation_type Character, type of variation to demonstrate: "lightness", "saturation", "hue", "mixed" (default: "lightness")
#' @param variation_intensity Numeric, intensity of variation between 0-1 (default: 0.15)
#'
#' @return A plot showing the color palette with viridis-style image() display
#' @export
#'
#' @examples
#' \dontrun{
#' # Display with default settings (labels shown, white, center-justified)
#' display_energy_palette("iea_primary")
#'
#' # Display without labels (minimal style)
#' display_energy_palette("iea_primary", show_labels = FALSE)
#'
#' # Display with horizontal black labels
#' display_energy_palette("renewable_focus", label_angle = 0, labels_color = "black")
#'
#' # Display with colored labels for better visibility
#' display_energy_palette("renewable_focus", labels_color = "yellow")
#'
#' # Display first 5 colors with custom label styling
#' display_energy_palette("epa_ghg", n_colors = 5, labels_color = "cyan", label_angle = 45)
#'
#' # Dark background automatically works well with white labels
#' display_energy_palette("fossil_focus", background_color = "#2D2D2D")
#'
#' # Show color variations for duplicate source handling
#' display_energy_palette("iea_primary", show_variations = TRUE, n_variations = 3)
#'
#' # Show more variations with different types
#' display_energy_palette("renewable_focus", show_variations = TRUE, n_variations = 5,
#'                        variation_type = "saturation")
#'
#' # Demonstrate high variation count for complex datasets
#' display_energy_palette("technology_focus", show_variations = TRUE, n_variations = 10,
#'                        variation_type = "mixed", variation_intensity = 0.25)
#' }
display_energy_palette <- function(palette_name, n_colors = NULL, background_color = "white",
                                 show_labels = TRUE, label_angle = 90, compact = TRUE,
                                 labels_color = "white", show_variations = FALSE,
                                 n_variations = 3, variation_type = "lightness",
                                 variation_intensity = 0.15) {

  if (!requireNamespace("graphics", quietly = TRUE)) {
    stop("Package 'graphics' is required for this function.")
  }

  palette <- get_energy_palette(palette_name)

  # Generate variations if requested
  if (show_variations) {
    expanded_palette <- character()
    expanded_names <- character()

    for (i in seq_along(palette)) {
      base_color <- palette[i]
      base_name <- names(palette)[i]

      # Generate variations for this base color
      variations <- generate_color_variations(
        base_color = base_color,
        n_variations = n_variations,
        variation_type = variation_type,
        variation_intensity = variation_intensity,
        include_base = TRUE
      )

      # Create names for variations
      if (n_variations > 1) {
        if (n_variations > 3) {
          # Use range notation centered for many variations
          center_index <- ceiling(n_variations / 2)
          variation_names <- rep("", n_variations)  # Start with empty labels
          variation_names[center_index] <- paste0(base_name, " (1-", n_variations, ")")
        } else {
          # Use individual numbers for few variations: "Coal (1)", "Coal (2)", "Coal (3)"
          variation_names <- paste0(base_name, " (", seq_along(variations), ")")
        }
      } else {
        variation_names <- base_name
      }

      expanded_palette <- c(expanded_palette, variations)
      expanded_names <- c(expanded_names, variation_names)
    }

    names(expanded_palette) <- expanded_names
    palette <- expanded_palette
  }

  if (!is.null(n_colors)) {
    n_to_show <- min(n_colors, length(palette))
    palette <- palette[seq_len(n_to_show)]
  }

  n <- length(palette)

  # Set margins based on compact option and label requirements
  if (compact) {
    if (show_labels && (label_angle == 90 || label_angle == 270)) {
      # Vertical labels need bottom space
      graphics::par(mar = c(3, 0.5, 1.5, 0.5), bg = background_color)
    } else if (show_labels) {
      # Horizontal or angled labels need less bottom space
      graphics::par(mar = c(2, 0.5, 1.5, 0.5), bg = background_color)
    } else {
      # No labels - minimal margins (same as show_all_energy_palettes)
      graphics::par(mar = c(0.5, 0.5, 2, 0.5), bg = background_color)
    }
  } else {
    # Standard margins for non-compact mode
    graphics::par(mar = c(3, 2, 3, 2), bg = background_color)
  }

  # Create full-width color bar using image() like viridis and show_all_energy_palettes
  title_text <- if(show_variations) {
    paste("Energy Palette:", palette_name, "with", n_variations, "variations")
  } else {
    paste("Energy Palette:", palette_name)
  }

  graphics::image(1:n, 1, as.matrix(1:n),
                 col = palette,
                 main = title_text,
                 xlab = "",
                 ylab = "",
                 xaxt = "n",
                 yaxt = "n",
                 bty = "n",
                 cex.main = if(compact) 0.9 else 1.2,
                 col.main = if(background_color == "white") "black" else "white")

  # Add labels if requested
  if (show_labels) {
    # Use the specified labels_color parameter
    text_color <- labels_color

    # Center-justify labels over the color bars with optimal positioning
    # Position labels in the center of each color bar for better readability
    if (label_angle == 90 || label_angle == 270) {
      # Vertical labels - center them over each color bar
      y_pos <- 1.0  # Position in center of color bar
      adj_val <- c(0.5, 0.5)  # Center both horizontally and vertically
    } else if (label_angle == 0 || label_angle == 180) {
      # Horizontal labels - center them over each color bar
      y_pos <- 1.0  # Position in center of color bar
      adj_val <- c(0.5, 0.5)  # Center both ways
    } else {
      # Angled labels - center them over each color bar
      y_pos <- 1.0  # Position in center of color bar
      adj_val <- c(0.5, 0.5)  # Center both ways
    }

    # Add center-justified labels with custom color
    for(i in 1:n) {
      graphics::text(i, y_pos, names(palette)[i],
                    srt = label_angle,
                    adj = adj_val,
                    cex = if(compact) 0.7 else 0.8,
                    col = text_color,
                    family = "sans",
                    font = 2)  # Bold font for better visibility over colors
    }
  }

  # Reset graphics parameters
  graphics::par(mar = c(5, 4, 4, 2) + 0.1, bg = "white")
}
