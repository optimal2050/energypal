## Palette ordering
#
# ------------------------------------------------------------------------
# EVERYTHING IN THIS FILE ARRANGES VISUALS.
#
# Orderings and the numeric properties behind them order legends and chart
# series. They are indicative, not validated figures, and must never be used
# in calculations. Each declared ordering and property carries a `_note` in
# the palette file saying so, and energypal_validate() refuses a
# declaration that omits it.
# ------------------------------------------------------------------------
#
# An ordering is resolved from, in precedence order:
#   1. an explicit character vector of entry ids
#   2. a name declared in the palette's `orders:` block
#   3. a numeric property name, sorted descending
#   4. a computed ordering: spec, alpha, hue, lightness, chroma

.computed_orders <- c("spec", "alpha", "hue", "lightness", "chroma")

# The declared orderings of a specification, as name -> character vector.
.spec_orders <- function(spec) {
  o <- spec$orders
  if (is.null(o) || !length(o)) return(list())
  lapply(o, function(x) {
    if (is.character(x)) x else as.character(unlist(x$`_order`))
  })
}

.spec_order_meta <- function(spec, nm) {
  x <- spec$orders[[nm]]
  if (is.null(x) || is.character(x)) {
    list(note = NA_character_, source = NA_character_, url = NA_character_)
  } else {
    list(note = .chr1(x$`_note`), source = .chr1(x$`_source`), url = .chr1(x$`_url`))
  }
}

# Row indices of `tab` in the requested order.
.resolve_order <- function(tab, order = NULL, spec = NULL, direction = 1) {
  idx <- seq_len(nrow(tab))

  if (!is.null(order)) {
    if (length(order) > 1L || !(order[1] %in% c(.computed_orders,
                                                names(.spec_orders(spec)),
                                                names(tab)))) {
      idx <- .order_by_ids(tab, as.character(order))
    } else {
      key <- order[1]
      declared <- .spec_orders(spec)
      if (key %in% names(declared)) {
        # a declared sequence wins over a like-named property: the curated
        # answer beats the raw input it was derived from
        idx <- .order_by_ids(tab, declared[[key]])
      } else if (key %in% .computed_orders) {
        idx <- .order_computed(tab, key)
      } else {
        # a property column, descending, entries without a value last
        v <- .inherit_from_parent(tab[[key]], tab)
        idx <- order(is.na(v), -xtfrm(v), seq_along(v))
      }
    }
  }

  if (identical(as.numeric(direction), -1)) idx <- rev(idx)
  idx
}

# Order by a sequence of ids, keeping each family together.
#
# Orderings are declared at carrier level - carbon_intensity names nine entries -
# but a palette holds 93, most of them subtypes. An entry the sequence does not
# name sorts with its nearest named ancestor, immediately after it, so
# FossilCoal is followed by Anthracite, Bituminous and the rest rather than the
# coal family being scattered. Entries with no named ancestor go last, in file
# order.
.order_by_ids <- function(tab, ids) {
  ids <- as.character(ids)
  anchor <- .lift_to_set(tab$name, tab, ids)
  rank <- match(anchor, ids)
  rank[is.na(rank)] <- length(ids) + 1L
  order(rank, seq_len(nrow(tab)))
}

# Each name replaced by itself if it is in `set`, else its nearest ancestor that
# is, else NA.
.lift_to_set <- function(names, tab, set) {
  parent_of <- stats::setNames(tab$parent, tab$name)
  vapply(names, function(nm) {
    for (. in seq_len(8L)) {
      if (is.na(nm)) return(NA_character_)
      if (nm %in% set) return(nm)
      nm <- unname(parent_of[nm])
    }
    NA_character_
  }, character(1), USE.NAMES = FALSE)
}

# A subtype rarely carries its own figure, so it takes its parent's. Without
# this, ordering by a numeric property would strand every subtype at the end.
.inherit_from_parent <- function(v, tab) {
  parent_of <- stats::setNames(tab$parent, tab$name)
  idx_of <- stats::setNames(seq_len(nrow(tab)), tab$name)
  for (i in which(is.na(v))) {
    nm <- tab$parent[i]
    for (. in seq_len(8L)) {
      if (is.na(nm)) break
      j <- idx_of[nm]
      if (!is.na(j) && !is.na(v[j])) { v[i] <- v[j]; break }
      nm <- unname(parent_of[nm])
    }
  }
  v
}

.order_computed <- function(tab, key) {
  if (key == "spec") return(seq_len(nrow(tab)))
  if (key == "alpha") return(order(tab$name))
  col <- tab$color
  ok <- !is.na(col) & nzchar(col)
  val <- rep(NA_real_, length(col))
  if (any(ok)) {
    hcl <- farver::decode_colour(col[ok], to = "hcl")
    val[ok] <- switch(key,
      hue = hcl[, "h"],
      lightness = hcl[, "l"],
      chroma = hcl[, "c"]
    )
  }
  order(is.na(val), val, seq_along(val))
}

#' Orderings available for a palette
#'
#' Lists the orderings that can be passed to `order` in [energypal()],
#' [energypal_table()] and the scale functions, together with the note and
#' source recorded for each.
#'
#' @section Presentation only:
#' Orderings arrange legends and chart series. They are **not** model inputs.
#' The sequences, and the numeric properties some of them derive from, are
#' indicative values chosen so that charts read sensibly; they are not validated
#' figures and must not be used in calculations. Every declared ordering carries
#' a note saying so, printed by this function.
#'
#' @param palette Name of a built-in or registered palette. Defaults to the
#'   `energypal.palette` option, or `"carriers"`.
#' @param file Path to a palette file, taking precedence over `palette`.
#'
#' @return A data frame with one row per available ordering and columns
#'   `order`, `kind` (`"declared"`, `"property"` or `"computed"`), `n`, `note`,
#'   `source` and `url`.
#' @examples
#' energypal_orders("carriers")
#'
#' # the note travels with the ordering
#' energypal_orders("carriers")$note[1]
#' @seealso [energypal()], [energypal_table()]
#' @export
energypal_orders <- function(palette = NULL, file = NULL) {
  spec <- energypal_spec(palette = palette, file = file)
  tab <- .palette_table(spec, palette %||% "carriers")

  declared <- .spec_orders(spec)
  rows <- list()

  for (nm in names(declared)) {
    m <- .spec_order_meta(spec, nm)
    rows[[length(rows) + 1L]] <- data.frame(
      order = nm, kind = "declared", n = length(declared[[nm]]),
      note = m$note, source = m$source, url = m$url, stringsAsFactors = FALSE
    )
  }

  # Only numeric properties are orderings. A text property such as
  # `_taxonomy_source` is provenance carried alongside the entries - real data,
  # available in energypal_table(), but nothing you would sort a legend by.
  props <- setdiff(names(tab), c(.base_cols, "label_default", "palette"))
  props <- props[vapply(tab[props], is.numeric, logical(1))]
  for (p in setdiff(props, names(declared))) {
    rows[[length(rows) + 1L]] <- data.frame(
      order = p, kind = "property", n = sum(!is.na(tab[[p]])),
      note = attr(tab[[p]], "note") %||% NA_character_,
      source = attr(tab[[p]], "source") %||% NA_character_,
      url = attr(tab[[p]], "url") %||% NA_character_, stringsAsFactors = FALSE
    )
  }

  for (cmp in .computed_orders) {
    rows[[length(rows) + 1L]] <- data.frame(
      order = cmp, kind = "computed", n = nrow(tab),
      note = "Computed from the palette itself. Presentation only.",
      source = NA_character_, url = NA_character_, stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
