#' Utility Functions for Energy Visualizations
#'
#' Helper functions for common energy data visualization tasks.
#'

#' Show All Energy Palettes
#'
#' Display all available energy color palettes in a grid format.
#' Includes solid background for dark theme compatibility.
#'
#' @param ncol Number of columns for the display grid (default: 2)
#' @param palette_names Optional vector of specific palette names to display
#' @param background_color Character, background color for plots (default: "white")
#' @param show_labels Logical, whether to show energy source labels (default: FALSE)
#' @param compact Logical, use compact viridis-style display (default: TRUE)
#'
#' @return Invisibly returns a list of palette plots
#' @export
#'
#' @examples
#' \dontrun{
#' # Show all palettes
#' show_all_energy_palettes()
#' 
#' # Show specific palettes
#' show_all_energy_palettes(palette_names = c("iea_primary", "renewable_focus"))
#' 
#' # Show with dark background
#' show_all_energy_palettes(background_color = "#2D2D2D")
#' }
show_all_energy_palettes <- function(ncol = 2, palette_names = NULL, background_color = "white", 
                                     show_labels = FALSE, compact = TRUE) {
  
  if (!requireNamespace("graphics", quietly = TRUE)) {
    stop("Package 'graphics' is required for this function.")
  }
  
  if (is.null(palette_names)) {
    palette_names <- get_energy_palette_names()
  }
  
  n_palettes <- length(palette_names)
  nrow <- ceiling(n_palettes / ncol)
  
  # Set up the plotting layout with minimal margins for maximum color display
  graphics::par(mfrow = c(nrow, ncol), mar = c(0.5, 0.5, 2, 0.5), bg = background_color)
  
  plot_list <- list()
  text_color <- if(background_color == "white") "black" else "white"
  
  for (i in seq_along(palette_names)) {
    palette_name <- palette_names[i]
    palette <- get_energy_palette(palette_name)
    n <- length(palette)
    
    # Create full-width color bar using image() like viridis
    graphics::image(1:n, 1, as.matrix(1:n), 
                   col = palette,
                   main = palette_name,
                   xlab = "", 
                   ylab = "",
                   xaxt = "n", 
                   yaxt = "n",
                   bty = "n",
                   cex.main = 0.9,
                   col.main = text_color)
    
    plot_list[[palette_name]] <- palette
  }
  
  # Reset graphics parameters
  graphics::par(mfrow = c(1, 1), mar = c(5, 4, 4, 2) + 0.1, bg = "white")
  
  invisible(plot_list)
}

#' Add Energy Color Column to Data
#'
#' Adds a color column to a data frame based on energy source mappings.
#' This is useful for pre-computing colors or when you need direct access
#' to the color values in your data processing pipeline.
#'
#' @param data Data frame containing energy source information
#' @param source_column Character, name of the column containing energy source names
#' @param color_column Character, name for the new color column (default: "energy_color")
#' @param palette Character, energy palette to use for mapping. If NULL, uses default.
#' @param mapping_function Character, mapping method: "auto", "exact", "fuzzy", or "regex"
#' @param unmapped_color Character, color for unmapped sources (default: "#999999")
#' @param apply_variations Logical, whether to apply color variations for duplicates
#' @param variation_type Character, type of variation if applied
#' @param variation_intensity Numeric, intensity of variation (0-1)
#' @param overwrite Logical, whether to overwrite existing color column (default: FALSE)
#'
#' @return Data frame with added color column
#' @export
#'
#' @examples
#' # Basic usage
#' data(owid_energy_mix)
#' data_with_colors <- add_energy_colors(
#'   owid_energy_mix, 
#'   source_column = "source"
#' )
#' head(data_with_colors)
#' 
#' # With custom palette and variations
#' data_with_colors <- add_energy_colors(
#'   owid_energy_mix,
#'   source_column = "source", 
#'   color_column = "my_colors",
#'   palette = "renewable_focus",
#'   apply_variations = TRUE,
#'   variation_intensity = 0.4
#' )
#' 
#' # Use the colors directly
#' unique(data_with_colors[c("source", "my_colors")])
add_energy_colors <- function(data,
                             source_column = NULL,
                             color_column = "energy_color",
                             palette = NULL,
                             mapping_function = "auto",
                             unmapped_color = "#999999",
                             apply_variations = FALSE,
                             variation_type = "shade",
                             variation_intensity = 0.3,
                             overwrite = FALSE) {
  
  # Validate inputs
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  
  # Auto-detect source column if not provided
  if (is.null(source_column)) {
    possible_names <- c("source", "energy_source", "Source", "Energy_Source", 
                       "fuel", "technology", "resource", "type", "category")
    found_columns <- intersect(possible_names, names(data))
    
    if (length(found_columns) == 0) {
      stop("source_column not specified and could not auto-detect. ",
           "Please specify the column containing energy source names.")
    } else if (length(found_columns) > 1) {
      source_column <- found_columns[1]
      message("Multiple possible source columns found. Using '", source_column, 
              "'. Available: ", paste(found_columns, collapse = ", "))
    } else {
      source_column <- found_columns[1]
      message("Auto-detected source column: '", source_column, "'")
    }
  }
  
  if (!source_column %in% names(data)) {
    stop("source_column '", source_column, "' not found in data")
  }
  
  if (color_column %in% names(data) && !overwrite) {
    stop("color_column '", color_column, "' already exists. Use overwrite = TRUE to replace it.")
  }
  
  # Use default palette if none specified
  if (is.null(palette)) {
    palette <- "hierarchy_carriers"
  }
  
  # Get unique sources for mapping
  unique_sources <- unique(data[[source_column]])
  
  # Check for unmapped sources and warn if found
  # Run unmapped check for side-effect warnings (ignore returned object)
  invisible(check_unmapped_sources(
    sources = unique_sources,
    palette_name = palette,
    method = mapping_function,
    warn = TRUE
  ))
  
  # Map colors
  color_mapping <- map_energy_colors(
    sources = unique_sources,
    palette_name = palette,
    method = mapping_function,
    unmapped_color = unmapped_color
  )
  
  # Add color column to data
  data[[color_column]] <- color_mapping[data[[source_column]]]
  
  # Add attributes for reference
  attr(data, "energy_color_mapping") <- list(
    source_column = source_column,
    color_column = color_column,
    palette = palette,
    mapping_function = mapping_function,
    n_unique_sources = length(unique_sources),
    mapping_created = Sys.time()
  )
  
  return(data)
}

#' Get Energy Color Mapping from Data
#'
#' Extract the color mapping information from data that has been processed 
#' with add_energy_colors().
#'
#' @param data Data frame with energy color column
#' @param source_column Character, name of source column
#' @param color_column Character, name of color column
#'
#' @return Named vector of color mappings
#' @export
#'
#' @examples
#' # Add colors to data
#' data_with_colors <- add_energy_colors(owid_energy_mix, "source")
#' 
#' # Extract the mapping
#' color_map <- get_color_mapping_from_data(data_with_colors, "source", "energy_color")
#' print(color_map)
get_color_mapping_from_data <- function(data, source_column, color_column = "energy_color") {
  
  if (!source_column %in% names(data)) {
    stop("source_column '", source_column, "' not found in data")
  }
  
  if (!color_column %in% names(data)) {
    stop("color_column '", color_column, "' not found in data")
  }
  
  # Get unique source-color pairs
  unique_pairs <- unique(data[c(source_column, color_column)])
  
  # Create named vector
  color_mapping <- unique_pairs[[color_column]]
  names(color_mapping) <- unique_pairs[[source_column]]
  
  return(color_mapping)
}

#' Generate Energy Mix Chart
#'
#' Create a standardized energy mix visualization with appropriate colors.
#'
#' @param data Data frame with energy mix data
#' @param x_var Column name for x-axis variable (e.g., "year", "country")
#' @param y_var Column name for y-axis variable (e.g., "generation", "percentage")  
#' @param source_var Column name for energy source variable
#' @param palette Energy palette to use (default: "iea_primary")
#' @param chart_type Type of chart: "stacked_bar", "stacked_area", or "grouped_bar"
#' @param title Plot title
#' @param ... Additional arguments passed to ggplot2 functions
#'
#' @return A ggplot2 object
#' @export
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' 
#' # Create stacked bar chart
#' plot_energy_mix(
#'   data = owid_energy_mix,
#'   x_var = "year",
#'   y_var = "percentage", 
#'   source_var = "source",
#'   title = "Energy Mix Over Time"
#' )
#' 
#' # Create area chart
#' plot_energy_mix(
#'   data = owid_energy_mix,
#'   x_var = "year",
#'   y_var = "generation_twh",
#'   source_var = "source", 
#'   chart_type = "stacked_area",
#'   palette = "renewable_focus"
#' )
#' }
plot_energy_mix <- function(data, 
                           x_var, 
                           y_var, 
                           source_var,
                           palette = NULL,
                           chart_type = "stacked_bar",
                           title = "Energy Mix",
                           ...) {
  
  # Use default palette if none specified
  if (is.null(palette)) {
    palette <- "hierarchy_carriers"
  }
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for this function.")
  }
  
  # Create base plot
  p <- ggplot2::ggplot(data, ggplot2::aes_string(x = x_var, y = y_var, fill = source_var))
  
  # Add appropriate geom based on chart type
  if (chart_type == "stacked_bar") {
    p <- p + ggplot2::geom_col(position = "stack", ...)
  } else if (chart_type == "stacked_area") {
    p <- p + ggplot2::geom_area(position = "stack", ...)
  } else if (chart_type == "grouped_bar") {
    p <- p + ggplot2::geom_col(position = "dodge", ...)
  } else {
    stop("chart_type must be one of: 'stacked_bar', 'stacked_area', 'grouped_bar'")
  }
  
  # Add energy color scale
  p <- p + scale_fill_energy(palette = palette)
  
  # Add theme and labels
  p <- p + 
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = title,
      x = tools::toTitleCase(gsub("_", " ", x_var)),
      y = tools::toTitleCase(gsub("_", " ", y_var)),
      fill = tools::toTitleCase(gsub("_", " ", source_var))
    ) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title = ggplot2::element_text(hjust = 0.5)
    )
  
  return(p)
}

#' Validate Energy Palette
#'
#' Check if a color palette is valid for energy visualization.
#'
#' @param palette Named vector of colors or palette name
#' @param min_colors Minimum number of colors required (default: 3)
#' @param check_contrast Whether to check color contrast (default: TRUE)
#'
#' @return Logical, TRUE if palette is valid
#' @export
#'
#' @examples
#' # Validate existing palette
#' validate_energy_palette("iea_primary")
#' 
#' # Validate custom palette
#' my_palette <- c("Coal" = "#2C2C2C", "Gas" = "#4682B4", "Solar" = "#FFA500")
#' validate_energy_palette(my_palette)
validate_energy_palette <- function(palette, min_colors = 3, check_contrast = TRUE) {
  
  # If palette is a name, get the actual palette
  if (is.character(palette) && length(palette) == 1 && palette %in% get_energy_palette_names()) {
    palette <- get_energy_palette(palette)
  }
  
  # Check if it's a named vector
  if (!is.character(palette) || is.null(names(palette))) {
    message("Palette must be a named character vector of colors")
    return(FALSE)
  }
  
  # Check minimum number of colors
  if (length(palette) < min_colors) {
    message("Palette has ", length(palette), " colors but needs at least ", min_colors)
    return(FALSE)
  }
  
  # Check for valid hex colors
  valid_hex <- grepl("^#[0-9A-Fa-f]{6}$", palette)
  if (!all(valid_hex)) {
    invalid_colors <- names(palette)[!valid_hex]
    message("Invalid hex colors found: ", paste(invalid_colors, collapse = ", "))
    return(FALSE)
  }
  
  # Check for duplicate colors
  if (any(duplicated(palette))) {
    dup_colors <- palette[duplicated(palette)]
    message("Duplicate colors found: ", paste(dup_colors, collapse = ", "))
    return(FALSE)
  }
  
  # Basic contrast check (simplified)
  if (check_contrast) {
    rgb_vals <- grDevices::col2rgb(palette)
    brightness <- apply(rgb_vals, 2, function(x) sum(x * c(0.299, 0.587, 0.114)))
    
    if (max(brightness) - min(brightness) < 100) {
      message("Warning: Palette may have insufficient contrast between colors")
    }
  }
  
  message("Palette validation passed!")
  return(TRUE)
}

#' Energy Color Interpolation
#'
#' Create gradient colors between energy sources for continuous scales.
#'
#' @param source1 First energy source name
#' @param source2 Second energy source name  
#' @param n Number of colors to interpolate (default: 10)
#' @param palette Energy palette to use (default: "iea_primary")
#'
#' @return Character vector of interpolated hex colors
#' @export
#'
#' @examples
#' # Interpolate between coal and solar
#' coal_to_solar <- interpolate_energy_colors("Coal", "Solar", n = 5)
#' 
#' # Display the gradient
#' \dontrun{
#' graphics::pie(rep(1, 5), col = coal_to_solar, labels = 1:5)
#' }
interpolate_energy_colors <- function(source1, source2, n = 10, palette = NULL) {
  if (is.null(palette) || identical(palette, "hierarchy_carriers")) {
    pal <- hierarchy_palette(section = "carriers", label_style = "id")
  } else {
    # Backward compat: attempt legacy getter (may be deprecated)
    pal <- get_energy_palette(palette)
  }
  # Helper to resolve via matcher if direct name absent
  resolve_color <- function(src) {
    if (src %in% names(pal)) return(pal[src])
    m <- match_energy_sources(src, palette_name = if (is.null(palette)) "hierarchy_carriers" else palette, palette_vector = pal, warn = FALSE)
    if (!is.na(m$matched[1]) && m$matched[1] %in% names(pal)) return(pal[m$matched[1]])
    stop("Source '", src, "' not found in palette (hierarchy)")
  }
  color1 <- resolve_color(source1)
  color2 <- resolve_color(source2)
  ramp_func <- grDevices::colorRampPalette(c(color1, color2))
  ramp_func(n)
}

# ---------------------------------------------------------------------------
# Color variation helpers (internal)
# ---------------------------------------------------------------------------

#' Order Energy Sources by Carbon Intensity
#'
#' Convert energy source names to ordered factors based on carbon intensity hierarchy.
#' This ensures consistent ordering in plots from high-carbon (fossil fuels) to 
#' low-carbon (renewables).
#'
#' @param sources Character vector of energy source names
#' @param palette Character, energy palette to use for determining canonical order
#' @param custom_order Optional character vector specifying custom ordering
#' @param method Character, ordering method: "carbon_intensity", "dispatchability", or "palette_order"
#' @param reverse Logical, whether to reverse the order (default: FALSE)
#'
#' @return Ordered factor with energy sources arranged by carbon intensity
#' @export
#'
#' @examples
#' # Basic carbon intensity ordering
#' sources <- c("Solar", "Coal", "Wind", "Natural Gas", "Nuclear")
#' ordered_sources <- order_energy_sources(sources)
#' print(levels(ordered_sources))
#' 
#' # Custom ordering for renewables-first view
#' sources <- c("Coal", "Solar", "Wind", "Hydro")
#' ordered_sources <- order_energy_sources(sources, reverse = TRUE)
#' print(levels(ordered_sources))
#' 
#' # Use in ggplot2
#' \dontrun{
#' data$source_ordered <- order_energy_sources(data$source)
#' ggplot(data, aes(x = year, y = value, fill = source_ordered)) + 
#'   geom_col()
#' }
order_energy_sources <- function(sources,
                                 custom_order = NULL,
                                 method = "carbon_intensity",
                                 reverse = FALSE,
                                 for_stacking = TRUE,
                                 direction = NULL,
                                 palette = NULL) { # palette kept for backward compatibility

  if (!is.null(palette)) {
    # Soft deprecation message (only once per session ideally, but simple message for now)
    message("`palette` argument is deprecated and ignored; ordering now derives from hierarchy or internal canonical lists.")
  }

  if (!is.null(custom_order)) {
    factor_order <- custom_order
  } else if (method == "palette_order") {
    # Interpret palette_order as hierarchy order (carriers section)
    hpal <- hierarchy_palette(section = "carriers", label_style = "id")
    factor_order <- names(hpal)
  } else {
    carbon_order <- c(
      "Coal", "Anthracite", "Bituminous Coal", "Sub-bituminous Coal", "Lignite", "Coal Power",
      "Oil", "Crude Oil", "Heavy Fuel Oil", "Diesel", "Residual Fuel Oil", "Petroleum",
      "Natural Gas", "Gas", "LNG", "Gas Turbine", "Combined Cycle Gas",
      "Nuclear", "Nuclear Power", "Nuclear PWR", "Nuclear BWR",
      "Hydro", "Hydroelectric", "Hydro Turbine", "Large Hydro", "Small Hydro",
      "Bioenergy", "Biomass", "Biogas", "Biofuels", "Wood",
      "Geothermal", "Geothermal Power",
      "Wind", "Wind Power", "Wind Turbine", "Onshore Wind", "Offshore Wind",
      "Solar", "Solar Power", "Solar PV", "Solar Thermal", "Photovoltaic",
      "Battery Storage", "Pumped Hydro", "Storage", "Other"
    )
    if (method == "dispatchability") {
      factor_order <- c(
        "Coal", "Oil", "Natural Gas", "Nuclear", "Hydro", "Bioenergy", "Geothermal",
        "Coal Power", "Gas Turbine", "Nuclear PWR", "Hydro Turbine",
        "Wind", "Wind Turbine", "Solar", "Solar PV",
        "Battery Storage", "Pumped Hydro", "Storage", "Other"
      )
    } else { # carbon_intensity default
      factor_order <- carbon_order
    }
  }

  if (reverse) factor_order <- rev(factor_order)
  if (!is.null(direction) && direction == 1) factor_order <- rev(factor_order)

  present_sources <- intersect(factor_order, sources)
  missing_sources <- setdiff(sources, factor_order)
  if (length(missing_sources) > 0) {
    present_sources <- c(present_sources, missing_sources)
    message("Unknown sources added at end: ", paste(missing_sources, collapse = ", "))
  }
  factor(sources, levels = present_sources, ordered = TRUE)
}

#' Apply Energy Source Ordering to Data Frame
#'
#' Automatically convert energy source columns to ordered factors in a data frame.
#'
#' @param data Data frame containing energy source information
#' @param source_column Character, name of the column containing energy source names
#' @param new_column Character, name for the new ordered factor column. If NULL, overwrites source_column
#' @param palette Character, energy palette to use for ordering
#' @param method Character, ordering method to use
#' @param reverse Logical, whether to reverse the order
#'
#' @return Data frame with ordered energy source column
#' @export
#'
#' @examples
#' # Apply ordering to example data
#' data(owid_energy_mix)
#' ordered_data <- apply_energy_order(owid_energy_mix, "source")
#' 
#' # Check the factor levels
#' levels(ordered_data$source)
#' 
#' # Create new column with ordering
#' ordered_data <- apply_energy_order(
#'   owid_energy_mix, 
#'   source_column = "source",
#'   new_column = "source_ordered",
#'   method = "carbon_intensity"
#' )
apply_energy_order <- function(data,
                              source_column,
                              new_column = NULL,
                              palette = NULL,
                              method = "carbon_intensity", 
                              reverse = FALSE) {
  
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  
  if (!source_column %in% names(data)) {
    stop("source_column '", source_column, "' not found in data")
  }
  
  # Use source column name if new column not specified
  if (is.null(new_column)) {
    new_column <- source_column
  }
  
  # Apply ordering
  data[[new_column]] <- order_energy_sources(
    sources = data[[source_column]],
    palette = palette,
    method = method,
    reverse = reverse
  )
  
  return(data)
}

#' Get Canonical Energy Source Order
#'
#' Returns the canonical ordering of energy sources for a given palette or method.
#'
#' @param palette Character, energy palette name
#' @param method Character, ordering method
#' @param reverse Logical, whether to reverse the order
#'
#' @return Character vector of energy sources in canonical order
#' @export
#'
#' @examples
#' # Get carbon intensity order
#' carbon_order <- get_canonical_order("iea_primary", "carbon_intensity")
#' print(carbon_order)
#' 
#' # Get palette-based order
#' palette_order <- get_canonical_order("renewable_focus", "palette_order")
#' print(palette_order)
get_canonical_order <- function(method = "carbon_intensity", reverse = FALSE, palette = NULL) {
  if (!is.null(palette)) {
    message("`palette` argument is deprecated and ignored; canonical order derives from hierarchy/internal lists.")
  }
  if (method == "palette_order") {
    order <- names(hierarchy_palette(section = "carriers", label_style = "id"))
  } else if (method == "dispatchability") {
    order <- c(
      "Coal", "Oil", "Natural Gas", "Nuclear", "Hydro", "Bioenergy", "Geothermal",
      "Coal Power", "Gas Turbine", "Nuclear PWR", "Hydro Turbine",
      "Wind", "Wind Turbine", "Solar", "Solar PV",
      "Battery Storage", "Pumped Hydro", "Storage", "Other"
    )
  } else { # carbon_intensity
    order <- c(
      "Coal", "Anthracite", "Bituminous Coal", "Sub-bituminous Coal", "Lignite", "Coal Power",
      "Oil", "Crude Oil", "Heavy Fuel Oil", "Diesel", "Residual Fuel Oil", "Petroleum",
      "Natural Gas", "Gas", "LNG", "Gas Turbine", "Combined Cycle Gas",
      "Nuclear", "Nuclear Power", "Nuclear PWR", "Nuclear BWR",
      "Hydro", "Hydroelectric", "Hydro Turbine", "Large Hydro", "Small Hydro",
      "Bioenergy", "Biomass", "Biogas", "Biofuels", "Wood",
      "Geothermal", "Geothermal Power",
      "Wind", "Wind Power", "Wind Turbine", "Onshore Wind", "Offshore Wind",
      "Solar", "Solar Power", "Solar PV", "Solar Thermal", "Photovoltaic",
      "Battery Storage", "Pumped Hydro", "Storage", "Other"
    )
  }
  order <- order[!duplicated(order)]
  if (reverse) order <- rev(order)
  order
}