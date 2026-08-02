#' Color Variation Functions
#'
#' Functions to create color variations from base energy colors.
#' Useful when multiple data points map to the same energy source.
#'

#' Generate Color Variations
#'
#' Creates variations of a base color by adjusting lightness, saturation, or hue.
#' Useful for distinguishing between multiple data points that map to the same energy source.
#'
#' @param base_color Character, hex color code to create variations from
#' @param n_variations Integer, number of variations to create (including the base color)
#' @param variation_type Character, type of variation: "lightness", "saturation", "hue", or "mixed"
#' @param variation_intensity Numeric, intensity of variation (0-1, default: 0.15)
#' @param include_base Logical, whether to include the original color in output (default: TRUE)
#'
#' @return Character vector of hex color codes
#' @export
#'
#' @examples
#' # Create lightness variations of coal color
#' coal_color <- "#2C2C2C"
#' coal_variations <- generate_color_variations(coal_color, n_variations = 4)
#' 
#' # Create hue variations of solar color
#' solar_color <- "#FFA500"
#' solar_variations <- generate_color_variations(solar_color, n_variations = 3, 
#'                                               variation_type = "hue")
#' 
#' # Display variations
#' display_color_variations(coal_variations, "Coal Variations")
generate_color_variations <- function(base_color, 
                                     n_variations = 3,
                                     variation_type = "lightness",
                                     variation_intensity = 0.15,
                                     include_base = TRUE) {
  
  if (!requireNamespace("grDevices", quietly = TRUE)) {
    stop("Package 'grDevices' is required for color variations.")
  }
  
  # Validate inputs
  if (n_variations < 1) {
    stop("n_variations must be at least 1")
  }
  
  if (variation_intensity < 0 || variation_intensity > 1) {
    stop("variation_intensity must be between 0 and 1")
  }
  
  variation_type <- match.arg(variation_type, c("lightness", "saturation", "hue", "mixed"))
  
  # Convert hex to RGB
  rgb_base <- grDevices::col2rgb(base_color)
  
  # Convert to HSV for easier manipulation
  hsv_base <- grDevices::rgb2hsv(rgb_base[1], rgb_base[2], rgb_base[3])
  h_base <- hsv_base[1, 1]
  s_base <- hsv_base[2, 1]
  v_base <- hsv_base[3, 1]
  
  # Generate variations
  variations <- character(n_variations)
  
  if (include_base) {
    variations[1] <- base_color
    start_idx <- 2
  } else {
    start_idx <- 1
  }
  
  # Calculate variation steps
  n_to_generate <- if (include_base) n_variations - 1 else n_variations
  
  if (n_to_generate > 0) {
    for (i in seq_len(n_to_generate)) {
      idx <- start_idx + i - 1
      
      # Calculate progressive intensity factor (0 to 1)
      # Creates ordered variations from low to high intensity
      intensity_factor <- if (n_to_generate == 1) {
        0.5  # Single variation uses half intensity
      } else {
        i / n_to_generate  # Progressive from 1/n to n/n (i.e., 0.33, 0.67, 1.0 for n=3)
      }
      
      # Apply variation based on type
      h_new <- h_base
      s_new <- s_base
      v_new <- v_base
      
      if (variation_type == "lightness") {
        # Vary lightness progressively lighter
        v_new <- pmax(0.1, pmin(1, v_base + intensity_factor * variation_intensity))
        
      } else if (variation_type == "saturation") {
        # Vary saturation progressively more saturated
        s_new <- pmax(0.1, pmin(1, s_base + intensity_factor * variation_intensity))
        
      } else if (variation_type == "hue") {
        # Vary hue progressively around color wheel
        h_new <- (h_base + intensity_factor * variation_intensity) %% 1
        
      } else if (variation_type == "mixed") {
        # Combine lightness and saturation progressively
        v_new <- pmax(0.1, pmin(1, v_base + intensity_factor * variation_intensity * 0.6))
        s_new <- pmax(0.1, pmin(1, s_base + intensity_factor * variation_intensity * 0.4))
      }
      
      # Convert back to hex
      rgb_new <- grDevices::hsv(h_new, s_new, v_new)
      variations[idx] <- rgb_new
    }
  }
  
  return(variations)
}

#' Create Energy Source Color Variations
#'
#' Generate color variations for a specific energy source from a palette.
#'
#' @param energy_source Character, name of the energy source
#' @param palette_name Character, name of the energy palette to use
#' @param n_variations Integer, number of variations to create
#' @param variation_type Character, type of variation to create
#' @param variation_intensity Numeric, intensity of variation (0-1)
#'
#' @return Named character vector of hex color codes
#' @export
#'
#' @examples
#' # Create variations for coal from IEA palette
#' coal_vars <- create_energy_source_variations("Coal", "iea_primary", n_variations = 4)
#' 
#' # Create variations for solar
#' solar_vars <- create_energy_source_variations("Solar", "renewable_focus", 
#'                                               n_variations = 3, 
#'                                               variation_type = "saturation")
create_energy_source_variations <- function(energy_source,
                                           palette_name = NULL,
                                           n_variations = 3,
                                           variation_type = "lightness",
                                           variation_intensity = 0.3) {
  
  # Use default palette if none specified
  if (is.null(palette_name)) {
    palette_name <- get_default_energy_palette()
  }
  
  # Get the base color for this energy source
  base_colors <- map_energy_colors(energy_source, palette_name = palette_name)
  
  if (length(base_colors) == 0 || is.na(base_colors[1])) {
    stop("Could not map energy source '", energy_source, "' to a color")
  }
  
  base_color <- base_colors[1]
  
  # Generate variations
  variations <- generate_color_variations(
    base_color = base_color,
    n_variations = n_variations,
    variation_type = variation_type,
    variation_intensity = variation_intensity,
    include_base = TRUE
  )
  
  # Create meaningful names
  if (n_variations == 1) {
    names(variations) <- energy_source
  } else {
    names(variations) <- paste0(energy_source, "_", seq_len(n_variations))
  }
  
  return(variations)
}

#' Display Color Variations
#'
#' Visualize color variations in a simple plot.
#'
#' @param colors Character vector of hex color codes
#' @param title Character, title for the plot
#' @param background_color Character, background color (default: "white")
#'
#' @return NULL (creates a plot)
#' @export
#'
#' @examples
#' # Display variations
#' coal_variations <- generate_color_variations("#2C2C2C", n_variations = 5)
#' display_color_variations(coal_variations, "Coal Color Variations")
display_color_variations <- function(colors, title = "Color Variations", background_color = "white") {
  
  if (!requireNamespace("graphics", quietly = TRUE)) {
    stop("Package 'graphics' is required for color display.")
  }
  
  n <- length(colors)
  
  # Set up plot
  graphics::par(mar = c(2, 1, 3, 1), bg = background_color)
  
  # Create empty plot
  graphics::plot(1:n, rep(1, n), type = "n", xlim = c(0.5, n + 0.5), ylim = c(0.5, 1.5),
                axes = FALSE, xlab = "", ylab = "", main = title,
                col.main = if(background_color == "white") "black" else "white")
  
  # Draw color rectangles
  for (i in 1:n) {
    graphics::rect(i - 0.4, 0.7, i + 0.4, 1.3, col = colors[i], border = "black", lwd = 1)
    
    # Add color names if available
    color_name <- if(!is.null(names(colors))) names(colors)[i] else colors[i]
    
    # Choose text color for contrast
    text_color <- if (background_color == "white") "black" else "white"
    
    graphics::text(i, 0.5, color_name, cex = 0.7, col = text_color, srt = 45, adj = c(1, 0.5))
    graphics::text(i, 1.5, colors[i], cex = 0.6, col = text_color, srt = 0, adj = c(0.5, 0))
  }
  
  # Reset plotting parameters
  graphics::par(mar = c(5, 4, 4, 2) + 0.1, bg = "white")
}

#' Auto-Generate Variations for Duplicate Mappings
#'
#' Automatically detect when multiple sources map to the same color and generate variations.
#'
#' @param source_names Character vector of energy source names
#' @param base_colors Named character vector of base colors
#' @param variation_type Character, type of variation to create
#' @param variation_intensity Numeric, intensity of variation (0-1)
#' @param min_sources_for_variation Integer, minimum number of sources mapping to same color 
#'   before variations are applied (default: 2)
#'
#' @return Named character vector with variations applied
#' @export
#'
#' @examples
#' # Simulate duplicate mappings
#' sources <- c("Coal_Plant_1", "Coal_Plant_2", "Solar_Farm_A", "Solar_Farm_B", "Wind")
#' base_colors <- c(Coal = "#2C2C2C", Solar = "#FFA500", Wind = "#87CEEB")
#' mapped_colors <- c("#2C2C2C", "#2C2C2C", "#FFA500", "#FFA500", "#87CEEB")
#' names(mapped_colors) <- sources
#' 
#' varied_colors <- auto_generate_variations(sources, mapped_colors)
auto_generate_variations <- function(source_names,
                                   base_colors,
                                   variation_type = "lightness",
                                   variation_intensity = 0.3,
                                   min_sources_for_variation = 2) {
  
  # Find duplicates
  color_groups <- split(names(base_colors), base_colors)
  
  # Filter groups that need variations
  groups_needing_variations <- color_groups[lengths(color_groups) >= min_sources_for_variation]
  
  # Initialize result with base colors
  result_colors <- base_colors
  
  # Generate variations for groups that need them
  for (base_color in names(groups_needing_variations)) {
    group_sources <- groups_needing_variations[[base_color]]
    n_sources <- length(group_sources)
    
    if (n_sources >= min_sources_for_variation) {
      # Generate variations
      variations <- generate_color_variations(
        base_color = base_color,
        n_variations = n_sources,
        variation_type = variation_type,
        variation_intensity = variation_intensity,
        include_base = TRUE
      )
      
      # Assign variations to sources
      for (i in seq_along(group_sources)) {
        result_colors[group_sources[i]] <- variations[i]
      }
    }
  }
  
  return(result_colors)
}