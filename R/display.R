## Palette display
#
# Two views, chosen by how many palettes are asked for:
#   one palette   -> a vertical list, swatch + name + hex, so long identifiers
#                    like HydrogenDerivatives stay readable
#   many palettes -> aligned rows, one per palette, sharing a column per entry,
#                    so the same carrier can be compared down the page

#' Plot energy palettes
#'
#' Draws a palette so you can look at it. Given several palette names it draws
#' them as aligned rows instead, one row per palette and one column per entry,
#' which is the quickest way to see how two published colour schemes differ.
#'
#' @param palette Palette name, or a character vector of names to compare.
#'   Defaults to the `energypal.palette` option, or `"carriers"`. Pass
#'   `energypal_info()$name` to see everything at once.
#' @param n Number of colours to show from each palette. `NULL` shows all.
#' @param file Path to a palette file, taking precedence over `palette`.
#'   Only meaningful for a single palette.
#' @param label_style How to label entries: `"default"`, `"id"`, `"short"` or
#'   `"long"`. See [energypal()].
#' @param include_groups,include_subtypes Passed to [energypal()]; both `FALSE`
#'   by default, matching the plotting palette.
#' @param show_hex Logical; show the hex code alongside the name in the
#'   single-palette view (default `TRUE`).
#'
#' @return Invisibly, the palette(s) drawn: a named colour vector for a single
#'   palette, or a named list of them.
#' @examples
#' energypal_show("carriers")
#'
#' # Compare published schemes
#' energypal_show(c("carriers", "eia", "ipcc", "owid"))
#'
#' # Everything the package ships
#' energypal_show(energypal_info()$name)
#' @seealso [energypal()] for the colours themselves, [energypal_info()] for
#'   the list of palettes.
#' @export
energypal_show <- function(palette = NULL,
                           n = NULL,
                           file = NULL,
                           label_style = c("default", "id", "short", "long"),
                           include_groups = FALSE,
                           include_subtypes = FALSE,
                           show_hex = TRUE) {
  label_style <- match.arg(label_style)
  if (is.null(palette) && is.null(file)) palette <- getOption("energypal.palette", "carriers")

  if (!is.null(file) || length(palette) == 1L) {
    spec <- energypal_spec(palette = palette, file = file)
    nm <- if (!is.null(file)) basename(file) else palette
    if (.palette_type(spec) == "continuous") {
      pal <- energypal(palette = palette, n = n, file = file)
      .show_ramp(pal, title = nm, breaks = as.numeric(unlist(spec$breaks)),
                 unit = .chr1(spec$meta$unit))
      return(invisible(pal))
    }
    pal <- energypal(palette = palette, n = n, file = file, label_style = label_style,
                     include_groups = include_groups, include_subtypes = include_subtypes)
    .show_one(pal, title = nm, show_hex = show_hex)
    return(invisible(pal))
  }

  specs <- lapply(palette, function(p) energypal_spec(palette = p))
  continuous <- vapply(specs, function(s) .palette_type(s) == "continuous", logical(1))

  pals <- lapply(palette, function(p) {
    energypal(palette = p, n = n, label_style = "id",
              include_groups = include_groups, include_subtypes = include_subtypes)
  })
  names(pals) <- palette

  # Several ramps compare best stacked with their own break labels; there are no
  # shared entries to align on.
  if (all(continuous)) {
    .show_ramps(pals,
                breaks = lapply(specs, function(s) as.numeric(unlist(s$breaks))),
                units = vapply(specs, function(s) .chr1(s$meta$unit), character(1)))
    return(invisible(pals))
  }

  # The comparison view aligns entries in columns, so it must key on the
  # canonical id: each palette labels a carrier in its own source's words
  # ("Oil", "Petroleum"), and keying on the label would put the same carrier in
  # a different column for every palette. Labels are resolved separately, once,
  # from whichever palette first defines each id.
  .show_many(pals, labels = .common_labels(palette[!continuous], label_style),
             continuous = continuous)
  invisible(pals)
}

# id -> display label, taking the first palette that defines each id.
.common_labels <- function(palette, label_style) {
  if (identical(label_style, "id")) return(NULL)
  col <- switch(label_style, default = "label_default", short = "label_short",
                long = "label_long")
  out <- character()
  for (p in palette) {
    tab <- tryCatch(energypal_table(p, include_groups = TRUE),
                    error = function(e) NULL)
    if (is.null(tab) || is.null(tab[[col]])) next
    ok <- !is.na(tab[[col]]) & nzchar(tab[[col]]) & !(tab$name %in% names(out))
    if (any(ok)) out[tab$name[ok]] <- tab[[col]][ok]
  }
  out
}

# Half-height of a palette bar, in row units. Shared so that a stack of ramps and
# a grid of swatches draw the same weight - they sit next to each other on the
# gallery page and a mismatch reads as an accident.
.bar_half <- 0.42

# Vertical list: swatch, name, hex.
.show_one <- function(pal, title, show_hex = TRUE) {
  if (!length(pal)) stop("palette is empty", call. = FALSE)
  k <- length(pal)
  op <- graphics::par(mar = c(0.5, 0.5, 2.5, 0.5))
  on.exit(graphics::par(op), add = TRUE)

  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(k + 0.5, 0.5))
  graphics::title(main = title)

  for (i in seq_len(k)) {
    graphics::rect(0.02, i - 0.4, 0.22, i + 0.4, col = pal[i], border = "grey40", lwd = 0.5)
    lab <- names(pal)[i]
    if (show_hex) lab <- paste0(lab, "   ", pal[i])
    graphics::text(0.26, i, lab, adj = c(0, 0.5), cex = 0.8)
  }
  invisible(NULL)
}

# Continuous palettes: a horizontal ramp with break labels beneath. Bins are
# drawn as-is rather than smoothed, because a declared-breaks palette is meant
# to be read as bins.
.show_ramp <- function(pal, title, breaks = numeric(), unit = NA_character_) {
  k <- length(pal)
  if (!k) stop("palette is empty", call. = FALSE)
  bottom <- if (length(breaks)) 0.6 else 0.25
  op <- graphics::par(mai = c(bottom, 0.4, 0.45, 0.25))
  on.exit(graphics::par(op), add = TRUE)

  graphics::plot.new()
  graphics::plot.window(xlim = c(0.5, k + 0.5), ylim = c(0, 1))
  graphics::title(main = if (is.na(unit)) title else paste0(title, "  (", unit, ")"))

  for (i in seq_len(k)) {
    graphics::rect(i - 0.5, 0.35, i + 0.5, 0.85, col = pal[i], border = NA)
  }
  graphics::rect(0.5, 0.35, k + 0.5, 0.85, border = "grey40", lwd = 0.5)

  if (length(breaks)) {
    # breaks sit between bins, so break j is at the boundary after colour j
    at <- seq_along(breaks) + 0.5
    show <- if (length(breaks) > 12) {
      unique(round(seq(1, length(breaks), length.out = 10)))
    } else {
      seq_along(breaks)
    }
    graphics::segments(at[show], 0.30, at[show], 0.35, col = "grey40", lwd = 0.6)
    graphics::text(at[show], 0.24, format(breaks[show], trim = TRUE),
                   adj = c(0.5, 1), cex = 0.7, srt = 90)
  }
  invisible(NULL)
}

# Several ramps, one per row, each drawn in its own bins with its own end
# labels. Continuous palettes measure different quantities in different units,
# so there is nothing to align on and a shared axis would be a lie; each row
# carries its own range instead.
.show_ramps <- function(pals, breaks = list(), units = character()) {
  np <- length(pals)
  labs <- names(pals)
  ends <- vapply(seq_len(np), function(i) {
    b <- breaks[[i]]
    u <- if (length(units) >= i && !is.na(units[i])) units[i] else ""
    if (!length(b)) return("")
    sprintf("%s - %s %s", format(min(b), trim = TRUE), format(max(b), trim = TRUE), u)
  }, character(1))

  left <- max(graphics::strwidth(labs, units = "inches", cex = 0.85)) + 0.15
  right <- max(graphics::strwidth(ends, units = "inches", cex = 0.7)) + 0.2
  op <- graphics::par(mai = c(0.2, left, 0.35, right))
  on.exit(graphics::par(op), add = TRUE)

  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(np + 0.5, 0.5), xaxs = "i")

  for (r in seq_len(np)) {
    pal <- pals[[r]]
    k <- length(pal)
    at <- seq(0, 1, length.out = k + 1L)
    for (j in seq_len(k)) {
      graphics::rect(at[j], r - .bar_half, at[j + 1L], r + .bar_half,
                     col = pal[j], border = NA)
    }
    graphics::rect(0, r - .bar_half, 1, r + .bar_half, border = "grey40", lwd = 0.5)
    graphics::mtext(labs[r], side = 2, at = r, las = 1, line = 0.3, cex = 0.85)
    if (nzchar(ends[r])) {
      graphics::mtext(ends[r], side = 4, at = r, las = 1, line = 0.3, cex = 0.7)
    }
  }
  invisible(NULL)
}

# Aligned rows, one per palette, one column per entry (union across palettes,
# in first-seen order). Entries a palette does not define are left blank.
.show_many <- function(pals, labels = NULL, continuous = rep(FALSE, length(pals))) {
  entries <- unique(unlist(lapply(pals[!continuous], names), use.names = FALSE))
  np <- length(pals)
  ne <- length(entries)
  if (!ne) stop("palettes are empty", call. = FALSE)

  axis_labs <- entries
  if (!is.null(labels)) {
    hit <- labels[entries]
    axis_labs[!is.na(hit)] <- hit[!is.na(hit)]
  }

  # Leave room on the left for palette names and at the bottom for entry names
  left <- max(graphics::strwidth(names(pals), units = "inches", cex = 0.85)) + 0.15
  bottom <- max(graphics::strwidth(axis_labs, units = "inches", cex = 0.7)) + 0.2
  op <- graphics::par(mai = c(bottom, left, 0.35, 0.15))
  on.exit(graphics::par(op), add = TRUE)

  graphics::plot.new()
  graphics::plot.window(xlim = c(0.5, ne + 0.5), ylim = c(np + 0.5, 0.5))

  for (r in seq_len(np)) {
    pal <- pals[[r]]
    # A continuous palette has no entries to align on, so it spans the row as a
    # ramp rather than leaving a blank line among the discrete ones.
    if (continuous[r]) {
      ramp <- grDevices::colorRampPalette(pal)(ne)
      for (cix in seq_len(ne)) {
        graphics::rect(cix - 0.5, r - .bar_half, cix + 0.5, r + .bar_half,
                       col = ramp[cix], border = NA)
      }
      graphics::rect(0.5, r - .bar_half, ne + 0.5, r + .bar_half, border = "grey40", lwd = 0.5)
      graphics::mtext(names(pals)[r], side = 2, at = r, las = 1, line = 0.3, cex = 0.85)
      next
    }
    for (cix in seq_len(ne)) {
      col <- pal[entries[cix]]
      if (is.na(col)) next
      graphics::rect(cix - 0.5, r - .bar_half, cix + 0.5, r + .bar_half,
                     col = col, border = "white", lwd = 0.6)
    }
    graphics::mtext(names(pals)[r], side = 2, at = r, las = 1, line = 0.3, cex = 0.85)
  }
  graphics::mtext(axis_labs, side = 1, at = seq_len(ne), las = 2, line = 0.3, cex = 0.7)
  invisible(NULL)
}
