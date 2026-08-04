## Palette flattening and colour extraction
#
# A palette specification (see R/palettes.R) is a tree of nodes. This file turns
# that tree into a flat table, and the table into a named colour vector.
#
# Node grammar:
#   Name: "#RRGGBB"                  a bare colour
#   Name:                            a map
#     _color:   "#RRGGBB"
#     _short:   short display label
#     _long:    long display label
#     _aliases: [alternative, labels, ...]
#     subtypes: {Child: "#RRGGBB"}   leaf children
#     Child: {...}                   nested children
#
# Flattened columns:
#   name          canonical identifier (the YAML key)
#   level         1 = top level, increasing with depth
#   parent        parent's name, NA at level 1
#   color         hex colour, NA if the node defines none
#   type          group | carrier | subtype
#   path          full path joined by '>'
#   branch        top-level ancestor, for convenience
#   label_short   from _short
#   label_long    from _long
#   label_default long if present, else short, else name
#   aliases       alternative labels, ';'-separated, NA if none
#   palette       the palette this row came from

# Keys with a defined meaning. Any *other* `_`-prefixed key is a user-defined
# property (`_carbon_intensity`) and becomes a column in the flattened table.
.label_keys <- c("_color", "_short", "_long", "_aliases")

.is_prop_key <- function(k) startsWith(k, "_") & !(k %in% .label_keys)
                         
                         .walk_nodes <- function(x,
                         level = 1L,
                         parent = NA_character_,
                         path_prefix = NULL,
                         top_group = NA_character_,
                         rows = list()) {
  for (nm in names(x)) {
    node <- x[[nm]]
    if (is.null(node)) next

    # A bare colour string is a leaf node
    if (is.character(node) && length(node) == 1L) {
      current_path <- if (is.null(path_prefix)) nm else paste0(path_prefix, ">", nm)
      rows[[length(rows) + 1L]] <- .node_row(
        name = nm, level = level, parent = parent, color = node,
        type = "carrier", path = current_path,
        branch = if (level == 1L) nm else top_group
      )
      next
    }
    if (!is.list(node)) next

    keys <- names(node)
    color <- if (!is.null(node$`_color`)) as.character(node$`_color`)[1] else NA_character_
    subtypes <- node$subtypes
    has_subtypes <- is.list(subtypes) && length(subtypes) > 0L
    child_names <- setdiff(keys[!startsWith(keys, "_")], "subtypes")
    has_children <- length(child_names) > 0L
    prop_keys <- keys[.is_prop_key(keys)]

    # Level 1 is a group only if it actually contains children. A flat palette's
    # top-level entries are ordinary carriers, not groups.
    type <- if (level == 1L && has_children) "group" else "carrier"

    current_path <- if (is.null(path_prefix)) nm else paste0(path_prefix, ">", nm)
    branch <- if (level == 1L) nm else top_group

    rows[[length(rows) + 1L]] <- .node_row(
      name = nm, level = level, parent = parent, color = color,
      type = type, path = current_path, branch = branch,
      label_short = if (!is.null(node$`_short`)) as.character(node$`_short`)[1] else NA_character_,
      label_long  = if (!is.null(node$`_long`))  as.character(node$`_long`)[1]  else NA_character_,
      aliases     = if (!is.null(node$`_aliases`)) paste(unlist(node$`_aliases`), collapse = ";") else NA_character_,
      props       = stats::setNames(lapply(prop_keys, function(k) node[[k]]),
                                    sub("^_", "", prop_keys))
    )

    if (has_subtypes) {
      for (sn in names(subtypes)) {
        scol <- subtypes[[sn]]
        rows[[length(rows) + 1L]] <- .node_row(
          name = sn, level = level + 1L, parent = nm,
          color = if (is.character(scol)) scol[1] else NA_character_,
          type = "subtype", path = paste0(current_path, ">", sn), branch = branch
        )
      }
    }

    if (has_children) {
      rows <- .walk_nodes(
        x = node[child_names],
        level = level + 1L,
        parent = nm,
        path_prefix = current_path,
        top_group = if (level == 1L) nm else top_group,
        rows = rows
      )
    }
  }
  rows
}

# A row is a plain list rather than a one-row data frame, so that rows carrying
# different properties can still be assembled into one table.
.node_row <- function(name, level, parent, color, type, path, branch,
                      label_short = NA_character_, label_long = NA_character_,
                      aliases = NA_character_, props = list()) {
  list(
    name = name, level = as.integer(level), parent = parent, color = color,
    type = type, path = path, branch = branch,
    label_short = label_short, label_long = label_long, aliases = aliases,
    .props = props
  )
}

.base_cols <- c("name", "level", "parent", "color", "type", "path", "branch",
                "label_short", "label_long", "aliases")

# Flatten an already-loaded specification.
.palette_table <- function(spec, palette_name = NA_character_) {
  if (is.null(spec$colors) || !length(spec$colors)) {
    stop("palette has no `colors:` block", call. = FALSE)
  }
  rows <- .walk_nodes(spec$colors)

  df <- data.frame(
    lapply(stats::setNames(.base_cols, .base_cols), function(k) {
      v <- vapply(rows, function(r) {
        x <- r[[k]]
        if (is.null(x) || !length(x)) NA else x[1]
      }, if (k == "level") integer(1) else character(1))
      v
    }),
    stringsAsFactors = FALSE
  )

  # Property columns: the union across rows, each carrying its provenance from
  # the palette's `properties:` block so the caveat travels with the values.
  prop_names <- unique(unlist(lapply(rows, function(r) names(r$.props))))
  for (p in prop_names) {
    vals <- lapply(rows, function(r) r$.props[[p]])
    col <- vapply(vals, function(v) if (is.null(v) || !length(v)) NA_real_ else
      suppressWarnings(as.numeric(v[1])), numeric(1))
    # keep character properties as character rather than coercing to NA
    if (all(is.na(col)) && any(!vapply(vals, is.null, logical(1)))) {
      col <- vapply(vals, function(v) if (is.null(v) || !length(v)) NA_character_ else
        as.character(v[1]), character(1))
    }
    meta <- spec$properties[[p]]
    if (!is.null(meta)) {
      attr(col, "note") <- .chr1(meta$`_note`)
      attr(col, "source") <- .chr1(meta$`_source`)
      attr(col, "url") <- .chr1(meta$`_url`)
      attr(col, "unit") <- .chr1(meta$`_unit`)
    }
    df[[p]] <- col
  }

  df$label_default <- ifelse(
    !is.na(df$label_long) & nzchar(df$label_long), df$label_long,
    ifelse(!is.na(df$label_short) & nzchar(df$label_short), df$label_short, df$name)
  )
  df$palette <- palette_name
  rownames(df) <- NULL
  df
}

#' Flatten a palette into a table
#'
#' Returns one row per palette entry, with its colour, position in the
#' hierarchy, display labels and aliases. This is the form the matcher and the
#' scale functions work from, and the most convenient way to inspect a palette.
#'
#' @param palette Name of a built-in or registered palette. Defaults to the
#'   `energypal.palette` option, or `"carriers"`. See [energypal_info()].
#' @param file Path to a palette file, taking precedence over `palette`.
#' @param include_groups Logical; include the aggregate group rows (default `TRUE`).
#' @param order How to sequence the rows. `NULL` or `"spec"` keeps file order;
#'   otherwise the name of an ordering declared in the palette, the name of a
#'   numeric property (sorted descending), one of the computed orderings
#'   `"alpha"`, `"hue"`, `"lightness"`, `"chroma"`, or an explicit character
#'   vector of entry names. See [energypal_orders()].
#'
#'   **Presentation only** — orderings arrange visuals and are not model inputs.
#' @param direction `1` (default) or `-1` to reverse the chosen order.
#' @return A data frame with columns `name`, `level`, `parent`, `color`, `type`,
#'   `path`, `branch`, `label_short`, `label_long`, `aliases`, `label_default`
#'   and `palette`, plus one column per numeric property the palette declares.
#'   Property columns carry their `note`, `source`, `url` and `unit` as
#'   attributes.
#' @examples
#' tab <- energypal_table("carriers")
#' head(tab[, c("name", "level", "type", "color", "label_default")])
#'
#' # Only the carrier-level rows
#' nrow(energypal_table("carriers", include_groups = FALSE))
#'
#' # Declared properties become columns, and carry their caveat with them
#' tab <- energypal_table("carriers", include_groups = FALSE)
#' attr(tab$carbon_intensity, "note")
#' attr(tab$carbon_intensity, "unit")
#' @seealso [energypal()] for a colour vector, [energypal_orders()] for the
#'   available orderings, [energypal_info()] for the palette list.
#' @export
energypal_table <- function(palette = NULL, file = NULL, include_groups = TRUE,
                            order = NULL, direction = 1) {
  path <- .palette_file(palette, file)
  nm <- if (!is.null(file)) sub("\\.yml$", "", basename(path)) else (palette %||% "carriers")
  spec <- energypal_spec(palette = palette, file = file)

  if (.palette_type(spec) == "continuous") {
    stops <- .palette_stops(spec)
    brk <- as.numeric(unlist(spec$breaks))
    df <- data.frame(
      position = seq_along(stops),
      color = stops,
      break_min = if (length(brk)) c(NA_real_, brk)[seq_along(stops)] else NA_real_,
      break_max = if (length(brk)) c(brk, NA_real_)[seq_along(stops)] else NA_real_,
      type = "stop",
      palette = nm,
      stringsAsFactors = FALSE
    )
    if (identical(as.numeric(direction), -1)) df <- df[rev(seq_len(nrow(df))), , drop = FALSE]
    rownames(df) <- NULL
    return(df)
  }

  df <- .palette_table(spec, nm)
  # Capture before any subsetting: `[.data.frame` drops column attributes, and
  # the property columns carry their provenance there.
  keep <- .capture_col_attrs(df)
  if (!include_groups) df <- df[df$type != "group", , drop = FALSE]
  # Order after filtering, so a declared sequence is not skewed by dropped rows
  df <- df[.resolve_order(df, order, spec, direction), , drop = FALSE]
  df <- .restore_col_attrs(df, keep)
  rownames(df) <- NULL
  df
}

.prov_attrs <- c("note", "source", "url", "unit")

.capture_col_attrs <- function(df) {
  lapply(df, function(col) attributes(col)[.prov_attrs])
}

.restore_col_attrs <- function(df, keep) {
  for (nm in intersect(names(df), names(keep))) {
    a <- keep[[nm]]
    for (k in names(a)) if (!is.null(a[[k]])) attr(df[[nm]], k) <- a[[k]]
  }
  df
}

#' Energy colour palette
#'
#' Returns a named vector of colours from a palette, in the style of
#' `RColorBrewer::brewer.pal()`. The first argument selects the palette by name;
#' `energypal_info()` lists what is available.
#'
#' By default you get the palette's main level only — the carriers or
#' technologies themselves, 17 of them for `"carriers"`. The aggregate groups
#' above them (`FossilFuels`, `Renewable`) and the subtypes below
#' (`Anthracite`, `Lignite`) are available through `include_groups` and
#' `include_subtypes`, but are off by default because a plotting palette wants
#' distinct colours, and adjacent subtypes are deliberately near-identical.
#'
#' Palettes are plain YAML files, so a project can supply its own via `file =`
#' or [energypal_register()] and use it everywhere a built-in name works.
#'
#' @param palette Name of a built-in or registered palette. Defaults to the
#'   `energypal.palette` option, or `"carriers"`.
#' @param n Number of colours to return. `NULL` (default) returns all of them;
#'   otherwise the first `n`, and it is an error to ask for more than the
#'   palette holds.
#' @param file Path to a palette file, taking precedence over `palette`.
#' @param include_groups Logical; include aggregate group entries such as
#'   `FossilFuels` (default `FALSE`).
#' @param include_carriers Logical; include carrier or technology entries — the
#'   main level of the palette (default `TRUE`).
#' @param include_subtypes Logical; include subtype entries such as `Anthracite`
#'   (default `FALSE`).
#' @param order How to sequence the colours. `NULL` or `"spec"` keeps file
#'   order; otherwise the name of an ordering declared in the palette
#'   (`"carbon_intensity"`, `"dispatchability"`, `"merit_order"`,
#'   `"renewability"`), the name of a numeric property (sorted descending), one
#'   of the computed orderings `"alpha"`, `"hue"`, `"lightness"`, `"chroma"`, or
#'   an explicit character vector of entry names. See [energypal_orders()].
#'
#'   **Presentation only.** Orderings, and the numeric properties behind them,
#'   exist to arrange legends and chart series. They are indicative values, not
#'   validated figures, and must not be used in calculations.
#' @param direction `1` (default) or `-1` to reverse the chosen order.
#' @param label_style How to name the returned vector: `"id"` (canonical
#'   identifier, the default), `"short"`, `"long"`, or `"default"`
#'   (long if present, else short, else id).
#' @param drop_na_colors Logical; drop entries with no colour (default `TRUE`).
#' @param unique_names Logical; make the returned names unique by appending a
#'   numeric suffix to duplicates (default `TRUE`).
#'
#' @return A named character vector of hex colours.
#' @examples
#' # The default carrier palette: 17 colours, one per carrier
#' energypal()
#'
#' # A published report's colours, same identifiers
#' energypal("ipcc")
#'
#' # Brewer-style: just the first few
#' energypal("eia", n = 5)
#'
#' # Readable names for legends
#' energypal("carriers", label_style = "long")
#'
#' # The full hierarchy, groups and fuel subtypes included
#' length(energypal("carriers", include_groups = TRUE, include_subtypes = TRUE))
#'
#' # What is available
#' energypal_info()$name
#' @seealso [energypal_info()] to list the available palettes,
#'   [energypal_table()] for the underlying table, and [energypal_colors()] to
#'   map data labels to colours.
#' @export
energypal <- function(palette = NULL,
                      n = NULL,
                      file = NULL,
                      order = NULL,
                      direction = 1,
                      include_groups = FALSE,
                      include_carriers = TRUE,
                      include_subtypes = FALSE,
                      label_style = c("id", "short", "long", "default"),
                      drop_na_colors = TRUE,
                      unique_names = TRUE) {
  label_style <- match.arg(label_style)
  spec <- energypal_spec(palette = palette, file = file)

  # A continuous palette is a ramp, not a set of named entries: `n` interpolates
  # along it rather than taking a head, and the result is unnamed, as with
  # viridis(n) or colorRampPalette()(n).
  if (.palette_type(spec) == "continuous") {
    stops <- .palette_stops(spec)
    if (identical(as.numeric(direction), -1)) stops <- rev(stops)
    if (is.null(n)) return(stops)
    if (!is.numeric(n) || length(n) != 1L || n < 1) {
      stop("`n` must be a single positive number.", call. = FALSE)
    }
    return(grDevices::colorRampPalette(stops)(n))
  }

  tab <- energypal_table(palette = palette, file = file, include_groups = TRUE)

  keep <- rep(FALSE, nrow(tab))
  if (include_groups) keep <- keep | tab$type == "group"
  if (include_carriers) keep <- keep | tab$type == "carrier"
  if (include_subtypes) keep <- keep | tab$type == "subtype"
  tab <- tab[keep, , drop = FALSE]

  if (drop_na_colors) tab <- tab[!is.na(tab$color) & nzchar(tab$color), , drop = FALSE]
  if (nrow(tab) == 0L) return(stats::setNames(character(0), character(0)))

  # Order after filtering: a declared sequence should not be skewed by rows the
  # include_ flags removed.
  tab <- tab[.resolve_order(tab, order, spec, direction), , drop = FALSE]

  name_col <- switch(label_style,
    id = tab$name,
    short = ifelse(!is.na(tab$label_short) & nzchar(tab$label_short), tab$label_short, tab$name),
    long = ifelse(!is.na(tab$label_long) & nzchar(tab$label_long), tab$label_long, tab$name),
    default = tab$label_default
  )

  if (unique_names && anyDuplicated(name_col)) {
    dupes <- which(duplicated(name_col) | duplicated(name_col, fromLast = TRUE))
    counts <- stats::ave(seq_along(name_col), name_col, FUN = seq_along)
    name_col[dupes] <- paste0(name_col[dupes], "_", counts[dupes])
  }

  res <- stats::setNames(tab$color, name_col)

  if (!is.null(n)) {
    if (!is.numeric(n) || length(n) != 1L || n < 1) {
      stop("`n` must be a single positive number.", call. = FALSE)
    }
    if (n > length(res)) {
      stop("palette has ", length(res), " colours; `n = ", n, "` is too many.", call. = FALSE)
    }
    res <- res[seq_len(n)]
  }
  res
}
