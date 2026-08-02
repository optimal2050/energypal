## Legacy palettes removed
#' @title Legacy palette infrastructure removed
#' @description The previous static list `energy_palettes` and related accessors
#'   have been deprecated and replaced by a single hierarchy-driven palette.
#'   Use `hierarchy_palette()` or the token 'hierarchy_carriers' in scale functions.
#' @keywords internal
energy_palettes <- NULL

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
  .Deprecated("hierarchy_palette", package = "energypal",
              msg = "Static palette names are deprecated; use hierarchy_palette() or the 'hierarchy_carriers' token.")
  c("hierarchy_carriers")
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
  .Deprecated("hierarchy_palette", package = "energypal",
              msg = "get_energy_palette() is deprecated; colors now sourced exclusively from hierarchy_palette().")
  pal <- hierarchy_palette(section = "carriers", include_groups = FALSE, include_carriers = TRUE, include_subtypes = FALSE, label_style = "id")
  if (reverse) pal <- rev(pal)
  pal
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
display_energy_palette <- function(...) {
  .Deprecated(msg = "display_energy_palette() is deprecated; construct displays manually from hierarchy_palette().")
  invisible(NULL)
}
