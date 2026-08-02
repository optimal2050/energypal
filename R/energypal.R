## Hierarchical Energy Palette Utilities
#
# Provides functions to load and flatten the hierarchical energy palettes
# defined in inst/extdata/hierarchical_energy_palettes.yml
#
# Exposed functions:
# - load_energy_palettes(): raw list structure (cached)
# - hierarchy_to_table(): flattened data.frame with one row per node
#
# Flattened table columns:
#   name          : canonical identifier for the node (from YAML key)
#   level         : integer depth (1 = top group e.g. Fossil, 2 = carrier, 3 = subtype)
#   parent        : parent node name (NA for level 1)
#   color         : hex color for this node (may be NA if missing)
#   type          : one of group|carrier|subtype
#   path          : full path concatenated by '>'
#   branch        : top-level group name (replicated for convenience)
#   label_short   : optional short display label (_short in YAML)
#   label_long    : optional long display label (_long in YAML)
#   label_default : preferred display label (long if present, else short, else name)
#
# The YAML also contains a 'technologies' tree which can be flattened later
# (currently we focus on carriers; function allows selecting section).

#' Load hierarchical energy palette specification
#'
#' Reads and caches the hierarchical palette YAML (carriers + technologies).
#' @param force Logical; if TRUE re-read file even if cached
#' @return list representing YAML structure
#' @export
load_energy_palettes <- function(force = FALSE) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required to load hierarchical palettes. Please install it.")
  }
  # Choose cache environment: package namespace if loaded, else a local top-level env
  cache_env <- if ("energypal" %in% loadedNamespaces()) {
    # Use an internal environment stored in options to avoid locked namespace binding issue
    opt_env <- getOption("energypal.cache_env")
    if (is.null(opt_env) || !is.environment(opt_env)) {
      opt_env <- new.env(parent = emptyenv())
      options(energypal.cache_env = opt_env)
    }
    opt_env
  } else {
    if (!exists(".energypal_dev_cache", envir = .GlobalEnv)) {
      assign(".energypal_dev_cache", new.env(parent = emptyenv()), envir = .GlobalEnv)
    }
    get(".energypal_dev_cache", envir = .GlobalEnv)
  }
  if (!force && exists(".hierarchy_cache", envir = cache_env, inherits = FALSE)) {
    return(get(".hierarchy_cache", envir = cache_env, inherits = FALSE))
  }
  fname <- system.file("extdata", "hierarchical_energy_palettes.yml", package = "energypal")
  if (!nzchar(fname) || !file.exists(fname)) {
    # Development fallback: look relative to project root
    alt <- file.path(getwd(), "inst", "extdata", "hierarchical_energy_palettes.yml")
    if (file.exists(alt)) fname <- alt else stop("hierarchical_energy_palettes.yml not found (checked installed system.file and inst/extdata in working directory)")
  }
  y <- yaml::read_yaml(fname)
  assign(".hierarchy_cache", y, envir = cache_env)
  y
}

## Internal recursive walker (re-written to correctly traverse nested structures)
.walk_hierarchy <- function(x,
                            level = 1L,
                            parent = NA_character_,
                            path_prefix = NULL,
                            top_group = NA_character_,
                            section = c("carriers", "technologies"),
                            rows = list()) {
  section <- match.arg(section)
  for (nm in names(x)) {
    node <- x[[nm]]
    if (is.null(node) || !is.list(node)) next
    # Distinguish a structural node vs a leaf container (subtypes stored under $subtypes)
    color <- if (!is.null(node$`_color`)) node$`_color` else NA_character_
    has_subtypes <- !is.null(node$subtypes) && is.list(node$subtypes) && length(node$subtypes) > 0
    # Determine type classification heuristically
    type <- if (level == 1L) {
      # Top-level branch label (e.g. FossilFuels, ElectricPower, Industry)
      "group"
    } else if (has_subtypes) {
      "carrier"
    } else {
      # Could still be a carrier/technology without explicit subtypes
      "carrier"
    }
    current_path <- if (is.null(path_prefix)) nm else paste0(path_prefix, ">", nm)
    branch <- if (level == 1L) nm else top_group
    rows[[length(rows) + 1]] <- data.frame(
      name = nm,
      level = level,
      parent = parent,
      color = color,
      type = type,
      path = current_path,
      branch = branch,
      label_short = if (!is.null(node$`_short`)) node$`_short` else NA_character_,
      label_long = if (!is.null(node$`_long`)) node$`_long` else NA_character_,
      stringsAsFactors = FALSE
    )
    # Append subtypes
    if (has_subtypes) {
      for (sn in names(node$subtypes)) {
        scol <- node$subtypes[[sn]]
        rows[[length(rows) + 1]] <- data.frame(
          name = sn,
          level = level + 1L,
          parent = nm,
          color = if (is.character(scol)) scol else NA_character_,
          type = "subtype",
          path = paste0(current_path, ">", sn),
          branch = branch,
          label_short = NA_character_,
          label_long = NA_character_,
          stringsAsFactors = FALSE
        )
      }
    }
    # Recurse into nested structural children (exclude known keys)
    child_names <- setdiff(names(node), c("_color", "subtypes"))
    if (length(child_names) > 0) {
      rows <- .walk_hierarchy(
        x = node[child_names],
        level = level + 1L,
        parent = nm,
        path_prefix = current_path,
        top_group = if (level == 1L) nm else top_group,
        section = section,
        rows = rows
      )
    }
  }
  rows
}

#' Flatten hierarchical energy palette into a table
#'
#' @param section Which top-level branch to flatten: 'carriers' or 'technologies'
#' @param include_groups Logical; include the top-level group rows (default TRUE)
#' @return data.frame
#' @export
hierarchy_to_table <- function(section = c("carriers", "technologies"),
                               include_groups = TRUE) {
  section <- match.arg(section)
  h <- load_energy_palettes()
  if (is.null(h[[section]])) stop("Section '", section, "' not found in hierarchy YAML")
  rows <- .walk_hierarchy(h[[section]], level = 1L, parent = NA_character_, top_group = NA_character_, section = section)
  df <- do.call(rbind, rows)
  # Provide label_default preference (long > short > name)
  df$label_default <- ifelse(!is.na(df$label_long) & nzchar(df$label_long),
    df$label_long,
    ifelse(!is.na(df$label_short) & nzchar(df$label_short), df$label_short, df$name)
  )
  if (!include_groups) df <- df[df$type != "group", , drop = FALSE]
  rownames(df) <- NULL
  df$section <- section
  df
}

#' Get carrier color vector from hierarchy
#' @param include_subtypes logical include subtype colors too
#' @return named character vector
#' @export
hierarchy_carrier_palette <- function(include_subtypes = FALSE) {
  tab <- hierarchy_to_table("carriers", include_groups = FALSE)
  carriers <- tab[tab$type == "carrier", c("name", "color")]
  res <- carriers$color
  names(res) <- carriers$name
  if (include_subtypes) {
    st <- tab[tab$type == "subtype", c("name", "color")]
    stv <- st$color
    names(stv) <- st$name
    res <- c(res, stv)
  }
  res[!is.na(res)]
}

#' Energy palette by name
#'
#' Returns a named vector of colors for either the carriers or technologies
#' section of the hierarchy. Provides flexible control over inclusion of
#' group rows, carrier rows, and subtype rows, along with selection of which
#' label should be used for the names of the returned vector.
#'
#' @param section One of 'carriers' or 'technologies'.
#' @param include_groups Logical; include top-level group nodes (default FALSE for plotting palettes).
#' @param include_carriers Logical; include carrier / technology nodes (default TRUE).
#' @param include_subtypes Logical; include subtype nodes (default TRUE).
#' @param label_style One of 'id','short','long','default' determining the naming of the returned vector.
#'   id = internal canonical name; short/long = corresponding hierarchy labels if present;
#'   default = hierarchy label_default column (long > short > id).
#' @param drop_na_colors Logical; drop rows without a defined color (default TRUE).
#' @param unique_names Logical; ensure returned names are unique (deduplicate by appending numeric suffix) (default TRUE).
#'
#' @return Named character vector of hex colors (possibly zero length if none match filters).
#' @export
energypal <- function(section = c("carriers", "technologies"),
                      include_groups = TRUE,
                      include_carriers = TRUE,
                      include_subtypes = TRUE,
                      label_style = c("id", "short", "long", "default", "legacy"),
                      drop_na_colors = TRUE,
                      unique_names = TRUE) {
  section <- match.arg(section)
  label_style <- match.arg(label_style)
  tab <- hierarchy_to_table(section = section, include_groups = TRUE)
  # Filter by type flags
  keep <- rep(FALSE, nrow(tab))
  if (include_groups) keep <- keep | tab$type == "group"
  if (include_carriers) keep <- keep | tab$type == "carrier"
  if (include_subtypes) keep <- keep | tab$type == "subtype"
  tab <- tab[keep, , drop = FALSE]
  if (nrow(tab) == 0) {
    return(setNames(character(0), character(0)))
  }
  if (drop_na_colors) tab <- tab[!is.na(tab$color) & nzchar(tab$color), , drop = FALSE]
  if (nrow(tab) == 0) {
    return(setNames(character(0), character(0)))
  }
  name_col <- switch(label_style,
    id = tab$name,
    short = ifelse(!is.na(tab$label_short) & nzchar(tab$label_short), tab$label_short, tab$name),
    long = ifelse(!is.na(tab$label_long) & nzchar(tab$label_long), tab$label_long, tab$name),
    default = tab$label_default,
    legacy = .legacy_carrier_name(tab$name, tab$label_short, tab$label_long)
  )
  # Ensure uniqueness if requested
  if (unique_names) {
    if (any(duplicated(name_col))) {
      dupes <- which(duplicated(name_col) | duplicated(name_col, fromLast = TRUE))
      counts <- ave(seq_along(name_col), name_col, FUN = seq_along)
      name_col[dupes] <- paste0(name_col[dupes], "_", counts[dupes])
    }
  }
  res <- tab$color
  names(res) <- name_col
  res
}

## Future: synonyms could optionally be loaded from YAML if added under a 'synonyms' key.

# Internal: map internal carrier IDs to simplified legacy names for backward compatibility
.legacy_carrier_name <- function(ids, short, long) {
  # Start with default preference (long > short > id)
  base <- ifelse(!is.na(long) & nzchar(long), long, ifelse(!is.na(short) & nzchar(short), short, ids))
  # Pattern replacements for known fossil group prefixes
  base <- gsub("^FossilCoal$", "Coal", base)
  base <- gsub("^OtherFossilCoal$", "Coal", base)
  base <- gsub("^FossilOil$", "Oil", base)
  base <- gsub("^OtherFossilOil$", "Oil", base)
  base <- gsub("^FossilGas$", "Natural Gas", base)
  base <- gsub("^OtherFossilGas$", "Natural Gas", base)
  base
}

if (F) {
  #
}
