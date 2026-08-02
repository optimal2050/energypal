#' Smart Energy Source Mapping (Enhanced)
#'
#' Intelligently map energy source names to colors using a unified matching system
#' with exact matches, canonicalized matching, hierarchy aliases, fuzzy matching,
#' and regular expressions.
#'
#' @param sources Character vector of energy source names to map
#' @param palette_name Character string specifying the palette to use (default: "carriers")
#' @param match_method Character string specifying mapping method:
#'   "exact", "canonical", "alias", "fuzzy", "regex", or "auto" (default: "auto")
#' @param unmapped_color Color to use for unmapped sources (default: "#999999")
#' @param case_sensitive Logical, whether matching should be case sensitive (default: FALSE)
#' @param max_distance Maximum normalized distance for fuzzy matching (default: 0.4)
#' @param regex_patterns List of regex patterns or "auto" to generate from palette names
#' @param warn Logical, emit warnings for ambiguous matches (default: TRUE)
#'
#' @return A named vector of colors corresponding to the input sources
#' @export
#'
#' @examples
#' # Basic mapping
#' sources <- c("Coal", "Natural Gas", "Solar", "Wind")
#' energy_colors(sources)
#'
#' # Fuzzy matching for similar names
#' sources <- c("coal power", "nat gas", "solar pv", "wind power")
#' energy_colors(sources, match_method = "fuzzy")
#'
#' # Using regex patterns
#' energy_colors(sources, match_method = "regex")
#'
#' # Using specific methods only
#' energy_colors(sources, match_method = "exact")
energy_colors <- function(sources,
                           palette_name = "carriers",
                           match_method = "auto",
                           unmapped_color = "#999999",
                           case_sensitive = FALSE,
                           # apply_variations = NULL,
                           # variation_type = NULL,
                           # variation_intensity = NULL
                          ...) {
  # Ensure plain character vector (avoid factor issues when using tolower/gsub)
  if (!is.null(sources)) sources <- as.character(sources)

  # Use default palette if none specified
  if (is.null(palette_name)) {
    palette_name <- "carriers"
    # palette_name <- get_default_energy_palette()
  }

  # Use package options if parameters not specified
  # if (is.null(apply_variations)) {
  #   apply_variations <- get_energy_options("enable_auto_variations")
  # }
  # if (is.null(variation_type)) {
  #   variation_type <- get_energy_options("variation_type")
  # }
  # if (is.null(variation_intensity)) {
  #   variation_intensity <- get_energy_options("variation_intensity")
  # }

  # Get the palette
  # palette <- if (identical(palette_name, "carriers")) {
  #   energypal(section = "carriers", include_groups = FALSE, include_carriers = TRUE, include_subtypes = FALSE, label_style = "id")
  # } else {
  #   energypal(section = "carriers", include_groups = FALSE, include_carriers = TRUE, include_subtypes = FALSE, label_style = "id")
  # }
  palette <- energypal(palette_name, include_groups = T)

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

  if (match_method == "auto") {
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
  } else if (match_method == "exact") {
    result <- .map_exact(result, sources, search_sources, search_names, palette)
  } else if (match_method == "fuzzy") {
    result <- .map_fuzzy(result, sources, search_sources, search_names, palette)
  } else if (match_method == "regex") {
    result <- .map_regex(result, sources, search_sources, search_names, palette)
  } else {
    stop("Method must be one of: 'auto', 'exact', 'fuzzy', 'regex'")
  }

  # # Apply variations if enabled and needed
  # if (apply_variations) {
  #   result <- .apply_color_variations(result, sources, variation_type, variation_intensity)
  # } else {
  #   # Check for duplicates and warn if needed
  #   .check_duplicate_mappings(result, sources)
  # }

  return(result)
}

#' Match Energy Source Names to Palette Entries (Enhanced)
#'
#' Robust multi-stage matcher using the unified matching system to align
#' arbitrary data source labels to a palette's canonical source names.
#' Now implements the full suite of matching algorithms:
#' 1. Exact match
#' 2. Canonicalized (case/space/punct/number stripped) match
#' 3. Hierarchy alias matching (short/long labels)
#' 4. Advanced fuzzy matching with synonyms and string distance
#' 5. Regex pattern matching
#'
#' @param sources Character vector of (possibly repeated) source labels from data.
#' @param palette_name Character palette identifier (default: "carriers").
#' @param include_full_palette Logical; if TRUE, append unmatched palette rows even if
#'   not present in data (default FALSE).
#' @param max_distance Maximum normalized Levenshtein distance (0-1) allowed for fuzzy step (default 0.4).
#' @param warn Logical; emit warnings about ambiguous matches (default TRUE).
#' @param palette_vector Optional direct palette vector (overrides palette_name).
#'
#' @return data.frame with columns:
#'   original (unique input), matched (palette name or NA), color (hex or NA),
#'   method (match stage), candidates (semicolon list if ambiguous)
#' @export
#'
#' @examples
#' match_energy_sources(c("Coal","coal power","natural gas","Solar PV"))
#'
#' # With full palette included
#' match_energy_sources(c("Coal", "Wind"), include_full_palette = TRUE)
#'
#' # Using custom distance threshold
#' match_energy_sources(c("coalpwr", "windgen"), max_distance = 0.6)
match_energy_sources <- function(sources,
                                 palette_name = NULL,
                                 include_full_palette = FALSE,
                                 max_distance = 0.4,
                                 warn = TRUE,
                                 palette_vector = NULL) {
  # Allow direct provision of a palette vector (hierarchy-first refactor path)
  if (!is.null(palette_vector)) {
    pal <- palette_vector
  } else {
    if (is.null(palette_name)) palette_name <- "carriers"
    # For now, use energypal until get_energy_palette is available
    pal <- energypal(palette_name, include_groups = FALSE)
  }

  # Use unified matching system
  result <- match_energy_sources_v2(
    sources = sources,
    palette = pal,
    methods = "auto",
    case_sensitive = FALSE,
    max_distance = max_distance,
    regex_patterns = NULL,
    warn = warn,
    include_full_palette = include_full_palette
  )

  return(result)
}


# ============================================================================ #
# UNIFIED ENERGY SOURCE MATCHING SYSTEM
# ============================================================================ #

# Core canonicalization function (improved from match_energy_sources)
.canonicalize <- function(x) {
  # lower, remove all non-letters, collapse spaces
  x2 <- tolower(x)
  x2 <- gsub("[[:space:]]+", "", x2)
  x2 <- gsub("[^a-z]+", "", x2)
  x2
}

# Core distance calculation function
.norm_dist <- function(a, b) {
  stringdist::stringdist(a, b, method = "lv") / max(nchar(a), nchar(b), 1)
}

# Generate built-in energy patterns from hierarchy data
.get_default_energy_patterns <- function() {
  list(
    # Fossil Fuels
    "Coal" = c("coal", "lignite", "anthracite", "bituminous", "sub-?bituminous", "coke", "coalpower", "coalfired"),
    "FossilCoal" = c("coal", "lignite", "anthracite", "bituminous", "sub-?bituminous", "coke", "coalpower", "coalfired"),
    "Oil" = c("oil", "petroleum", "crude", "fuel.?oil", "diesel", "gasoline", "motor.?gasoline", "jet.?fuel", "lpg", "ngl"),
    "FossilOil" = c("oil", "petroleum", "crude", "fuel.?oil", "diesel", "gasoline", "motor.?gasoline", "jet.?fuel", "lpg", "ngl"),
    "Natural Gas" = c("(natural.?)?gas", "methane", "lng", "cng", "shale.?gas", "tight.?gas", "associated.?gas"),
    "FossilGas" = c("(natural.?)?gas", "methane", "lng", "cng", "shale.?gas", "tight.?gas", "associated.?gas"),

    # Nuclear
    "Nuclear" = c("nuclear", "uranium", "reactor", "pwr", "bwr", "smr"),

    # Renewables
    "Bioenergy" = c("bio(energy|mass|gas|fuel)?", "wood", "ethanol", "biodiesel", "waste", "solid.?biomass"),
    "Hydro" = c("hydro(electric)?", "water.?power", "pumped.?storage", "run.?of.?river", "large.?hydro", "small.?hydro"),
    "Wind" = c("wind", "onshore", "offshore", "turbine", "wind.?power", "wind.?energy"),
    "Solar" = c("solar", "pv", "photovoltaic", "csp", "solar.?thermal", "solar.?pv"),
    "Geothermal" = c("geothermal", "hydrothermal", "egs", "ground.?source"),

    # Synthetic
    "Hydrogen" = c("hydrogen", "h2", "green.?hydrogen", "blue.?hydrogen", "grey.?hydrogen", "pink.?hydrogen", "turquoise.?hydrogen"),
    "Synthetic" = c("synthetic", "e-?(methane|methanol|diesel|jet)", "ft.?liquids"),

    # Storage
    "Storage" = c("storage", "battery", "thermal.?storage"),

    # Other Renewables
    "OtherRenewables" = c("wave", "tidal", "ocean.?thermal", "renewable", "clean", "green"),
    "Other Renewables" = c("wave", "tidal", "ocean.?thermal", "renewable", "clean", "green")
  )
}

# ============================================================================ #
# MODULAR MATCHING FUNCTIONS
# ============================================================================ #

# Exact string matching
.match_exact <- function(sources, palette, case_sensitive = FALSE) {
  if (!case_sensitive) {
    search_names <- tolower(names(palette))
    search_sources <- tolower(sources)
  } else {
    search_names <- names(palette)
    search_sources <- sources
  }

  result <- data.frame(
    original = sources,
    matched = NA_character_,
    color = NA_character_,
    method = NA_character_,
    candidates = NA_character_,
    stringsAsFactors = FALSE
  )

  exact_hits <- match(search_sources, search_names)
  matched_exact <- !is.na(exact_hits)

  if (any(matched_exact)) {
    result$matched[matched_exact] <- names(palette)[exact_hits[matched_exact]]
    result$color[matched_exact] <- unname(palette[exact_hits[matched_exact]])
    result$method[matched_exact] <- "exact"
  }

  return(result)
}

# Canonicalized matching (case/space/punct/number stripped)
#.match_stripped
.match_canonical <- function(sources, palette, previous_result = NULL) {
  if (is.null(previous_result)) {
    result <- data.frame(
      original = sources,
      matched = NA_character_,
      color = NA_character_,
      method = NA_character_,
      candidates = NA_character_,
      stringsAsFactors = FALSE
    )
  } else {
    result <- previous_result
  }

  pal_names <- names(palette)
  pal_canon <- .canonicalize(pal_names)
  canon_input <- .canonicalize(sources)

  remaining <- which(is.na(result$matched))

  for (i in remaining) {
    idx <- which(pal_canon == canon_input[i])
    if (length(idx) == 1) {
      result$matched[i] <- pal_names[idx]
      result$color[i] <- unname(palette[idx])
      result$method[i] <- "canonical"
    }
  }

  return(result)
}

# Hierarchy alias matching (short/long labels)
.match_alias <- function(sources, palette, previous_result = NULL) {
  if (is.null(previous_result)) {
    result <- data.frame(
      original = sources,
      matched = NA_character_,
      color = NA_character_,
      method = NA_character_,
      candidates = NA_character_,
      stringsAsFactors = FALSE
    )
  } else {
    result <- previous_result
  }

  # Build hierarchy aliases if available
  hierarchy_aliases <- NULL
  if (requireNamespace("yaml", quietly = TRUE)) {
    alias_map <- list()
    safe_add <- function(tbl) {
      if (!is.null(tbl) && is.data.frame(tbl)) {
        in_pal <- tbl$name %in% names(palette)
        if (any(in_pal)) {
          sub <- tbl[in_pal, , drop = FALSE]
          if ("label_long" %in% names(sub)) {
            valid_long <- !is.na(sub$label_long) & nzchar(sub$label_long)
            if (any(valid_long)) alias_map[sub$label_long[valid_long]] <<- sub$name[valid_long]
          }
          if ("label_short" %in% names(sub)) {
            valid_short <- !is.na(sub$label_short) & nzchar(sub$label_short)
            if (any(valid_short)) {
              for (i in which(valid_short)) {
                al <- sub$label_short[i]; canon <- sub$name[i]
                if (!is.null(alias_map[[al]])) next
                alias_map[[al]] <<- canon
              }
            }
          }
        }
      }
    }

    # Try to get hierarchy data
    h1 <- try(hierarchy_to_table("carriers", include_groups = FALSE), silent = TRUE)
    if (!inherits(h1, "try-error")) safe_add(h1)
    h2 <- try(hierarchy_to_table("technologies", include_groups = FALSE), silent = TRUE)
    if (!inherits(h2, "try-error")) safe_add(h2)

    if (length(alias_map)) {
      hierarchy_aliases <- data.frame(
        alias = names(alias_map),
        canonical = unlist(alias_map, use.names = FALSE),
        stringsAsFactors = FALSE
      )
    }
  }

  remaining <- which(is.na(result$matched))

  if (length(remaining) > 0 && !is.null(hierarchy_aliases)) {
    for (i in remaining) {
      ali <- hierarchy_aliases$canonical[hierarchy_aliases$alias == sources[i]]
      if (length(ali) == 1) {
        result$matched[i] <- ali
        result$color[i] <- unname(palette[ali])
        result$method[i] <- "alias"
      }
    }
  }

  return(result)
}

# Advanced fuzzy matching with synonyms and string distance
.match_fuzzy <- function(sources, palette,
                         previous_result = NULL,
                         max_distance = 0.4, warn = TRUE) {
  if (is.null(previous_result)) {
    result <- data.frame(
      original = sources,
      matched = NA_character_,
      color = NA_character_,
      method = NA_character_,
      candidates = NA_character_,
      stringsAsFactors = FALSE
    )
  } else {
    result <- previous_result
  }

  # Build synonym map using default patterns
  energy_patterns <- .get_default_energy_patterns()

  # Create token reverse lookup
  token_reverse <- data.frame(
    token = character(0),
    canonical = character(0),
    stringsAsFactors = FALSE
  )

  for (canonical_name in names(energy_patterns)) {
    if (canonical_name %in% names(palette)) {
      tokens <- energy_patterns[[canonical_name]]
      token_df <- data.frame(
        token = tokens,
        canonical = rep(canonical_name, length(tokens)),
        stringsAsFactors = FALSE
      )
      token_reverse <- rbind(token_reverse, token_df)
    }
  }

  if (nrow(token_reverse) > 0) {
    token_reverse$token_canon <- .canonicalize(token_reverse$token)
  }

  remaining <- which(is.na(result$matched))
  canon_input <- .canonicalize(sources)

  for (i in remaining) {
    ci <- canon_input[i]
    cand_rows <- data.frame(token = character(0), canonical = character(0), stringsAsFactors = FALSE)

    # First try exact canonical token match
    if (nrow(token_reverse) > 0) {
      cand_rows <- token_reverse[token_reverse$token_canon == ci, ]
    }

    # If no exact token match, try fuzzy distance
    if (nrow(cand_rows) == 0 && nrow(token_reverse) > 0) {
      dists <- vapply(token_reverse$token_canon, .norm_dist, numeric(1), b = ci)
      min_d <- min(dists)
      if (!is.infinite(min_d) && min_d <= max_distance) {
        cand_rows <- token_reverse[dists <= min_d + 1e-8, ]
      }
    }

    if (nrow(cand_rows) == 0) {
      next
    }

    # Reduce to palette names still in palette
    cand_pal <- unique(cand_rows$canonical[cand_rows$canonical %in% names(palette)])

    if (length(cand_pal) == 1) {
      nm <- cand_pal
      result$matched[i] <- nm
      result$color[i] <- unname(palette[nm])
      result$method[i] <- "fuzzy"
    } else if (length(cand_pal) > 1) {
      # Disambiguate by computing distance to canonical names
      d_name <- vapply(cand_pal, .norm_dist, numeric(1), b = ci)
      best <- cand_pal[d_name == min(d_name)]
      if (length(best) == 1) {
        nm <- best
        result$matched[i] <- nm
        result$color[i] <- unname(palette[nm])
        result$method[i] <- "fuzzy_disambiguated"
      } else {
        # Ambiguous
        result$matched[i] <- best[1]
        result$color[i] <- unname(palette[best[1]])
        result$method[i] <- "fuzzy_ambiguous"
        result$candidates[i] <- paste(cand_pal, collapse = ";")
        if (warn) {
          warning(sprintf("Ambiguous energy source '%s' could match: %s (selected '%s')",
                         result$original[i], paste(cand_pal, collapse = ", "), best[1]), call. = FALSE)
        }
      }
    }
  }

  return(result)
}

# Regex pattern matching
.match_regex <- function(sources, palette, previous_result = NULL, regex_patterns = NULL, case_sensitive = FALSE) {
  if (is.null(previous_result)) {
    result <- data.frame(
      original = sources,
      matched = NA_character_,
      color = NA_character_,
      method = NA_character_,
      candidates = NA_character_,
      stringsAsFactors = FALSE
    )
  } else {
    result <- previous_result
  }

  # Use default patterns if none provided
  if (is.null(regex_patterns)) {
    regex_patterns <- .get_default_energy_patterns()
  }

  # Auto-generate patterns from palette names
  if (identical(regex_patterns, "auto")) {
    regex_patterns <- list()
    for (pal_name in names(palette)) {
      # Generate basic patterns from name
      clean_name <- gsub("[^a-zA-Z ]", "", pal_name)
      words <- unlist(strsplit(clean_name, "\\s+"))
      patterns <- c(
        tolower(pal_name),
        tolower(clean_name),
        paste(tolower(words), collapse = ".?"),
        tolower(words)
      )
      regex_patterns[[pal_name]] <- unique(patterns[nzchar(patterns)])
    }
  }

  remaining <- which(is.na(result$matched))
  search_sources <- if (case_sensitive) sources else tolower(sources)

  for (i in remaining) {
    current_source <- search_sources[i]
    if (is.na(current_source) || current_source == "") next

    matched_patterns <- character(0)

    for (pal_name in names(regex_patterns)) {
      if (pal_name %in% names(palette)) {
        patterns <- regex_patterns[[pal_name]]
        for (pattern in patterns) {
          if (grepl(pattern, current_source, perl = TRUE, ignore.case = !case_sensitive)) {
            matched_patterns <- c(matched_patterns, pal_name)
            break
          }
        }
      }
    }

    if (length(matched_patterns) == 1) {
      result$matched[i] <- matched_patterns[1]
      result$color[i] <- unname(palette[matched_patterns[1]])
      result$method[i] <- "regex"
    } else if (length(matched_patterns) > 1) {
      # Take first match but record ambiguity
      result$matched[i] <- matched_patterns[1]
      result$color[i] <- unname(palette[matched_patterns[1]])
      result$method[i] <- "regex_ambiguous"
      result$candidates[i] <- paste(matched_patterns, collapse = ";")
    }
  }

  return(result)
}

# Legacy helper function for exact matching (backward compatibility)
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

# ============================================================================ #
# UNIFIED MATCHING ENGINE
# ============================================================================ #

#' Unified Energy Source Matching Engine (Version 2)
#'
#' Advanced multi-stage matching system that combines all matching algorithms
#' in a flexible, configurable way.
#'
#' @param sources Character vector of energy source names to match
#' @param palette Named character vector of colors (palette)
#' @param methods Character vector of methods to apply in order. Options:
#'   "exact", "canonical", "alias", "fuzzy", "regex", or "auto" (default)
#' @param case_sensitive Logical, whether matching should be case sensitive (default: FALSE)
#' @param max_distance Maximum normalized distance for fuzzy matching (default: 0.4)
#' @param regex_patterns List of regex patterns or "auto" to generate from palette names
#' @param warn Logical, emit warnings for ambiguous matches (default: TRUE)
#' @param include_full_palette Logical, include unmatched palette entries (default: FALSE)
#'
#' @return data.frame with columns: original, matched, color, method, candidates
#' @export
match_energy_sources_v2 <- function(sources,
                                    palette = "carriers",
                                    methods = "auto",
                                    case_sensitive = FALSE,
                                    max_distance = 0.4,
                                    regex_patterns = NULL,
                                    warn = TRUE,
                                    include_full_palette = FALSE) {
  # browser()

  # Validate inputs
  stopifnot(is.character(sources))
  # stopifnot(is.character(palette) && !is.null(names(palette)))

  # Get unique sources for processing
  src_unique <- unique(sources)

  # Define method sequence
  if (identical(methods, "auto")) {
    methods <- c("exact", "canonical", "alias", "fuzzy", "regex")
  }

  # Initialize result
  result <- NULL

  # Apply methods in sequence
  for (method in methods) {
    if (method == "exact") {
      result <- .match_exact(src_unique, palette, case_sensitive)
    } else if (method == "canonical") {
      result <- .match_canonical(src_unique, palette, result)
    } else if (method == "alias") {
      result <- .match_alias(src_unique, palette, result)
    } else if (method == "fuzzy") {
      result <- .match_fuzzy(src_unique, palette, result, max_distance, warn)
    } else if (method == "regex") {
      result <- .match_regex(src_unique, palette, result, regex_patterns, case_sensitive)
    } else {
      warning("Unknown method: ", method, ". Skipping.")
    }
  }

  # Add unmatched palette entries if requested
  if (include_full_palette) {
    missing_pal <- setdiff(names(palette), result$matched)
    if (length(missing_pal) > 0) {
      add <- data.frame(
        original = rep(NA_character_, length(missing_pal)),
        matched = missing_pal,
        color = unname(palette[missing_pal]),
        method = "palette_fill",
        candidates = NA_character_,
        stringsAsFactors = FALSE
      )
      result <- rbind(result, add)
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

  # Use the new unified regex matching system
  energy_patterns <- .get_default_energy_patterns()

  for (i in subset_idx) {
    current_source <- search_sources[i]
    if (is.na(current_source) || current_source == "") next

    for (pal_name in names(energy_patterns)) {
      if (pal_name %in% search_names) {
        patterns <- energy_patterns[[pal_name]]
        if (any(sapply(patterns, function(p) grepl(p, current_source, perl = TRUE, ignore.case = TRUE)))) {
          pal_idx <- which(search_names == pal_name)[1]
          result[i] <- palette[pal_idx]
          break
        }
      }
    }
  }
  return(result)
}

# # Legacy helper functions for color variations (commented out)
# .apply_color_variations <- function(result, sources, variation_type, variation_intensity) {
# .check_duplicate_mappings <- function(result, sources) {
# ...




