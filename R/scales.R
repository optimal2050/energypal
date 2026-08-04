## ggplot2 scales
#
# The discrete scale has to colour whatever labels the data actually contains,
# which ggplot2's palette function cannot see - it is handed a count, not the
# levels. The levels are captured through `limits`, which ggplot2 does call with
# the observed values, and which runs before the palette function. That also
# makes `limits` the natural place to apply a declared ordering.
#
# The continuous scale is a thin wrapper over scale_*_gradientn(). The binned one
# is not a wrapper over scale_*_stepsn(), which would resample the palette by
# data position rather than honour the bins it declares - see .bin_palette().

.check_palette_type <- function(palette, file, want, fn) {
  got <- .palette_type(energypal_spec(palette = palette, file = file))
  if (identical(got, want)) return(invisible(TRUE))
  nm <- palette %||% basename(file %||% "")
  stop(sprintf(
    "%s() needs a %s palette, but '%s' is %s.\n  Use %s instead.",
    fn, want, nm, got,
    if (want == "discrete") "scale_*_energy_c() or scale_*_energy_b()" else "scale_*_energy()"
  ), call. = FALSE)
}

# Observed levels, resequenced by a declared ordering.
#
# With `order = NULL` the levels are returned untouched, so a factor's own level
# order is respected - which is how a ggplot2 user usually expects to control
# sequence. Only an explicit `order` overrides it.
#
# Ranking is done against the ordered table, which already keeps each family
# together: an entry the ordering does not name sorts with its nearest named
# ancestor. So "Natural Gas", which resolves to the NaturalGas subtype rather
# than to FossilGas, lands beside the other fossil fuels without any special
# handling here.
.order_levels <- function(levels, palette, file, order, direction) {
  reverse <- identical(as.numeric(direction), -1)
  if (is.null(order)) return(if (reverse) rev(levels) else levels)

  m <- energypal_match(levels, palette = palette, file = file, warn = FALSE)
  matched <- m$matched[match(levels, m$original)]

  tab <- energypal_table(palette = palette, file = file, include_groups = TRUE,
                         order = order)
  rank <- match(matched, tab$name)
  rank[is.na(rank)] <- nrow(tab) + seq_len(sum(is.na(rank)))
  out <- levels[order(rank, seq_along(levels))]

  # Reverse the resulting sequence rather than the table. A palette may hold the
  # same name at two levels (Nuclear is both a group and the carrier inside it),
  # and match() would then pick a different row from a flipped table - so
  # direction = -1 would not be exactly rev() of the forward order.
  if (reverse) rev(out) else out
}

# Legend labels for the observed levels.
.level_labels <- function(levels, palette, file, label_style) {
  if (identical(label_style, "asis")) return(levels)
  m <- energypal_match(levels, palette = palette, file = file, warn = FALSE)
  matched <- m$matched[match(levels, m$original)]
  if (identical(label_style, "id")) {
    return(ifelse(is.na(matched), levels, matched))
  }
  tab <- energypal_table(palette = palette, file = file, include_groups = TRUE)
  idx <- match(matched, tab$name)
  lab <- switch(label_style,
    short = tab$label_short[idx],
    long = tab$label_long[idx],
    default = tab$label_default[idx]
  )
  ifelse(is.na(lab) | !nzchar(lab), levels, lab)
}

#' Energy colour scales for ggplot2
#'
#' Colour the series of a plot from an energy palette. The discrete scale
#' resolves whatever labels your data contains — `"Coal"`, `"nat gas"`,
#' `"COAL1"` — through [energypal_match()], so it works on real data without
#' preprocessing. The `_c` and `_b` variants take a continuous palette and give
#' a smooth gradient or binned steps.
#'
#' @section Choosing a variant:
#' \describe{
#'   \item{`scale_fill_energy()`}{discrete data: carriers, technologies, sectors.}
#'   \item{`scale_fill_energy_c()`}{continuous data with a smooth ramp.}
#'   \item{`scale_fill_energy_b()`}{continuous data in bins, using the palette's
#'     own break points unless you override them. This is how resource maps are
#'     conventionally drawn.}
#' }
#' Passing a continuous palette to the discrete scale, or the reverse, is an
#' error rather than a silent half-result.
#'
#' @param palette Name of a built-in or registered palette. Defaults to the
#'   `energypal.palette` option, or `"carriers"` — except for `_c()` and `_b()`,
#'   which need a continuous palette and default to `"windatlas"`.
#' @param file Path to a palette file, taking precedence over `palette`.
#' @param order Legend order. `NULL` keeps the data's own order; otherwise a
#'   declared ordering such as `"carbon_intensity"` or `"merit_order"`, a
#'   computed one such as `"alpha"`, or an explicit vector. See
#'   [energypal_orders()].
#'
#'   **Presentation only** — orderings arrange the legend and are not model inputs.
#' @param direction `1` (default) or `-1` to reverse the order.
#' @param label_style How to label the legend: `"asis"` (default) keeps the
#'   labels your data uses; `"id"` shows the canonical identifier; `"short"`,
#'   `"long"` and `"default"` use the palette's display labels.
#' @param unmapped_color Colour for labels the palette cannot resolve
#'   (default `"#999999"`), so they are visibly unmapped rather than silently wrong.
#' @param gradient Logical; shade labels that resolve to the same carrier into
#'   distinct tones of it (default `FALSE`). See [energypal_gradient()].
#' @param breaks For `_b()`, the bin boundaries. `NULL` (default) uses the
#'   palette's declared breaks.
#' @param guide,na.value,... Passed to the underlying ggplot2 scale.
#'
#' @return A ggplot2 scale, to be added to a plot with `+`.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   library(ggplot2)
#'   d <- subset(owid_energy_mix, year == max(owid_energy_mix$year))
#'
#'   # the data says "Coal", "Natural Gas", "Oil" - no preprocessing needed
#'   ggplot(d, aes(country, percentage, fill = source)) +
#'     geom_col() +
#'     scale_fill_energy()
#'
#'   # a published colour scheme
#'   ggplot(d, aes(country, percentage, fill = source)) +
#'     geom_col() +
#'     scale_fill_energy(palette = "ipcc")
#'
#'   # order the stack by carbon intensity rather than alphabetically
#'   ggplot(d, aes(country, percentage, fill = source)) +
#'     geom_col() +
#'     scale_fill_energy(order = "carbon_intensity")
#' }
#' @seealso [energypal()] for the palette, [energypal_colors()] for the colours
#'   alone, [energypal_orders()] for the available orderings.
#' @name scale_energy
NULL

#' @rdname scale_energy
#' @export
scale_fill_energy <- function(palette = NULL, file = NULL, order = NULL,
                              direction = 1, label_style = c("asis", "id", "short",
                                                             "long", "default"),
                              unmapped_color = "#999999", gradient = FALSE,
                              guide = "legend", ...) {
  label_style <- match.arg(label_style)
  .energy_discrete("fill", palette, file, order, direction, label_style,
                   unmapped_color, gradient, guide, ...)
}

#' @rdname scale_energy
#' @export
scale_colour_energy <- function(palette = NULL, file = NULL, order = NULL,
                                direction = 1, label_style = c("asis", "id", "short",
                                                               "long", "default"),
                                unmapped_color = "#999999", gradient = FALSE,
                                guide = "legend", ...) {
  label_style <- match.arg(label_style)
  .energy_discrete("colour", palette, file, order, direction, label_style,
                   unmapped_color, gradient, guide, ...)
}

#' @rdname scale_energy
#' @export
scale_color_energy <- scale_colour_energy

.energy_discrete <- function(aesthetic, palette, file, order, direction,
                             label_style, unmapped_color, gradient, guide, ...) {
  .check_palette_type(palette, file, "discrete", paste0("scale_", aesthetic, "_energy"))

  # `limits` is called by ggplot2 with the observed levels and runs before the
  # palette function, so it is where the levels are captured and reordered.
  seen <- new.env(parent = emptyenv())
  seen$levels <- character()

  limits_fn <- function(observed) {
    observed <- as.character(observed)
    lv <- .order_levels(observed, palette, file, order, direction)
    seen$levels <- lv
    lv
  }

  pal_fn <- function(n) {
    lv <- seen$levels
    if (!length(lv)) return(rep(unmapped_color, n))
    unname(energypal_colors(lv, palette = palette, file = file,
                            unmapped_color = unmapped_color,
                            gradient = gradient, warn = FALSE))
  }

  labels_fn <- function(breaks) {
    .level_labels(as.character(breaks), palette, file, label_style)
  }

  ggplot2::discrete_scale(
    aesthetics = aesthetic, palette = pal_fn,
    limits = limits_fn, labels = labels_fn, guide = guide, ...
  )
}

#' @rdname scale_energy
#' @export
scale_fill_energy_c <- function(palette = "windatlas", file = NULL, direction = 1,
                                na.value = "grey50", ...) {
  .check_palette_type(palette, file, "continuous", "scale_fill_energy_c")
  ggplot2::scale_fill_gradientn(
    colours = energypal(palette = palette, file = file, direction = direction),
    na.value = na.value, ...
  )
}

#' @rdname scale_energy
#' @export
scale_colour_energy_c <- function(palette = "windatlas", file = NULL, direction = 1,
                                  na.value = "grey50", ...) {
  .check_palette_type(palette, file, "continuous", "scale_colour_energy_c")
  ggplot2::scale_colour_gradientn(
    colours = energypal(palette = palette, file = file, direction = direction),
    na.value = na.value, ...
  )
}

#' @rdname scale_energy
#' @export
scale_color_energy_c <- scale_colour_energy_c

#' @rdname scale_energy
#' @export
scale_fill_energy_b <- function(palette = "windatlas", file = NULL, breaks = NULL,
                                direction = 1, na.value = "grey50", ...) {
  .check_palette_type(palette, file, "continuous", "scale_fill_energy_b")
  .energy_binned("fill", palette, file, breaks, direction, na.value, list(...))
}

#' @rdname scale_energy
#' @export
scale_colour_energy_b <- function(palette = "windatlas", file = NULL, breaks = NULL,
                                  direction = 1, na.value = "grey50", ...) {
  .check_palette_type(palette, file, "continuous", "scale_colour_energy_b")
  .energy_binned("colour", palette, file, breaks, direction, na.value, list(...))
}

#' @rdname scale_energy
#' @export
scale_color_energy_b <- scale_colour_energy_b

# One declared colour per declared bin.
#
# `scale_*_stepsn()` looks like the natural fit and is not: it treats `colours`
# as a gradient to *sample*, positioning each bin by where its midpoint falls in
# the data range. So the colours a palette declares only appear when the data
# happens to span exactly the declared breaks, and whenever it runs wider the
# ends become unreachable - 20 m/s and 27 m/s both drew as the 25th of 31 stops
# rather than the last one.
#
# A binned scale asks its palette function for the bin midpoints, having first
# put them through `rescaler`. Pass identity there and the midpoints arrive in
# data units, so the right colour is a `findInterval()` away and the mapping is
# exact for any data range. `n` bins from `n - 1` breaks, with the two open-ended
# bins at the ends taking the first and last colour.
.bin_palette <- function(cols, breaks) {
  force(cols); force(breaks)
  function(mid) {
    idx <- findInterval(mid, sort(breaks)) + 1L
    cols[pmin(pmax(idx, 1L), length(cols))]
  }
}

.identity_rescaler <- function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) x

.energy_binned <- function(aesthetic, palette, file, breaks, direction, na.value, dots) {
  breaks <- breaks %||% .palette_breaks(palette, file)
  cols <- energypal(palette = palette, file = file, direction = direction)
  args <- .thin_labels(breaks, dots)
  do.call(ggplot2::binned_scale, c(
    list(aesthetics = aesthetic,
         palette = .bin_palette(cols, breaks),
         breaks = breaks,
         rescaler = .identity_rescaler,
         na.value = na.value,
         guide = "coloursteps"),
    args
  ))
}

.palette_breaks <- function(palette, file) {
  brk <- as.numeric(unlist(energypal_spec(palette = palette, file = file)$breaks))
  if (!length(brk)) {
    stop("palette declares no `breaks:`; pass `breaks =` explicitly.", call. = FALSE)
  }
  brk
}

# Resource palettes declare a lot of bins - windatlas has 30 - and labelling
# every one makes the legend unreadable. Keep all the bins, label a readable
# subset. Any `labels` the caller supplies wins.
.thin_labels <- function(breaks, dots, max_labels = 10L) {
  if ("labels" %in% names(dots) || length(breaks) <= max_labels) return(dots)
  keep <- seq(1L, length(breaks), length.out = max_labels)
  keep <- unique(round(keep))
  dots$labels <- function(b) ifelse(seq_along(b) %in% keep, format(b, trim = TRUE), "")
  dots
}
