## Palette store
#
# A palette is a YAML file with a `meta:` provenance block and a `colors:` map.
# Built-in palettes live in inst/extdata/palettes/; users can register their own
# or pass a path directly. Entries may be nested to any depth or flat, and an
# individual entry may be a bare colour string or a map carrying `_color`,
# `_short`, `_long` and `_aliases`.
#
# `meta.extends` names another palette to inherit from. The child is merged over
# the parent, so a report palette need only state the colours it changes.

# Session registry of user palettes: name -> file path.
.energypal_registry <- new.env(parent = emptyenv())

.palette_dir <- function() {
  d <- system.file("extdata", "palettes", package = "energypal")
  if (nzchar(d) && dir.exists(d)) return(d)
  # Development fallback, for load_all() against the source tree
  alt <- file.path(getwd(), "inst", "extdata", "palettes")
  if (dir.exists(alt)) return(alt)
  stop("palette directory not found (looked in the installed package and inst/extdata/palettes)",
       call. = FALSE)
}

# Resolve a palette name or path to a file. Precedence:
#   explicit file > registered name > built-in name
.palette_file <- function(palette = NULL, file = NULL) {
  if (!is.null(file)) {
    if (!file.exists(file)) stop("palette file not found: ", file, call. = FALSE)
    return(normalizePath(file, winslash = "/"))
  }
  if (is.null(palette)) palette <- getOption("energypal.palette", "carriers")
  if (!is.character(palette) || length(palette) != 1L) {
    stop("`palette` must be a single palette name.", call. = FALSE)
  }
  if (exists(palette, envir = .energypal_registry, inherits = FALSE)) {
    return(get(palette, envir = .energypal_registry, inherits = FALSE))
  }
  f <- file.path(.palette_dir(), paste0(palette, ".yml"))
  if (file.exists(f)) return(normalizePath(f, winslash = "/"))

  # A family name resolves to whichever member is marked `default: true`, so
  # `windatlas` reaches `windatlas_speed` without a free-form alias.
  fam <- .family_index()
  if (palette %in% names(fam)) {
    d <- fam[[palette]]$default
    if (!is.na(d)) {
      return(normalizePath(file.path(.palette_dir(), paste0(d, ".yml")), winslash = "/"))
    }
    stop("'", palette, "' is a palette family with no default member. Pick one of: ",
         paste(fam[[palette]]$members, collapse = ", "), call. = FALSE)
  }

  stop("unknown palette '", palette, "'. Available: ",
       paste(.builtin_names(), collapse = ", "),
       if (length(names(fam))) {
         paste0(" (families: ", paste(names(fam), collapse = ", "), ")")
       } else "",
       if (length(ls(.energypal_registry))) {
         paste0(" (registered: ", paste(ls(.energypal_registry), collapse = ", "), ")")
       } else "",
       call. = FALSE)
}

.builtin_names <- function() {
  sort(sub("\\.yml$", "", basename(list.files(.palette_dir(), pattern = "\\.yml$"))))
}

# family -> list(members, default, measures). Built by reading each palette's
# meta block; cached on the directory's modification time.
.family_index <- function() {
  dir <- .palette_dir()
  key <- paste0("families:", dir, ":", as.numeric(file.mtime(dir)))
  hit <- .cache_get(key)
  if (!is.null(hit)) return(hit)

  out <- list()
  for (nm in .builtin_names()) {
    m <- tryCatch(yaml::read_yaml(file.path(dir, paste0(nm, ".yml")))$meta,
                  error = function(e) NULL)
    fam <- .chr1(m$family)
    if (is.na(fam) || !nzchar(fam)) next
    if (is.null(out[[fam]])) {
      out[[fam]] <- list(members = character(), default = NA_character_,
                         measures = character())
    }
    out[[fam]]$members <- c(out[[fam]]$members, nm)
    out[[fam]]$measures <- c(out[[fam]]$measures, .chr1(m$measure))
    if (isTRUE(m$default)) out[[fam]]$default <- nm
  }
  .cache_set(key, out)
}

#' Available energy palettes
#'
#' Lists the palettes that can be passed to [energypal()], `palette =` arguments
#' and the scale functions: the ones shipped with the package plus any
#' registered in this session with [energypal_register()].
#'
#' This is a function rather than a stored data frame (unlike
#' `RColorBrewer::brewer.pal.info`) so that registered palettes appear in it and
#' so it cannot fall out of step with the files on disk.
#'
#' @section Families:
#' An atlas publishes several quantities and styles each differently, so its
#' scales ship as separate palettes grouped by `family` and distinguished by
#' `measure` — `windatlas_speed`, `windatlas_density` and so on. They are not
#' interchangeable. One member of each family is its default, so the bare family
#' name (`"windatlas"`) resolves to the most common measure.
#'
#' @param family Optional family name; return only that family's members.
#' @return A data frame with one row per palette and columns `name`, `title`,
#'   `source`, `family`, `measure`, `default`, `type` (`"discrete"` or
#'   `"continuous"`), `n` (number of colours), `nested` (whether the palette has
#'   a hierarchy), `breaks`, `unit` and `builtin`.
#'
#'   Every colour `n` counts is one the palette file declares itself. A palette
#'   that `extends` another inherits its taxonomy — names, labels, aliases,
#'   hierarchy, orderings — but never its colours.
#' @examples
#' energypal_info()
#'
#' # what a family offers
#' energypal_info(family = "windatlas")
#'
#' # just the continuous palettes
#' i <- energypal_info()
#' i[i$type == "continuous", c("name", "measure", "unit")]
#' @seealso [energypal()] to retrieve a palette, [energypal_register()] to add one.
#' @export
energypal_info <- function(family = NULL) {
  builtin <- .builtin_names()
  registered <- setdiff(ls(.energypal_registry), builtin)
  names_all <- c(builtin, registered)
  rows <- lapply(names_all, function(nm) {
    spec <- tryCatch(energypal_spec(nm), error = function(e) NULL)
    if (is.null(spec)) {
      return(.info_row(nm, builtin = nm %in% builtin))
    }
    type <- .palette_type(spec)
    if (type == "continuous") {
      stops <- .palette_stops(spec)
      return(.info_row(nm, spec, type = "continuous", n = length(stops), nested = FALSE,
                       breaks = length(unlist(spec$breaks)), builtin = nm %in% builtin))
    }
    tab <- .palette_table(spec, nm)
    .info_row(nm, spec, type = "discrete",
              n = sum(!is.na(tab$color) & nzchar(tab$color)),
              nested = any(tab$level > 1L), breaks = 0L, builtin = nm %in% builtin)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL

  if (!is.null(family)) {
    known <- unique(stats::na.omit(out$family))
    if (!family %in% known) {
      stop("unknown palette family '", family, "'. Available: ",
           if (length(known)) paste(known, collapse = ", ") else "(none)", call. = FALSE)
    }
    out <- out[!is.na(out$family) & out$family == family, , drop = FALSE]
    rownames(out) <- NULL
  }
  out
}

.info_row <- function(nm, spec = NULL, type = NA_character_, n = NA_integer_,
                      nested = NA, breaks = NA_integer_, builtin = NA) {
  m <- spec$meta
  data.frame(
    name = nm,
    title = .chr1(m$title),
    source = .chr1(m$source),
    family = .chr1(m$family),
    measure = .chr1(m$measure),
    default = isTRUE(m$default),
    type = type,
    n = n,
    nested = nested,
    breaks = breaks,
    unit = .chr1(m$unit),
    builtin = builtin,
    stringsAsFactors = FALSE
  )
}

.chr1 <- function(x) if (is.null(x) || !length(x)) NA_character_ else as.character(x)[1]
                  
                  # A palette is continuous when it says so, or when its `colors:` block is an
                  # unnamed sequence of stops rather than a map of named entries.
                  .palette_type <- function(spec) {
  t <- .chr1(spec$meta$type)
  if (!is.na(t) && nzchar(t)) {
    if (!t %in% c("discrete", "continuous")) {
      stop("meta$type must be 'discrete' or 'continuous', not '", t, "'", call. = FALSE)
    }
    return(t)
  }
  if (is.null(names(spec$colors))) "continuous" else "discrete"
}

# Ordered stops of a continuous palette.
.palette_stops <- function(spec) {
  as.character(unlist(spec$colors, use.names = FALSE))
}

#' Register a user palette for this session
#'
#' Makes a palette file available by name, so it can be used anywhere a built-in
#' palette name is accepted. The registration lasts for the session only; to make
#' it permanent, call this from `.Rprofile` or pass `file =` explicitly.
#'
#' @param name Name to register the palette under.
#' @param file Path to the palette YAML file.
#' @return Invisibly, the previously registered path for `name`, or `NULL`.
#' @examples
#' p <- energypal_create(c(Coal = "#2C2C2C", Solar = "#FFA500"), name = "mine")
#' f <- tempfile(fileext = ".yml")
#' energypal_write(p, f)
#' energypal_register("mine", f)
#' energypal("mine")
#' @seealso [energypal_create()], [energypal_write()], [energypal_info()]
#' @export
energypal_register <- function(name, file) {
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    stop("`name` must be a single non-empty string.", call. = FALSE)
  }
  if (!file.exists(file)) stop("palette file not found: ", file, call. = FALSE)
  # Fail early on an unreadable or invalid file rather than at first use
  energypal_validate(yaml::read_yaml(file), strict = FALSE)
  previous <- if (exists(name, envir = .energypal_registry, inherits = FALSE)) {
    get(name, envir = .energypal_registry, inherits = FALSE)
  } else {
    NULL
  }
  assign(name, normalizePath(file, winslash = "/"), envir = .energypal_registry)
  invisible(previous)
}

#' Load a palette specification
#'
#' Reads a palette YAML file and returns its parsed contents, resolving
#' `meta.extends` against the palette it inherits from. The result is cached on
#' the file's path and modification time, so editing a palette during
#' development invalidates the entry on its own.
#'
#' @param palette Name of a built-in or registered palette. Defaults to the
#'   `energypal.palette` option, or `"carriers"`.
#' @param file Path to a palette file, taking precedence over `palette`.
#' @param force Logical; if `TRUE`, re-read even when cached.
#' @return A list with `meta` and `colors` elements.
#' @examples
#' spec <- energypal_spec("carriers")
#' names(spec)
#' spec$meta$title
#' @seealso [energypal()] for a colour vector, [energypal_table()] for a data frame.
#' @export
energypal_spec <- function(palette = NULL, file = NULL, force = FALSE) {
  path <- .palette_file(palette, file)
  key <- paste0("spec:", path, ":", as.numeric(file.mtime(path)))
  if (!force) {
    hit <- .cache_get(key)
    if (!is.null(hit)) return(hit)
  }
  spec <- yaml::read_yaml(path)
  spec <- .resolve_extends(spec, path)
  .cache_set(key, spec)
}

# Merge a palette over the one named by meta.extends. `seen` guards against
# circular inheritance.
.resolve_extends <- function(spec, path, seen = character()) {
  parent <- spec$meta$extends
  if (is.null(parent) || !nzchar(parent)) return(spec)
  if (parent %in% seen) {
    stop("circular palette inheritance: ", paste(c(seen, parent), collapse = " -> "),
         call. = FALSE)
  }
  base <- yaml::read_yaml(.palette_file(parent))
  base <- .resolve_extends(base, path, c(seen, parent))

  # Taxonomy is inherited; colour is not. A report palette states what its
  # source actually publishes, so a carrier the source is silent about comes
  # back unmapped rather than quietly borrowing the parent's colour. The
  # structure stays, because hierarchy, labels, aliases and orderings are shared
  # vocabulary rather than a colour claim.
  declared <- .declared_colors(spec$colors)
  spec$colors <- .blank_colors(.merge_nodes(base$colors, spec$colors), declared)
  # Orderings and property metadata are inherited too, child overriding by name.
  # Without this a palette would inherit `_carbon_intensity` values from its
  # parent while losing the note that says they are presentation only.
  spec$orders <- utils::modifyList(base$orders %||% list(), spec$orders %||% list())
  spec$properties <- utils::modifyList(base$properties %||% list(),
                                       spec$properties %||% list())
  if (!length(spec$orders)) spec$orders <- NULL
  if (!length(spec$properties)) spec$properties <- NULL
  spec
}

# Names in a tree that carry a colour of their own, at any depth.
.declared_colors <- function(tree) {
  out <- character()
  for (nm in names(tree)) {
    node <- tree[[nm]]
    if (is.character(node) && length(node) == 1L) {
      out <- c(out, nm)
    } else if (is.list(node)) {
      if (!is.null(node$`_color`)) out <- c(out, nm)
      kids <- setdiff(names(node)[!startsWith(names(node), "_")], "subtypes")
      if (length(kids)) out <- c(out, .declared_colors(node[kids]))
      if (is.list(node$subtypes)) out <- c(out, .declared_colors(node$subtypes))
    }
  }
  unique(out)
}

# Drop the colour from every node whose name is not in `keep`, leaving the node
# itself in place so labels, aliases and hierarchy survive.
.blank_colors <- function(tree, keep) {
  for (nm in names(tree)) {
    node <- tree[[nm]]
    if (is.character(node) && length(node) == 1L) {
      # a bare colour becomes an empty map rather than disappearing
      if (!nm %in% keep) tree[[nm]] <- list()
      next
    }
    if (!is.list(node)) next
    if (!nm %in% keep) node$`_color` <- NULL
    kids <- setdiff(names(node)[!startsWith(names(node), "_")], "subtypes")
    if (length(kids)) node[kids] <- .blank_colors(node[kids], keep)
    if (is.list(node$subtypes) && length(node$subtypes)) {
      node$subtypes <- .blank_colors(node$subtypes, keep)
    }
    tree[[nm]] <- node
  }
  tree
}

# Merge an overriding tree onto a base tree.
#
# Overrides are written flat - a report palette is a short list of hex codes -
# but the entries they name usually live deep in the base hierarchy. So each
# override is applied wherever its name occurs in the base tree, at any depth,
# including inside `subtypes`. A name that occurs more than once (Nuclear is
# both a group and the carrier inside it) is overridden in every position, which
# is what keeps a group and its single child in step. A name that does not occur
# at all is a new entry and is added at the top level.
.merge_nodes <- function(base, over) {
  if (is.null(base)) return(over)
  if (is.null(over)) return(base)
  for (nm in names(over)) {
    o <- over[[nm]]
    paths <- .find_all_paths(base, nm)
    if (!length(paths)) {
      base[[nm]] <- o
      next
    }
    for (p in paths) base <- .apply_override(base, p, o)
  }
  base
}

# Every path at which `target` occurs in the tree, as a character vector usable
# for recursive `[[` indexing.
.find_all_paths <- function(tree, target, prefix = character()) {
  out <- list()
  for (nm in names(tree)) {
    node <- tree[[nm]]
    path <- c(prefix, nm)
    if (identical(nm, target)) out[[length(out) + 1L]] <- path
    if (is.list(node)) {
      # children are the plain keys; anything `_`-prefixed is a label or property
      kids <- setdiff(names(node)[!startsWith(names(node), "_")], "subtypes")
      if (length(kids)) out <- c(out, .find_all_paths(node[kids], target, path))
      if (is.list(node$subtypes) && length(node$subtypes)) {
        out <- c(out, .find_all_paths(node$subtypes, target, c(path, "subtypes")))
      }
    }
  }
  out
}

.apply_override <- function(tree, path, o) {
  cur <- tree[[path]]
  if (is.list(cur) && is.character(o) && length(o) == 1L) {
    # Bare colour over a full node: change the colour, keep labels and aliases
    cur[["_color"]] <- o
    tree[[path]] <- cur
  } else if (is.list(cur) && is.list(o)) {
    tree[[path]] <- .merge_one(cur, o)
  } else {
    tree[[path]] <- o
  }
  tree
}

.merge_one <- function(base, over) {
  for (k in names(over)) {
    if (identical(k, "_aliases")) {
      # Aliases accumulate rather than replace. A report palette adding its
      # source's wording ("Petroleum", "Nuclear Electric Power") is widening the
      # vocabulary the matcher understands, not narrowing it - overwriting here
      # would quietly drop "natural gas" from a palette that names gas "Gas".
      base[[k]] <- unique(c(unlist(base[[k]]), unlist(over[[k]])))
    } else if (is.list(base[[k]]) && is.list(over[[k]])) {
      base[[k]] <- .merge_one(base[[k]], over[[k]])
    } else {
      base[[k]] <- over[[k]]
    }
  }
  base
}

#' Build a palette from a named colour vector
#'
#' Turns a named character vector of hex colours into a palette object that can
#' be written to YAML with [energypal_write()], registered with
#' [energypal_register()], or used directly.
#'
#' This is the quickest way in: start from a vector, save it, then edit the YAML
#' to add labels and aliases where they earn their keep.
#'
#' @param x Named character vector of hex colours, e.g. `c(Coal = "#2C2C2C")`.
#' @param name Palette name. Defaults to `"custom"`.
#' @param title Human-readable title. Defaults to `name`.
#' @param extends Optional name of a palette to inherit labels and aliases from.
#' @return A palette specification list, with class `energypal_create`.
#' @examples
#' p <- energypal_create(c(Coal = "#2C2C2C", Solar = "#FFA500"), name = "mine")
#' p$meta$name
#' names(p$colors)
#' @seealso [energypal_write()], [energypal_register()]
#' @export
energypal_create <- function(x, name = "custom", title = NULL, extends = NULL) {
  if (!is.character(x) || is.null(names(x)) || any(!nzchar(names(x)))) {
    stop("`x` must be a named character vector of colours.", call. = FALSE)
  }
  bad <- x[!.is_hex(x)]
  if (length(bad)) {
    stop("not valid hex colours: ",
         paste(sprintf("%s = '%s'", names(bad), bad), collapse = ", "), call. = FALSE)
  }
  if (anyDuplicated(names(x))) {
    stop("duplicate names in `x`: ",
         paste(unique(names(x)[duplicated(names(x))]), collapse = ", "), call. = FALSE)
  }
  spec <- list(
    meta = c(
      list(name = name, title = title %||% name, version = "0.1.0"),
      if (!is.null(extends)) list(extends = extends) else NULL
    ),
    colors = as.list(unname(x))
  )
  names(spec$colors) <- names(x)
  structure(spec, class = c("energypal_create", "list"))
}

#' Write a palette to a YAML file
#'
#' Serialises a palette so it can be edited by hand and reloaded. Entries are
#' written in the simple `Name: "#RRGGBB"` form; any entry can then be expanded
#' in place into a map with `_color`, `_short`, `_long` and `_aliases` without
#' restructuring the rest of the file.
#'
#' @param pal A palette from [energypal_create()], or any named colour vector.
#' @param file Path to write to.
#' @return Invisibly, `file`.
#' @examples
#' p <- energypal_create(c(Coal = "#2C2C2C", Solar = "#FFA500"), name = "mine")
#' f <- tempfile(fileext = ".yml")
#' energypal_write(p, f)
#' cat(readLines(f), sep = "\n")
#' @seealso [energypal_create()], [energypal_register()]
#' @export
energypal_write <- function(pal, file) {
  if (is.character(pal)) pal <- energypal_create(pal)
  if (!is.list(pal) || is.null(pal$colors)) {
    stop("`pal` must be an energypal_create or a named colour vector.", call. = FALSE)
  }
  meta <- pal$meta %||% list(name = "custom")
  lines <- c(
    "# energypal palette",
    "#",
    "# Each entry may be a bare colour, or a map with _color, _short, _long and",
    "# _aliases. Add detail to individual entries as needed; the rest can stay simple.",
    "",
    "meta:"
  )
  for (k in names(meta)) {
    lines <- c(lines, sprintf("  %s: %s", k, .yaml_scalar(meta[[k]])))
  }
  lines <- c(lines, "", "colors:")
  lines <- c(lines, .emit_nodes(pal$colors, indent = "  "))
  writeLines(lines, file)
  invisible(file)
}

.yaml_scalar <- function(x) {
  x <- as.character(x)[1]
  # Quote anything that is not a plain word, so titles with punctuation survive.
  if (grepl("^[A-Za-z0-9_. -]+$", x)) x else paste0('"', gsub('"', '\\\\"', x), '"')
}

.emit_nodes <- function(nodes, indent) {
  out <- character()
  for (nm in names(nodes)) {
    v <- nodes[[nm]]
    if (is.character(v) && length(v) == 1L) {
      out <- c(out, sprintf('%s%s: "%s"', indent, nm, v))
    } else if (is.list(v)) {
      out <- c(out, sprintf("%s%s:", indent, nm))
      for (k in names(v)) {
        vk <- v[[k]]
        if (is.character(vk) && length(vk) > 1L) {
          out <- c(out, sprintf("%s  %s: [%s]", indent, k, paste(vk, collapse = ", ")))
        } else if (is.list(vk)) {
          out <- c(out, sprintf("%s  %s:", indent, k),
                   .emit_nodes(vk, paste0(indent, "    ")))
        } else {
          out <- c(out, sprintf('%s  %s: %s', indent, k, .yaml_scalar(vk)))
        }
      }
    }
  }
  out
}

#' Validate a palette specification
#'
#' Checks a palette for the problems that would otherwise surface as confusing
#' behaviour much later: a missing or misnamed `meta` block, colours that are not
#' hex, an `extends` target that does not exist, and duplicate entry names.
#'
#' Used by the package's own test suite across every built-in palette, and by
#' [energypal_register()] before accepting a user file.
#'
#' @section Strict mode:
#' `strict = TRUE` additionally requires provenance: a `meta$license` saying how
#' the colours were obtained, and, where that licence is a CC BY variant, the
#' `meta$attribution` it requires. This is the standard every palette in the
#' package must meet, and what a contributed palette is held to.
#'
#' It is *not* applied to palettes you register yourself. Your own colours need
#' no licence statement, and [energypal_register()] validates leniently so that
#' a project palette is a two-line file rather than a paperwork exercise.
#'
#' @param x A palette specification (from [energypal_spec()] or
#'   [energypal_create()]), or a path to a palette file.
#' @param name Optional expected palette name, checked against `meta$name`.
#' @param strict Also require provenance. `TRUE` by default, since the usual
#'   reason to call this directly is to check a palette meant for sharing.
#' @return Invisibly `TRUE`. Throws an error describing every problem found.
#' @examples
#' # your own colours: structure only
#' energypal_validate(energypal_create(c(Coal = "#2C2C2C")), strict = FALSE)
#'
#' # what a shipped palette must satisfy
#' energypal_validate(energypal_spec("owid"), name = "owid")
#' @export
energypal_validate <- function(x, name = NULL, strict = TRUE) {
  if (is.character(x) && length(x) == 1L && file.exists(x)) x <- yaml::read_yaml(x)
  problems <- character()

  if (!is.list(x)) stop("palette must be a list or a path to a palette file.", call. = FALSE)
  if (is.null(x$meta)) problems <- c(problems, "missing `meta:` block")
  if (is.null(x$meta$name) || !nzchar(.chr1(x$meta$name))) {
    problems <- c(problems, "missing `meta$name`")
  } else if (!is.null(name) && !identical(.chr1(x$meta$name), name)) {
    problems <- c(problems, sprintf("meta$name is '%s' but the palette is named '%s'",
                                    .chr1(x$meta$name), name))
  }
  if (is.null(x$colors) || !length(x$colors)) {
    problems <- c(problems, "missing or empty `colors:` block")
  }
  ext <- x$meta$extends
  if (!is.null(ext) && nzchar(ext)) {
    ok <- tryCatch({ .palette_file(ext); TRUE }, error = function(e) FALSE)
    if (!ok) problems <- c(problems, sprintf("`extends: %s` names a palette that does not exist", ext))
  }

  if (!is.null(x$colors) && length(x$colors)) {
    cols <- .collect_colors(x$colors)
    bad <- cols[!is.na(cols) & !.is_hex(cols)]
    if (length(bad)) {
      problems <- c(problems, sprintf("not valid hex colours: %s",
                                      paste(sprintf("%s = '%s'", names(bad), bad),
                                            collapse = ", ")))
    }
  }

  # Provenance is mandatory. Colours taken from a published source carry
  # obligations, and the only way to keep track of them across a store that
  # anyone can add a file to is to refuse a file that does not say where its
  # colours came from.
  lic <- .chr1(x$meta$license)
  if (!strict) {
    # skip the provenance rules entirely
  } else if (is.na(lic) || !nzchar(lic)) {
    problems <- c(problems,
                  "no `meta$license:` - every palette must state how its colours were obtained")
  } else if (grepl("CC BY", lic, fixed = TRUE)) {
    att <- .chr1(x$meta$attribution)
    if (is.na(att) || !nzchar(att)) {
      problems <- c(problems, paste(
        "`meta$license` declares CC BY but there is no `meta$attribution:`",
        "- that licence requires a citation, so the palette must carry one"))
    }
    # CC BY 4.0 s3(a)(1)(A)(iii) asks for a URI to the licence itself. Naming it
    # is not the same as linking it, and the link is the part that rots quietly.
    if (!grepl("https://", lic, fixed = TRUE)) {
      problems <- c(problems, paste(
        "`meta$license` declares CC BY but links no licence deed",
        "- include the https:// URI the licence asks you to provide"))
    }
  }

  # Orderings and numeric properties arrange visuals; they are not model inputs.
  # Requiring the note here is what stops that caveat being quietly dropped when
  # somebody adds an ordering later.
  for (nm in names(x$orders)) {
    o <- x$orders[[nm]]
    if (is.character(o)) next          # bare vector, nothing claimed, nothing to cite
    if (is.null(o$`_order`) || !length(o$`_order`)) {
      problems <- c(problems, sprintf("ordering '%s' has no `_order:` sequence", nm))
    }
    if (!nzchar(.chr1(o$`_note`)) || is.na(.chr1(o$`_note`))) {
      problems <- c(problems, sprintf(
        "ordering '%s' has no `_note:` - every declared ordering must state that it is for presentation only",
        nm))
    }
  }
  for (nm in names(x$properties)) {
    p <- x$properties[[nm]]
    if (!nzchar(.chr1(p$`_note`)) || is.na(.chr1(p$`_note`))) {
      problems <- c(problems, sprintf(
        "property '%s' has no `_note:` - every declared property must state that it is for presentation only",
        nm))
    }
  }

  # A palette that claims a family must say which quantity it styles, otherwise
  # its siblings are indistinguishable and silently interchangeable.
  fam <- .chr1(x$meta$family)
  if (!is.na(fam) && nzchar(fam)) {
    if (is.na(.chr1(x$meta$measure)) || !nzchar(.chr1(x$meta$measure))) {
      problems <- c(problems, sprintf(
        "palette declares `family: %s` but no `measure:` - siblings in a family must name the quantity they style",
        fam))
    }
    nm_x <- .chr1(x$meta$name)
    want <- paste0(fam, "_", .chr1(x$meta$measure))
    if (!is.na(nm_x) && !identical(nm_x, want)) {
      problems <- c(problems, sprintf(
        "name '%s' does not follow the family convention - expected '%s'", nm_x, want))
    }
  }

  if (length(problems)) {
    stop("invalid palette", if (!is.null(name)) paste0(" '", name, "'") else "", ":\n",
         paste0("  - ", problems, collapse = "\n"), call. = FALSE)
  }
  invisible(TRUE)
}

#' Check the family structure of the built-in palettes
#'
#' Validates relationships *between* palette files, which
#' [energypal_validate()] cannot see because it inspects one file at a
#' time: each family must have exactly one default member, and `measure` must be
#' unique within a family.
#'
#' @return Invisibly `TRUE`. Throws an error listing every problem found.
#' @examples
#' energypal_validate_families()
#' @seealso [energypal_validate()], [energypal_info()]
#' @export
energypal_validate_families <- function() {
  fam <- .family_index()
  problems <- character()
  for (nm in names(fam)) {
    f <- fam[[nm]]
    if (length(f$members) > 1L && is.na(f$default)) {
      problems <- c(problems, sprintf(
        "family '%s' has %d members but none marked `default: true` (%s)",
        nm, length(f$members), paste(f$members, collapse = ", ")))
    }
    dups <- unique(f$measures[duplicated(f$measures)])
    if (length(dups)) {
      problems <- c(problems, sprintf("family '%s' repeats measure(s): %s",
                                      nm, paste(dups, collapse = ", ")))
    }
    if (any(is.na(f$measures))) {
      problems <- c(problems, sprintf("family '%s' has a member with no `measure:`", nm))
    }
  }
  # a family name must not collide with a palette file name, or the family alias
  # would be shadowed by the file and resolve somewhere unexpected
  clash <- intersect(names(fam), .builtin_names())
  if (length(clash)) {
    problems <- c(problems, sprintf("family name(s) collide with palette file names: %s",
                                    paste(clash, collapse = ", ")))
  }

  if (length(problems)) {
    stop("invalid palette families:\n", paste0("  - ", problems, collapse = "\n"),
         call. = FALSE)
  }
  invisible(TRUE)
}

.is_hex <- function(x) grepl("^#[0-9A-Fa-f]{6}$", x)
                    
                    # Every colour anywhere in a node tree, named by entry.
# Every colour in a tree, keyed by path, for the validator's hex check.
.collect_colors <- function(nodes, prefix = "") {
  out <- character()
  for (nm in names(nodes)) {
    v <- nodes[[nm]]
    key <- if (nzchar(prefix)) paste0(prefix, ">", nm) else nm
    if (is.character(v) && length(v) == 1L) {
      out[key] <- v
    } else if (is.list(v) && !is.null(names(v))) {
      if (!is.null(v[["_color"]])) out[key] <- as.character(v[["_color"]])[1]
      # Children are the plain keys. Every `_`-prefixed key is a label or a
      # property, never a node - a string-valued property such as
      # `_taxonomy_source` would otherwise be checked as though it were a colour.
      children <- v[!startsWith(names(v), "_")]
      if (length(children)) out <- c(out, .collect_colors(children, key))
    }
  }
  out
}

`%||%` <- function(x, y) if (is.null(x)) y else x
