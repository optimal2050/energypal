#' Energy Color Scales for ggplot2
#'
#' Color and fill scales specifically designed for energy data visualizations.
#' These functions extend ggplot2's scale system with intelligent energy source mapping.
#'

#' Discrete Color Scale for Energy Data
#'
#' @param palette Character string specifying the energy palette to use. 
#'   If NULL (default), uses the currently set default palette.
#' @param mapping_method Character string for color mapping method: "auto", "exact", "fuzzy", or "regex".
#'   For custom mapping functions, use [scale_color_energy_custom()] instead.
#' @param unmapped_color Color for unmapped energy sources (default: "#999999")
#' @param guide Type of legend guide (default: "legend")
#' @param apply_variations Logical, whether to apply color variations for duplicate mappings.
#'   If NULL (default), uses package option setting.
#' @param variation_type Character, type of variation ("lightness", "saturation", "hue", "mixed").
#'   If NULL (default), uses package option setting.
#' @param variation_intensity Numeric, intensity of variation (0-1).
#'   If NULL (default), uses package option setting.
#' @param data Optional data frame used to determine which sources are present so that
#'   the legend only shows sources actually in the data (preferred over guessing with last_plot()).
#' @param auto_order Logical, whether to automatically order energy sources (default: TRUE)
#' @param order_method Character, method for ordering when auto_order=TRUE: "carbon_intensity", "dispatchability", or "palette_order" (default: "carbon_intensity")
#' @param custom_order Optional character vector specifying an explicit order of sources (takes precedence over order_method if provided)
#' @param direction Integer (1 or -1). Controls legend/source order and how colors are assigned across sources. 1 = canonical order, -1 = reversed (default: 1).
#'   This affects only legend/order mapping – physical stacking order in geoms is controlled separately via `stack_direction` in `geom_energy_col()` / `geom_energy_bar()` or `position_energy_stack()`.
#' @param palette_direction Integer (1 or -1). Reverses the underlying palette color sequence without changing legend/source order (default: 1).
#' @param use_palette_names Logical, whether to use palette source names in legend instead of data source names (default: FALSE)
#' @param use_hierarchy Logical; if TRUE, derive the set of sources (and optionally legend labels) from the hierarchy instead of the raw palette names.
#' @param section Character; which hierarchy section to use when `use_hierarchy=TRUE`. One of "carriers" or "technologies".
#' @param label_style Character; legend label style when `use_hierarchy=TRUE`: "default" (long if available else short else id), "short", "long", or "id" (the internal name).
#' @param ... Additional arguments passed to [ggplot2::scale_fill_manual()]
#'
#' @return A ggplot2 scale object
#' @export
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' ggplot(energy_data, aes(x = year, y = generation, color = source)) +
#'   geom_line() +
#'   scale_color_energy()
#' ggplot(energy_data, aes(x = year, y = generation, color = source)) +
#'   geom_line() +
#'   scale_color_energy(palette = "renewable_focus")
#' }
scale_color_energy <- function(palette = NULL,
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
                               use_hierarchy = FALSE,
                               section = c("carriers","technologies"),
                               label_style = c("default","short","long","id"),
                               ...) {
  if (is.null(palette)) palette <- get_default_energy_palette()
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package 'ggplot2' is required for this function.")
  section <- match.arg(section)
  label_style <- match.arg(label_style)

  # Determine sources from data or hierarchy (children names) else fallback to palette names
  sources <- NULL
  if (!is.null(data) && is.data.frame(data)) {
    guess_cols <- c("source","technology","fuel","energy_source")
    col_found <- intersect(guess_cols, names(data))
    if (length(col_found) > 0) sources <- unique(as.character(data[[col_found[1]]]))
  }
  if (is.null(sources) && use_hierarchy) {
    # Use all carrier / technology names (excluding groups) from hierarchy
    if (requireNamespace("yaml", quietly = TRUE)) {
      htab <- try(hierarchy_to_table(section = section, include_groups = FALSE), silent = TRUE)
      if (!inherits(htab, "try-error")) {
        sources <- unique(htab$name)
      }
    }
  }
  base_palette <- get_energy_palette(palette)
  if (is.null(sources)) sources <- names(base_palette)

  # Use matcher (drop synonym expansion—only palette + hierarchy children)
  match_df <- match_energy_sources(sources, palette_name = palette, include_full_palette = FALSE, warn = FALSE)
  # Construct color vector, fallback to unmapped_color
  out_colors <- setNames(rep(unmapped_color, length(sources)), sources)
  m_idx <- match(match_df$original, sources)
  valid <- !is.na(match_df$matched) & !is.na(m_idx)
  out_colors[m_idx[valid]] <- match_df$color[valid]

  raw_breaks <- names(out_colors)
  # Palette direction only affects color assignment sequence, not legend order
  color_vector <- out_colors
  if (palette_direction == -1) {
    color_vector <- rev(color_vector)
    names(color_vector) <- raw_breaks  # keep original legend order names association
  }
  breaks <- raw_breaks
  if (!is.null(custom_order)) {
    # Preserve full custom order for specified items, then append others
    keep <- custom_order[custom_order %in% breaks]
    others <- setdiff(breaks, keep)
    breaks <- c(keep, others)
  }
  if (direction == -1) breaks <- rev(breaks)
  # Reindex values vector to match break order for stable legend presentation
  # Optionally remap legend labels based on hierarchy metadata
  labels <- breaks
  if (use_hierarchy && !is.null(sources) && requireNamespace("yaml", quietly = TRUE)) {
    htab <- try(hierarchy_to_table(section = section, include_groups = FALSE), silent = TRUE)
    if (!inherits(htab, "try-error")) {
      # Build alias -> canonical name map so that long/short forms in the data still map to the canonical row
      alias_names <- htab$name
      alias_targets <- htab$name
      if ("label_long" %in% names(htab)) {
        valid_long <- !is.na(htab$label_long) & nzchar(htab$label_long)
        alias_names <- c(alias_names, htab$label_long[valid_long])
        alias_targets <- c(alias_targets, htab$name[valid_long])
      }
      if ("label_short" %in% names(htab)) {
        valid_short <- !is.na(htab$label_short) & nzchar(htab$label_short)
        idx_short <- which(valid_short)
        for (j in idx_short) {
          al <- htab$label_short[j]
          if (!(al %in% alias_names)) {
            alias_names <- c(alias_names, al)
            alias_targets <- c(alias_targets, htab$name[j])
          }
        }
      }
      alias_lookup <- alias_targets; names(alias_lookup) <- alias_names
      key <- switch(label_style,
                    default = "label_default",
                    short = "label_short",
                    long = "label_long",
                    id = "name")
      if (key == "name") {
        # Keep original breaks as-is
        labels <- breaks
      } else if (key %in% names(htab)) {
        # For each break, resolve canonical name via alias map then fetch label
        canonical_for_break <- unname(alias_lookup[breaks])
        lab_map <- htab[[key]]; names(lab_map) <- htab$name
        fetched <- lab_map[canonical_for_break]
        # Fallback to original break if NA/empty
        fetched[is.na(fetched) | !nzchar(fetched)] <- breaks[is.na(fetched) | !nzchar(fetched)]
        labels <- fetched
      }
    }
  }
  ggplot2::scale_colour_manual(values = color_vector[breaks], breaks = breaks, limits = breaks, labels = labels, guide = guide, ...)
}

#' @rdname scale_color_energy
#' @export
scale_colour_energy <- scale_color_energy

#' Discrete Fill Scale for Energy Data
#'
#' @inheritParams scale_color_energy
#' @return A ggplot2 scale object
#' @export
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' 
#' # Stacked bar chart with default palette
#' ggplot(energy_mix, aes(x = country, y = percentage, fill = source)) +
#'   geom_col() +
#'   scale_fill_energy() +
#'   labs(title = "Energy Mix by Country")
#'   
#' # Using specific palette (overrides default)
#' ggplot(energy_mix, aes(x = year, y = value, fill = technology)) +
#'   geom_area() +
#'   scale_fill_energy(palette = "epa_ghg")
#'   
#' # Change session default and use it
#' set_default_energy_palette("technology_focus")
#' ggplot(energy_mix, aes(x = year, y = value, fill = technology)) +
#'   geom_area() +
#'   scale_fill_energy()  # Uses technology_focus
#' }
scale_fill_energy <- function(palette = NULL,
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
                              use_hierarchy = FALSE,
                              section = c("carriers","technologies"),
                              label_style = c("default","short","long","id"),
                              ...) {
  if (is.null(palette)) palette <- get_default_energy_palette()
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package 'ggplot2' is required for this function.")
  section <- match.arg(section)
  label_style <- match.arg(label_style)

  sources <- NULL
  if (!is.null(data) && is.data.frame(data)) {
    guess_cols <- c("source","technology","fuel","energy_source")
    col_found <- intersect(guess_cols, names(data))
    if (length(col_found) > 0) sources <- unique(as.character(data[[col_found[1]]]))
  }
  if (is.null(sources) && use_hierarchy) {
    if (requireNamespace("yaml", quietly = TRUE)) {
      htab <- try(hierarchy_to_table(section = section, include_groups = FALSE), silent = TRUE)
      if (!inherits(htab, "try-error")) sources <- unique(htab$name)
    }
  }
  base_palette <- get_energy_palette(palette)
  if (is.null(sources)) sources <- names(base_palette)

  match_df <- match_energy_sources(sources, palette_name = palette, include_full_palette = FALSE, warn = FALSE)
  out_colors <- setNames(rep(unmapped_color, length(sources)), sources)
  m_idx <- match(match_df$original, sources)
  valid <- !is.na(match_df$matched) & !is.na(m_idx)
  out_colors[m_idx[valid]] <- match_df$color[valid]
  raw_breaks <- names(out_colors)
  color_vector <- out_colors
  if (palette_direction == -1) {
    color_vector <- rev(color_vector)
    names(color_vector) <- raw_breaks
  }
  breaks <- raw_breaks
  if (!is.null(custom_order)) {
    keep <- custom_order[custom_order %in% breaks]
    others <- setdiff(breaks, keep)
    breaks <- c(keep, others)
    # Reorder out_colors to ensure legend order aligns exactly
    out_colors <- out_colors[breaks]
  }
  if (direction == -1) breaks <- rev(breaks)
  labels <- breaks
  if (use_hierarchy && !is.null(sources) && requireNamespace("yaml", quietly = TRUE)) {
    htab <- try(hierarchy_to_table(section = section, include_groups = FALSE), silent = TRUE)
    if (!inherits(htab, "try-error")) {
      alias_names <- htab$name
      alias_targets <- htab$name
      if ("label_long" %in% names(htab)) {
        valid_long <- !is.na(htab$label_long) & nzchar(htab$label_long)
        alias_names <- c(alias_names, htab$label_long[valid_long])
        alias_targets <- c(alias_targets, htab$name[valid_long])
      }
      if ("label_short" %in% names(htab)) {
        valid_short <- !is.na(htab$label_short) & nzchar(htab$label_short)
        idx_short <- which(valid_short)
        for (j in idx_short) {
          al <- htab$label_short[j]
            if (!(al %in% alias_names)) {
              alias_names <- c(alias_names, al)
              alias_targets <- c(alias_targets, htab$name[j])
            }
        }
      }
      alias_lookup <- alias_targets; names(alias_lookup) <- alias_names
      key <- switch(label_style,
                    default = "label_default",
                    short = "label_short",
                    long = "label_long",
                    id = "name")
      if (key == "name") {
        labels <- breaks
      } else if (key %in% names(htab)) {
        canonical_for_break <- unname(alias_lookup[breaks])
        lab_map <- htab[[key]]; names(lab_map) <- htab$name
        fetched <- lab_map[canonical_for_break]
        fetched[is.na(fetched) | !nzchar(fetched)] <- breaks[is.na(fetched) | !nzchar(fetched)]
        labels <- fetched
      }
    }
  }
  ggplot2::scale_fill_manual(values = color_vector[breaks], breaks = breaks, limits = breaks, labels = labels, guide = guide, ...)
}

#' @examples
#' \dontrun{
#' # Manual specification with fallback
#' my_colors <- c("Coal" = "#2C2C2C", "Solar" = "#FFA500")
#' 
#' ggplot(energy_data, aes(x = year, y = value, fill = source)) +
#'   geom_area() +
#'   scale_fill_energy_manual(values = my_colors, palette = "iea_primary")
#' }
scale_fill_energy_manual <- function(values = NULL,
                                    palette = NULL,
                                    unmapped_color = "#999999",
                                    ...) {
  
  # Use default palette if none specified
  if (is.null(palette)) {
    palette <- get_default_energy_palette()
  }
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for this function.")
  }
  
  if (is.null(values)) {
    # Use the specified palette
    values <- get_energy_palette(palette)
  } else {
    # Extend with palette for unmapped values
    base_palette <- get_energy_palette(palette)
    
    # Add missing values from base palette
    missing_names <- setdiff(names(base_palette), names(values))
    if (length(missing_names) > 0) {
      values <- c(values, base_palette[missing_names])
    }
  }
  
  ggplot2::scale_fill_manual(values = values, ...)
}

#' @rdname scale_fill_energy_manual
#' @export
scale_color_energy_manual <- function(values = NULL,
                                     palette = NULL, 
                                     unmapped_color = "#999999",
                                     ...) {
  
  # Use default palette if none specified
  if (is.null(palette)) {
    palette <- get_default_energy_palette()
  }
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for this function.")
  }
  
  if (is.null(values)) {
    values <- get_energy_palette(palette)
  } else {
    base_palette <- get_energy_palette(palette)
    missing_names <- setdiff(names(base_palette), names(values))
    if (length(missing_names) > 0) {
      values <- c(values, base_palette[missing_names])
    }
  }
  
  ggplot2::scale_color_manual(values = values, ...)
}

#' @rdname scale_fill_energy_manual
#' @export
scale_colour_energy_manual <- scale_color_energy_manual

#' Energy Scale Using Pre-computed Color Column
#'
#' Use a pre-computed color column from the data for energy visualizations.
#' This is useful when you have already mapped colors using add_energy_colors()
#' or when you want direct control over the color mapping process.
#'
#' @param color_column Character, name of the column containing color values
#' @param data Optional data frame to validate color column exists
#' @param guide Type of legend guide (default: "legend") 
#' @param ... Additional arguments passed to [ggplot2::scale_color_identity()] or [ggplot2::scale_fill_identity()]
#'
#' @return A ggplot2 scale object
#' @export
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' 
#' # Pre-compute colors
#' data_with_colors <- add_energy_colors(energy_data, source_column = "source")
#' 
#' # Use the pre-computed colors
#' ggplot(data_with_colors, aes(x = year, y = value, fill = energy_color)) +
#'   geom_col() +
#'   scale_fill_energy_identity()
#' 
#' # With custom color column name
#' data_custom <- add_energy_colors(energy_data, "source", color_column = "my_colors")
#' ggplot(data_custom, aes(x = year, y = value, fill = my_colors)) +
#'   geom_col() +
#'   scale_fill_energy_identity()
#' 
#' # For color aesthetic
#' ggplot(data_with_colors, aes(x = year, y = value, color = energy_color)) +
#'   geom_point() +
#'   scale_color_energy_identity()
#' }
scale_fill_energy_identity <- function(color_column = "energy_color",
                                      data = NULL,
                                      guide = "legend",
                                      ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for this function.")
  }
  
  # Validate color column exists if data provided
  if (!is.null(data)) {
    if (!is.data.frame(data)) {
      stop("data must be a data frame")
    }
    if (!color_column %in% names(data)) {
      stop("color_column '", color_column, "' not found in data")
    }
  }
  
  ggplot2::scale_fill_identity(guide = guide, ...)
}

#' @rdname scale_fill_energy_identity
#' @export
scale_color_energy_identity <- function(color_column = "energy_color",
                                       data = NULL,
                                       guide = "legend",
                                       ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for this function.")
  }
  
  # Validate color column exists if data provided
  if (!is.null(data)) {
    if (!is.data.frame(data)) {
      stop("data must be a data frame")
    }
    if (!color_column %in% names(data)) {
      stop("color_column '", color_column, "' not found in data")
    }
  }
  
  ggplot2::scale_color_identity(guide = guide, ...)
}

#' @rdname scale_fill_energy_identity
#' @export
scale_colour_energy_identity <- scale_color_energy_identity

#' Energy Scale with Custom Mapping Function
#'
#' Apply a custom mapping function to energy data for color assignment.
#' This provides maximum flexibility for users who want to implement
#' their own color mapping logic.
#'
#' @param mapping_function Function that takes sources as first argument and returns named color vector
#' @param data Optional data frame to extract source levels from specific column
#' @param source_column Character, name of column containing energy sources (if data provided)
#' @param fallback_palette Character, energy palette to use if mapping function fails
#' @param guide Type of legend guide (default: "legend")
#' @param ... Additional arguments passed to the mapping function
#'
#' @return A ggplot2 scale object
#' @export
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' 
#' # Define a custom mapping function
#' my_custom_mapper <- function(sources, intensity = 0.4, palette_name = "renewable_focus") {
#'   # Custom logic - maybe based on carbon intensity or other criteria
#'   colors <- map_energy_colors(sources, 
#'                              palette_name = palette_name,
#'                              apply_variations = TRUE, 
#'                              variation_intensity = intensity)
#'   
#'   # Apply custom modifications
#'   if ("Coal" %in% names(colors)) {
#'     colors["Coal"] <- "#1a1a1a"  # Make coal darker
#'   }
#'   
#'   return(colors)
#' }
#' 
#' # Use in ggplot2
#' ggplot(energy_data, aes(x = year, y = value, fill = source)) +
#'   geom_col() +
#'   scale_fill_energy_custom(
#'     mapping_function = my_custom_mapper,
#'     intensity = 0.6,
#'     palette_name = "technology_focus"
#'   )
#' 
#' # Pre-compute colors and use identity scale
#' data_with_colors <- energy_data
#' unique_sources <- unique(energy_data$source)
#' custom_colors <- my_custom_mapper(unique_sources, intensity = 0.3)
#' data_with_colors$colors <- custom_colors[data_with_colors$source]
#' 
#' ggplot(data_with_colors, aes(x = year, y = value, fill = colors)) +
#'   geom_col() +
#'   scale_fill_identity()
#' }
scale_fill_energy_custom <- function(mapping_function,
                                    data = NULL,
                                    source_column = "source",
                                    fallback_palette = NULL,
                                    guide = "legend",
                                    ...) {
  
  if (!is.function(mapping_function)) {
    stop("mapping_function must be a function that takes 'sources' as first argument")
  }
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for this function.")
  }
  
  # Use default palette as fallback if none specified
  if (is.null(fallback_palette)) {
    fallback_palette <- get_default_energy_palette()
  }
  
  # Capture additional arguments
  custom_args <- list(...)
  
  # Create the palette function that will call the custom mapper
  energy_pal_custom <- function(n) {
    # Try to get source names from the plot context
    # This is complex with ggplot2, so we provide a simpler approach
    
    if (!is.null(data) && source_column %in% names(data)) {
      # Use provided data
      sources <- unique(data[[source_column]])
    } else {
      # Generate generic source names and let the function handle it
      sources <- paste0("Source_", seq_len(n))
    }
    
    tryCatch({
      # Call the custom mapping function with additional arguments
      result <- do.call(mapping_function, c(list(sources = sources), custom_args))
      
      if (is.null(names(result))) {
        names(result) <- sources[seq_along(result)]
      }
      
      # Ensure we have enough colors
      if (length(result) >= n) {
        return(result[seq_len(n)])
      } else {
        # Extend with fallback palette
        fallback_pal <- get_energy_palette(fallback_palette)
        return(c(result, fallback_pal[seq_len(n - length(result))]))
      }
      
    }, error = function(e) {
      warning("Custom mapping function failed: ", e$message, 
              ". Using fallback palette.")
      fallback_pal <- get_energy_palette(fallback_palette)
      return(fallback_pal[seq_len(min(n, length(fallback_pal)))])
    })
  }
  
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = energy_pal_custom,
    guide = guide
  )
}

#' @rdname scale_fill_energy_custom
#' @export
scale_color_energy_custom <- function(mapping_function,
                                     data = NULL,
                                     source_column = "source",
                                     fallback_palette = NULL,
                                     guide = "legend",
                                     ...) {
  
  if (!is.function(mapping_function)) {
    stop("mapping_function must be a function that takes 'sources' as first argument")
  }
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for this function.")
  }
  
  if (is.null(fallback_palette)) {
    fallback_palette <- get_default_energy_palette()
  }
  
  custom_args <- list(...)
  
  energy_pal_custom <- function(n) {
    if (!is.null(data) && source_column %in% names(data)) {
      sources <- unique(data[[source_column]])
    } else {
      sources <- paste0("Source_", seq_len(n))
    }
    
    tryCatch({
      result <- do.call(mapping_function, c(list(sources = sources), custom_args))
      
      if (is.null(names(result))) {
        names(result) <- sources[seq_along(result)]
      }
      
      if (length(result) >= n) {
        return(result[seq_len(n)])
      } else {
        fallback_pal <- get_energy_palette(fallback_palette)
        return(c(result, fallback_pal[seq_len(n - length(result))]))
      }
      
    }, error = function(e) {
      warning("Custom mapping function failed: ", e$message, 
              ". Using fallback palette.")
      fallback_pal <- get_energy_palette(fallback_palette)
      return(fallback_pal[seq_len(min(n, length(fallback_pal)))])
    })
  }
  
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = energy_pal_custom,
    guide = guide
  )
}

#' @rdname scale_fill_energy_custom  
#' @export
scale_colour_energy_custom <- scale_color_energy_custom