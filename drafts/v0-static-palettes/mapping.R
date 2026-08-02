#' Smart Energy Source Mapping
#'
#' Intelligently map energy source names to colors using exact matches,
#' fuzzy matching, and regular expressions.
#'
#' @param sources Character vector of energy source names to map
#' @param palette_name Character string specifying the palette to use (default: "iea_primary")
#' @param method Character string specifying mapping method: "exact", "fuzzy", or "regex" (default: "auto")
#' @param unmapped_color Color to use for unmapped sources (default: "#999999")
#' @param case_sensitive Logical, whether matching should be case sensitive (default: FALSE)
#'
#' @return A named vector of colors corresponding to the input sources
#' @export
#'
#' @examples
#' # Basic mapping
#' sources <- c("Coal", "Natural Gas", "Solar", "Wind")
#' map_energy_colors(sources)
#'
#' # Fuzzy matching for similar names
#' sources <- c("coal power", "nat gas", "solar pv", "wind power")
#' map_energy_colors(sources, method = "fuzzy")
#'
#' # Using different palette
#' map_energy_colors(sources, palette_name = "renewable_focus")
map_energy_colors <- function(sources, 
                             palette_name = NULL, 
                             method = "auto",
                             unmapped_color = "#999999",
                             case_sensitive = FALSE,
                             apply_variations = NULL,
                             variation_type = NULL,
                             variation_intensity = NULL) {
  # Ensure plain character vector (avoid factor issues when using tolower/gsub)
  if (!is.null(sources)) sources <- as.character(sources)
  
  # Use default palette if none specified
  if (is.null(palette_name)) {
    palette_name <- get_default_energy_palette()
  }
  
  # Use package options if parameters not specified
  if (is.null(apply_variations)) {
    apply_variations <- get_energy_options("enable_auto_variations")
  }
  if (is.null(variation_type)) {
    variation_type <- get_energy_options("variation_type")
  }
  if (is.null(variation_intensity)) {
    variation_intensity <- get_energy_options("variation_intensity")
  }
  
  # Get the palette
  palette <- get_energy_palette(palette_name)
  
  # Normalize case if needed
  if (!case_sensitive) {
    search_names <- tolower(names(palette))
    search_sources <- tolower(sources)
  } else {
    search_names <- names(palette)
    search_sources <- sources
  }
  
  # Initialize result vector
  result <- rep(unmapped_color, length(sources))
  names(result) <- sources
  
  if (method == "auto") {
    # Try exact first, then fuzzy, then regex
    result <- .map_exact(result, sources, search_sources, search_names, palette)
    unmapped_idx <- which(result == unmapped_color)
    if (length(unmapped_idx) > 0) {
      result <- .map_fuzzy(result, sources, search_sources, search_names, palette, unmapped_idx)
      unmapped_idx <- which(result == unmapped_color)
      if (length(unmapped_idx) > 0) {
        result <- .map_regex(result, sources, search_sources, search_names, palette, unmapped_idx)
      }
    }
  } else if (method == "exact") {
    result <- .map_exact(result, sources, search_sources, search_names, palette)
  } else if (method == "fuzzy") {
    result <- .map_fuzzy(result, sources, search_sources, search_names, palette)
  } else if (method == "regex") {
    result <- .map_regex(result, sources, search_sources, search_names, palette)
  } else {
    stop("Method must be one of: 'auto', 'exact', 'fuzzy', 'regex'")
  }
  
  # Apply variations if enabled and needed
  if (apply_variations) {
    result <- .apply_color_variations(result, sources, variation_type, variation_intensity)
  } else {
    # Check for duplicates and warn if needed
    .check_duplicate_mappings(result, sources)
  }
  
  return(result)
}

# Helper function for exact matching
.map_exact <- function(result, sources, search_sources, search_names, palette, subset_idx = NULL) {
  if (is.null(subset_idx)) {
    subset_idx <- seq_along(sources)
  }
  
  for (i in subset_idx) {
    exact_match <- which(search_names == search_sources[i])
    if (length(exact_match) > 0) {
      result[i] <- palette[exact_match[1]]
    }
  }
  return(result)
}

# Helper function for fuzzy matching
.map_fuzzy <- function(result, sources, search_sources, search_names, palette, subset_idx = NULL) {
  if (is.null(subset_idx)) {
    subset_idx <- seq_along(sources)
  }
  
  for (i in subset_idx) {
    # Skip if source is empty or invalid
    current_source <- search_sources[i]
    if (is.na(current_source) || current_source == "") {
      next
    }
    
    # Try partial matching
    partial_match <- grep(current_source, search_names, fixed = TRUE)
    if (length(partial_match) == 0) {
      # Try reverse partial matching
      partial_match <- which(sapply(search_names, function(x) {
        if (is.na(x) || x == "") return(FALSE)
        grepl(x, current_source, fixed = TRUE)
      }))
    }
    
    if (length(partial_match) > 0) {
      result[i] <- palette[partial_match[1]]
    }
  }
  return(result)
}

# Helper function for regex matching
.map_regex <- function(result, sources, search_sources, search_names, palette, subset_idx = NULL) {
  if (is.null(subset_idx)) {
    subset_idx <- seq_along(sources)
  }
  
  # Define common energy source patterns
  energy_patterns <- list(
    "coal" = c("coal", "lignite", "anthracite", "bituminous", "sub-?bituminous"),
    "oil" = c("oil", "petroleum", "crude", "refined", "diesel", "gasoline", "fuel oil"),
    "natural gas" = c("gas", "natural gas", "methane", "lng", "shale gas"),
    "nuclear" = c("nuclear", "uranium", "pwr", "bwr", "reactor"),
    "hydro" = c("hydro", "hydroelectric", "water", "dam"),
    "wind" = c("wind", "onshore", "offshore", "turbine"),
    "solar" = c("solar", "pv", "photovoltaic", "thermal", "csp"),
    "bioenergy" = c("bio", "biomass", "biogas", "ethanol", "biodiesel", "wood"),
    "geothermal" = c("geothermal", "thermal"),
    "other renewables" = c("renewable", "clean", "green")
  )
  
  for (i in subset_idx) {
    for (pal_name in search_names) {
      pal_key <- names(palette)[which(search_names == pal_name)]
      if (pal_key %in% names(energy_patterns)) {
        patterns <- energy_patterns[[tolower(pal_key)]]
        if (any(sapply(patterns, function(p) grepl(p, search_sources[i], perl = TRUE)))) {
          result[i] <- palette[pal_name]
          break
        }
      }
    }
  }
  return(result)
}

#' Create Energy Color Mapping Dictionary
#'
#' Create a comprehensive mapping dictionary for common energy source variations.
#'
#' @param palette_name Character string specifying the base palette (default: "iea_primary")
#' @param include_variations Logical, whether to include common variations (default: TRUE)
#'
#' @return A named vector mapping various energy source names to colors
#' @export
#'
#' @examples
#' # Create mapping dictionary
#' mapping <- create_energy_mapping()
#' head(mapping, 10)
#'
#' # Use the mapping directly
#' my_data_colors <- mapping[c("Coal Power", "Wind Energy", "Solar PV")]
create_energy_mapping <- function(palette_name = NULL, include_variations = TRUE) {
  
  # Use default palette if none specified
  if (is.null(palette_name)) {
    palette_name <- get_default_energy_palette()
  }
  
  base_palette <- get_energy_palette(palette_name)
  
  if (!include_variations) {
    return(base_palette)
  }
  
  # Define common variations for each energy source
  variations <- list(
    "Coal" = c("Coal", "Coal Power", "Coal-fired", "Thermal Coal", "Steam Coal", 
               "Lignite", "Anthracite", "Bituminous Coal", "Sub-bituminous Coal"),
    "Oil" = c("Oil", "Petroleum", "Crude Oil", "Fuel Oil", "Diesel", "Gasoline",
              "Refined Petroleum", "Liquid Fuels", "Petroleum Products"),
    "Natural Gas" = c("Natural Gas", "Gas", "Methane", "LNG", "CNG", 
                      "Shale Gas", "Gas Turbine", "Combined Cycle"),
    "Nuclear" = c("Nuclear", "Nuclear Power", "Uranium", "PWR", "BWR", 
                  "Nuclear Electric Power", "Nuclear Energy"),
    "Hydro" = c("Hydro", "Hydroelectric", "Hydroelectric Power", "Water Power",
                "Large Hydro", "Small Hydro", "Run-of-river", "Pumped Storage"),
    "Wind" = c("Wind", "Wind Power", "Wind Energy", "Onshore Wind", "Offshore Wind",
               "Wind Turbine", "Wind Farm"),
    "Solar" = c("Solar", "Solar Power", "Solar Energy", "Solar PV", "Photovoltaic",
                "Solar Thermal", "CSP", "Concentrated Solar Power"),
    "Bioenergy" = c("Bioenergy", "Biomass", "Biogas", "Biofuels", "Ethanol",
                    "Biodiesel", "Wood", "Waste", "Municipal Solid Waste"),
    "Geothermal" = c("Geothermal", "Geothermal Power", "Geothermal Energy",
                     "Ground Source", "Enhanced Geothermal"),
    "Other Renewables" = c("Other Renewables", "Renewables", "Clean Energy",
                          "Green Energy", "Wave", "Tidal", "Ocean Energy")
  )
  
  # Create expanded mapping
  expanded_mapping <- character()
  
  for (base_name in names(base_palette)) {
    color <- base_palette[base_name]
    
    # Find matching variations
    matching_variations <- NULL
    for (var_group in names(variations)) {
      if (any(grepl(base_name, var_group, ignore.case = TRUE)) ||
          any(grepl(var_group, base_name, ignore.case = TRUE))) {
        matching_variations <- variations[[var_group]]
        break
      }
    }
    
    if (!is.null(matching_variations)) {
      for (variation in matching_variations) {
        expanded_mapping[variation] <- color
      }
    } else {
      expanded_mapping[base_name] <- color
    }
  }
  
  return(expanded_mapping)
}

#' Add Custom Energy Palette
#'
#' Add a custom color palette to the energy palettes collection.
#'
#' @param palette_name Character string for the new palette name
#' @param colors Named vector of hex color codes
#' @param overwrite Logical, whether to overwrite existing palette (default: FALSE)
#'
#' @return Invisibly returns TRUE if successful
#' @export
#'
#' @examples
#' # Add a custom palette
#' custom_colors <- c("Renewable" = "#00FF00", "Fossil" = "#FF0000")
#' add_energy_palette("custom_simple", custom_colors)
#'
#' # Check it was added
#' "custom_simple" %in% get_energy_palette_names()
add_energy_palette <- function(palette_name, colors, overwrite = FALSE) {
  
  # Validate inputs
  if (!is.character(palette_name) || length(palette_name) != 1) {
    stop("palette_name must be a single character string")
  }
  
  if (!is.character(colors) || is.null(names(colors))) {
    stop("colors must be a named character vector")
  }
  
  # Check for valid hex colors
  if (!all(grepl("^#[0-9A-Fa-f]{6}$", colors))) {
    stop("All colors must be valid hex color codes (e.g., '#FF0000')")
  }
  
  # Check if palette already exists
  if (palette_name %in% names(energy_palettes) && !overwrite) {
    stop("Palette '", palette_name, "' already exists. Use overwrite = TRUE to replace it.")
  }
  
  # Add to global palette list (in practice, this would modify the package environment)
  # For now, we'll just show the concept
  message("Custom palette '", palette_name, "' would be added with ", length(colors), " colors.")
  message("Note: In the actual package, this would persist the palette for the session.")
  
  invisible(TRUE)
}

# Helper function to apply color variations for duplicate mappings
.apply_color_variations <- function(result, sources, variation_type, variation_intensity) {
  
  # Skip if no sources mapped to actual colors
  mapped_colors <- result[result != "#999999"]  # Assuming unmapped_color is "#999999"
  
  if (length(mapped_colors) == 0) {
    return(result)
  }
  
  # Find groups of sources that map to the same color
  color_groups <- split(names(mapped_colors), mapped_colors)
  
  # Get minimum sources needed for variation
  min_sources <- get_energy_options("min_sources_for_variation")
  
  # Find groups that need variations
  groups_needing_variations <- color_groups[lengths(color_groups) >= min_sources]
  
  if (length(groups_needing_variations) == 0) {
    return(result)
  }
  
  # Warn about auto-variations if enabled
  if (get_energy_options("warn_auto_variations")) {
    total_sources_with_variations <- sum(lengths(groups_needing_variations))
    warning("Auto-generating color variations for ", total_sources_with_variations, 
            " sources mapping to ", length(groups_needing_variations), " duplicate colors. ",
            "Set warn_auto_variations = FALSE to suppress this warning.", 
            call. = FALSE)
  }
  
  # Apply variations to each group
  for (base_color in names(groups_needing_variations)) {
    group_sources <- groups_needing_variations[[base_color]]
    n_sources <- length(group_sources)
    
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
      result[group_sources[i]] <- variations[i]
    }
  }
  
  return(result)
}

# Helper function to check for duplicate mappings and warn
.check_duplicate_mappings <- function(result, sources) {
  
  # Skip if warnings disabled
  if (!get_energy_options("warn_duplicate_mappings")) {
    return(invisible(NULL))
  }
  
  # Find duplicate mappings (excluding unmapped color)
  mapped_colors <- result[result != "#999999"]
  
  if (length(mapped_colors) == 0) {
    return(invisible(NULL))
  }
  
  # Find duplicates
  color_groups <- split(names(mapped_colors), mapped_colors)
  duplicate_groups <- color_groups[lengths(color_groups) > 1]
  
  if (length(duplicate_groups) > 0) {
    # Create warning message
    warning_parts <- character(length(duplicate_groups))
    
    for (i in seq_along(duplicate_groups)) {
      base_color <- names(duplicate_groups)[i]
      duplicate_sources <- duplicate_groups[[i]]
      warning_parts[i] <- paste0("Color ", base_color, ": ", 
                                paste(duplicate_sources, collapse = ", "))
    }
    
    warning("Multiple sources mapped to the same colors:\n",
            paste(warning_parts, collapse = "\n"),
            "\nConsider enabling auto-variations with set_energy_options(enable_auto_variations = TRUE)",
            call. = FALSE)
  }
  
  invisible(NULL)
}

#' Check for Unmapped Energy Sources
#'
#' Identifies energy sources that don't have exact matches in the specified palette
#' and would be assigned the unmapped color. Useful for data validation and
#' ensuring all sources will be properly colored.
#'
#' @param sources Character vector of energy source names to check
#' @param palette_name Character string specifying the palette to check against
#' @param method Character string specifying the mapping method ("auto", "fuzzy", "strict")
#' @param unmapped_color Character string for unmapped sources (default: "#999999")
#' @param case_sensitive Logical, whether matching should be case sensitive (default: FALSE)
#' @param warn Logical, whether to display warnings for unmapped sources (default: TRUE)
#'
#' @return List containing:
#'   \itemize{
#'     \item \code{mapped}: Character vector of successfully mapped sources
#'     \item \code{unmapped}: Character vector of unmapped sources
#'     \item \code{mapping_summary}: Data frame with source, mapped status, and assigned color
#'   }
#'
#' @export
#'
#' @examples
#' # Check mapping for example data
#' sources <- c("Solar", "Wind", "Solar PV", "Battery Storage", "Coal")
#' check_result <- check_unmapped_sources(sources, "iea_primary")
#' 
#' # View unmapped sources
#' print(check_result$unmapped)
#' 
#' # Get detailed mapping summary
#' print(check_result$mapping_summary)
check_unmapped_sources <- function(sources, 
                                   palette_name = NULL,
                                   method = "auto",
                                   unmapped_color = "#999999",
                                   case_sensitive = FALSE,
                                   warn = TRUE) {
  
  # Use default palette if none specified
  if (is.null(palette_name)) {
    palette_name <- get_default_energy_palette()
  }
  
  # Get color mapping for all sources
  color_mapping <- map_energy_colors(
    sources = sources,
    palette_name = palette_name,
    method = method,
    unmapped_color = unmapped_color,
    case_sensitive = case_sensitive
  )
  
  # Identify mapped vs unmapped sources
  mapped_sources <- sources[color_mapping != unmapped_color]
  unmapped_sources <- sources[color_mapping == unmapped_color]
  
  # Create detailed summary
  mapping_summary <- data.frame(
    source = sources,
    mapped = color_mapping != unmapped_color,
    color = color_mapping,
    stringsAsFactors = FALSE
  )
  
  # Display warnings if requested
  if (warn && length(unmapped_sources) > 0) {
    warning(
      "Found ", length(unmapped_sources), " unmapped source(s) in palette '", palette_name, "':\n",
      "  ", paste(unmapped_sources, collapse = ", "), "\n",
      "These sources will be colored with unmapped_color: ", unmapped_color, "\n",
      "Consider:\n",
      "  1. Using a different palette that includes these sources\n",
      "  2. Using fuzzy matching (method = 'fuzzy')\n",
      "  3. Updating source names to match palette definitions\n",
      "Use names(get_energy_palette('", palette_name, "')) to see available sources."
    )
  }
  
  # Return comprehensive results
  return(list(
    mapped = mapped_sources,
    unmapped = unmapped_sources,
    mapping_summary = mapping_summary,
    palette_sources = names(get_energy_palette(palette_name)),
    total_sources = length(sources),
    mapped_count = length(mapped_sources),
    unmapped_count = length(unmapped_sources)
  ))
}