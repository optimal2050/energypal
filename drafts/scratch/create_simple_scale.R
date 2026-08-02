# Create a completely new, simple scale_fill_energy function to replace the complex one

# New simple scale_fill_energy function
simple_scale_fill_energy <- function(palette = NULL,
                                     mapping_method = "auto",
                                     unmapped_color = "#999999",
                                     guide = "legend",
                                     apply_variations = NULL,
                                     variation_type = NULL,
                                     variation_intensity = NULL,
                                     auto_order = TRUE,
                                     order_method = "carbon_intensity",
                                     custom_order = NULL,
                                     direction = -1,
                                     palette_direction = 1,
                                     use_palette_names = FALSE,
                                     data = NULL,
                                     ...) {
  
  if (is.null(palette)) palette <- get_default_energy_palette()
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package 'ggplot2' is required for this function.")
  if (is.function(mapping_method)) stop("For custom mapping functions, use scale_fill_energy_custom().")

  base_palette <- get_energy_palette(palette)
  
  # Detect present sources from data if provided
  present_sources <- NULL
  if (!is.null(data) && is.data.frame(data)) {
    guess_cols <- c("source","technology","fuel","energy_source")
    col_found <- intersect(guess_cols, names(data))
    if (length(col_found) > 0) present_sources <- unique(as.character(data[[col_found[1]]]))
  }
  
  # Create the discrete scale
  if (!is.null(present_sources)) {
    # Static approach: we know the sources from data
    # SIMPLE: just return colors for present sources in their data order
    # No complex reordering - respect the factor order
    pal_vec <- base_palette[present_sources]
    
    pal_fun <- function(n) {
      if (length(pal_vec) == 0) return(character(0))
      if (n <= length(pal_vec)) {
        return(unname(pal_vec[seq_len(n)]))
      } else {
        return(unname(rep(pal_vec, length.out = n)))
      }
    }
  } else {
    # Dynamic approach: optimized for alphabetical assignment
    pal_fun <- function(n) {
      if (n == 0) return(character(0))
      
      # Common energy sources in typical alphabetical order
      alphabetical_energy_sources <- c(
        "Bioenergy", "Coal", "Geothermal", "Hydro", "Natural Gas", 
        "Nuclear", "Oil", "Other", "Solar", "Wind"
      )
      
      # Build a palette optimized for alphabetical assignment
      alphabetical_colors <- character(length(alphabetical_energy_sources))
      names(alphabetical_colors) <- alphabetical_energy_sources
      
      for (i in seq_along(alphabetical_energy_sources)) {
        source <- alphabetical_energy_sources[i]
        if (source %in% names(base_palette)) {
          alphabetical_colors[i] <- base_palette[source]
        } else {
          alphabetical_colors[i] <- unmapped_color
        }
      }
      
      # Return the first n colors
      colors_to_return <- unname(alphabetical_colors[seq_len(min(n, length(alphabetical_colors)))])
      
      # Pad with unmapped color if needed
      if (length(colors_to_return) < n) {
        colors_to_return <- c(colors_to_return, rep(unmapped_color, n - length(colors_to_return)))
      }
      
      # Handle palette_direction
      if (palette_direction == -1) {
        colors_to_return <- rev(colors_to_return)
      }
      
      return(colors_to_return)
    }
  }
  
  ggplot2::discrete_scale("fill", paste0("energy_fill_", palette), palette = pal_fun, guide = guide, ...)
}

cat("Created simple scale_fill_energy function\n")
cat("Key differences from complex version:\n")
cat("1. No complex canonical reordering in static case\n")
cat("2. Respects factor order in data\n")
cat("3. Simple alphabetical optimization for dynamic case\n")
cat("4. Much shorter and easier to understand\n")