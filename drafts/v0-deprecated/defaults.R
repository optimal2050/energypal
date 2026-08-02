#' Default Palette Management
#'
#' Functions to set and get the default palette for energy visualization scales.
#' This allows setting a session-wide default palette that will be used by
#' scale functions when no palette is explicitly specified.
#'

# Package option names (prefixed to avoid conflicts)
.energypal_option_names <- list(
  default_palette = "energypal.default_palette",
  enable_auto_variations = "energypal.enable_auto_variations",
  variation_type = "energypal.variation_type", 
  variation_intensity = "energypal.variation_intensity",
  min_sources_for_variation = "energypal.min_sources_for_variation",
  warn_duplicate_mappings = "energypal.warn_duplicate_mappings",
  warn_auto_variations = "energypal.warn_auto_variations",
  variation_display_method = "energypal.variation_display_method"
)

# Initialize default options on package load
.onLoad <- function(libname, pkgname) {
  # Set default options only if they don't already exist
  default_opts <- list()
  default_opts[[.energypal_option_names$default_palette]] <- "hierarchy_carriers"
  default_opts[[.energypal_option_names$enable_auto_variations]] <- FALSE
  default_opts[[.energypal_option_names$variation_type]] <- "lightness"
  default_opts[[.energypal_option_names$variation_intensity]] <- 0.3
  default_opts[[.energypal_option_names$min_sources_for_variation]] <- 2
  default_opts[[.energypal_option_names$warn_duplicate_mappings]] <- TRUE
  default_opts[[.energypal_option_names$warn_auto_variations]] <- TRUE
  default_opts[[.energypal_option_names$variation_display_method]] <- "append"
  
  # Only set options that don't already exist
  existing_opts <- options()
  for (opt_name in names(default_opts)) {
    if (!opt_name %in% names(existing_opts)) {
      options(setNames(list(default_opts[[opt_name]]), opt_name))
    }
  }
}

#' Set Default Energy Palette
#'
#' Sets the default palette to be used by scale functions when no palette
#' is explicitly specified.
#'
#' @param palette Character string specifying the palette name to use as default.
#'   Must be one of the available energy palettes.
#' @param validate Logical, whether to validate that the palette exists (default: TRUE)
#'
#' @return Invisibly returns the previous default palette name
#' @export
#'
#' @examples
#' \dontrun{
#' # Set renewable focus as default
#' set_default_energy_palette("renewable_focus")
#' 
#' # Now all scale functions will use renewable_focus by default
#' ggplot(data, aes(x = year, y = value, fill = source)) +
#'   geom_col() +
#'   scale_fill_energy()  # Uses renewable_focus automatically
#'   
#' # You can still override for specific plots
#' ggplot(data, aes(x = year, y = value, fill = source)) +
#'   geom_col() +
#'   scale_fill_energy(palette = "epa_ghg")  # Override with epa_ghg
#'   
#' # Reset to package default
#' set_default_energy_palette("iea_primary")
#' }
set_default_energy_palette <- function(palette, validate = TRUE) {
  if (validate) {
    available_palettes <- get_energy_palette_names()
    if (!palette %in% available_palettes) {
      stop("Palette '", palette, "' not found. Available palettes: ", paste(available_palettes, collapse = ", "))
    }
  }
  previous <- getOption(.energypal_option_names$default_palette, "hierarchy_carriers")
  options(setNames(list(palette), .energypal_option_names$default_palette))
  message("Default energy palette set to: ", palette)
  invisible(previous)
}

#' Get Default Energy Palette
#'
#' Returns the currently set default palette name.
#'
#' @return Character string with the current default palette name
#' @export
#'
#' @examples
#' # Check current default
#' get_default_energy_palette()
#' 
#' # Use in custom functions
#' my_function <- function(palette = get_default_energy_palette()) {
#'   colors <- get_energy_palette(palette)
#'   # ... rest of function
#' }
get_default_energy_palette <- function() {
  return(getOption(.energypal_option_names$default_palette, "hierarchy_carriers"))
}

#' Reset Default Energy Palette
#'
#' Resets the default palette to the package default ("iea_primary").
#'
#' @return Invisibly returns the previous default palette name
#' @export
#'
#' @examples
#' # After changing defaults, reset to package default
#' reset_default_energy_palette()
reset_default_energy_palette <- function() {
  previous <- getOption(.energypal_option_names$default_palette, "hierarchy_carriers")
  options(setNames(list("hierarchy_carriers"), .energypal_option_names$default_palette))
  message("Default energy palette reset to: hierarchy_carriers")
  invisible(previous)
}

#' Show Current Energy Palette Configuration
#'
#' Displays information about the current default palette and available options.
#'
#' @param show_palettes Logical, whether to display all available palettes (default: TRUE)
#'
#' @return Invisibly returns a list with configuration information
#' @export
#'
#' @examples
#' # Show current configuration
#' show_energy_palette_config()
#' 
#' # Just show default without listing all palettes
#' show_energy_palette_config(show_palettes = FALSE)
show_energy_palette_config <- function(show_palettes = TRUE) {
  
  current_default <- get_default_energy_palette()
  available_palettes <- get_energy_palette_names()
  
  cat("=== Energy Palette Configuration ===\n")
  cat("Current default palette:", current_default, "\n")
  cat("Available palettes:     ", length(available_palettes), "total\n\n")
  
  if (show_palettes) {
    cat("Available palette names:\n")
    for (i in seq_along(available_palettes)) {
      prefix <- if (available_palettes[i] == current_default) "* " else "  "
      cat(prefix, available_palettes[i], "\n")
    }
    cat("\n* = current default\n")
  }
  
  config_info <- list(
    default_palette = current_default,
    available_palettes = available_palettes,
    total_palettes = length(available_palettes)
  )
  
  invisible(config_info)
}

#' Set Temporary Default Palette
#'
#' Temporarily changes the default palette and returns a function to restore
#' the previous default. Useful for creating consistent visualizations within
#' a specific analysis or report section.
#'
#' @param palette Character string specifying the temporary default palette
#' @param validate Logical, whether to validate the palette exists (default: TRUE)
#'
#' @return Function that restores the previous default when called
#' @export
#'
#' @examples
#' \dontrun{
#' # Temporarily use renewable focus for a series of plots
#' restore_default <- set_temporary_energy_palette("renewable_focus")
#' 
#' # Create multiple plots that all use renewable_focus by default
#' p1 <- ggplot(data1, aes(x = year, y = value, fill = source)) +
#'   geom_col() + scale_fill_energy()
#'   
#' p2 <- ggplot(data2, aes(x = region, y = capacity, fill = technology)) +
#'   geom_col() + scale_fill_energy()
#' 
#' # Restore previous default
#' restore_default()
#' 
#' # Or use with() for automatic cleanup
#' with_temporary_palette <- function(palette, expr) {
#'   restore <- set_temporary_energy_palette(palette)
#'   on.exit(restore())
#'   force(expr)
#' }
#' 
#' plots <- with_temporary_palette("epa_ghg", {
#'   list(
#'     plot1 = ggplot(...) + scale_fill_energy(),
#'     plot2 = ggplot(...) + scale_color_energy()
#'   )
#' })
#' }
set_temporary_energy_palette <- function(palette, validate = TRUE) {
  
  # Store current default
  previous_default <- get_default_energy_palette()
  set_default_energy_palette(palette, validate = validate)
  
  # Return restoration function
  restore_function <- function() {
    options(setNames(list(previous_default), .energypal_option_names$default_palette))
  message("Default energy palette restored to: ", previous_default)
  }
  
  return(restore_function)
}

#' Set Energy Palette Options
#'
#' Configure package-wide options for energy palette behavior, including 
#' color variations and warning settings.
#'
#' @param ... Named arguments for options to set. Available options:
#'   \itemize{
#'     \item \code{enable_auto_variations}: Logical, enable automatic color variations for duplicates
#'     \item \code{variation_type}: Character, type of variation ("lightness", "saturation", "hue", "mixed")
#'     \item \code{variation_intensity}: Numeric, intensity of variation (0-1)
#'     \item \code{min_sources_for_variation}: Integer, minimum sources for variation
#'     \item \code{warn_duplicate_mappings}: Logical, warn about duplicate mappings
#'     \item \code{warn_auto_variations}: Logical, warn when variations are applied
#'     \item \code{variation_display_method}: Character, naming method for variations
#'   }
#'
#' @return Invisibly returns the previous options as a list
#' @export
#'
#' @examples
#' # Enable automatic color variations
#' set_energy_options(enable_auto_variations = TRUE, variation_intensity = 0.4)
#' 
#' # Disable warnings
#' set_energy_options(warn_duplicate_mappings = FALSE)
#' 
#' # Use saturation-based variations
#' set_energy_options(variation_type = "saturation")
set_energy_options <- function(...) {
  new_options <- list(...)
  
  if (length(new_options) == 0) {
    # Return current options
    current_opts <- list()
    for (opt_name in names(.energypal_option_names)) {
      if (opt_name != "default_palette") {  # Skip default_palette as it has its own functions
        current_opts[[opt_name]] <- getOption(.energypal_option_names[[opt_name]])
      }
    }
    return(invisible(current_opts))
  }
  
  # Validate option names
  valid_options <- names(.energypal_option_names)
  valid_options <- valid_options[valid_options != "default_palette"]  # Exclude default_palette
  invalid_options <- setdiff(names(new_options), valid_options)
  
  if (length(invalid_options) > 0) {
    stop("Invalid option(s): ", paste(invalid_options, collapse = ", "), 
         "\nValid options: ", paste(valid_options, collapse = ", "))
  }
  
  # Store previous options
  previous_options <- list()
  for (opt_name in names(new_options)) {
    previous_options[[opt_name]] <- getOption(.energypal_option_names[[opt_name]])
  }
  
  # Validate specific options
  if ("variation_intensity" %in% names(new_options)) {
    intensity <- new_options$variation_intensity
    if (!is.numeric(intensity) || intensity < 0 || intensity > 1) {
      stop("variation_intensity must be numeric between 0 and 1")
    }
  }
  
  if ("variation_type" %in% names(new_options)) {
    valid_types <- c("lightness", "saturation", "hue", "mixed")
    if (!new_options$variation_type %in% valid_types) {
      stop("variation_type must be one of: ", paste(valid_types, collapse = ", "))
    }
  }
  
  # Update options
  for (option_name in names(new_options)) {
    full_option_name <- .energypal_option_names[[option_name]]
    options(setNames(list(new_options[[option_name]]), full_option_name))
  }
  
  message("Energy palette options updated")
  invisible(previous_options)
}

#' Get Energy Palette Options
#'
#' Retrieve current package options for energy palette behavior.
#'
#' @param option Character, specific option name to retrieve. If NULL, returns all options.
#'
#' @return The option value if \code{option} is specified, otherwise a list of all options
#' @export
#'
#' @examples
#' # Get all options
#' get_energy_options()
#' 
#' # Get specific option
#' get_energy_options("enable_auto_variations")
get_energy_options <- function(option = NULL) {
  if (is.null(option)) {
    # Return all options
    current_opts <- list()
    for (opt_name in names(.energypal_option_names)) {
      if (opt_name != "default_palette") {  # Skip default_palette as it has its own functions
        current_opts[[opt_name]] <- getOption(.energypal_option_names[[opt_name]])
      }
    }
    return(current_opts)
  } else {
    # Return specific option
    valid_options <- names(.energypal_option_names)
    valid_options <- valid_options[valid_options != "default_palette"]
    
    if (!option %in% valid_options) {
      stop("Unknown option: ", option, 
           "\nValid options: ", paste(valid_options, collapse = ", "))
    }
    
    return(getOption(.energypal_option_names[[option]]))
  }
}

#' Reset Energy Palette Options
#'
#' Reset all package options to their default values.
#'
#' @return Invisibly returns the previous options
#' @export
#'
#' @examples
#' # After changing options, reset to defaults
#' reset_energy_options()
reset_energy_options <- function() {
  # Get current options
  previous_options <- get_energy_options()
  
  # Reset to defaults (excluding default_palette)
  default_values <- list(
    enable_auto_variations = FALSE,
    variation_type = "lightness",
    variation_intensity = 0.3,
    min_sources_for_variation = 2,
    warn_duplicate_mappings = TRUE,
    warn_auto_variations = TRUE,
    variation_display_method = "append"
  )
  
  # Set default options
  for (opt_name in names(default_values)) {
    full_option_name <- .energypal_option_names[[opt_name]]
    options(setNames(list(default_values[[opt_name]]), full_option_name))
  }
  
  message("Energy palette options reset to defaults")
  invisible(previous_options)
}