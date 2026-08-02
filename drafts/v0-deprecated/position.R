#' Energy-specific stacking position helper
#'
#' Control vertical stacking order of geom_col / geom_bar independently of
#' legend / scale ordering. ggplot2's stacking order is determined first by
#' factor level order, but the drawing order within a single x position can be
#' inverted using the `reverse` argument of `position_stack()`. This helper
#' maps the energypal `direction` semantic (-1 foundation high-carbon at bottom,
#' 1 invert) to that `reverse` flag.
#'
#' @param direction Integer; -1 (default) means high-carbon (Coal) at bottom;
#'   1 means invert (Coal on top). Any other value is ignored (treated as -1).
#' @param ... Passed through to [ggplot2::position_stack()].
#'
#' @return A ggplot2 position object.
#' @export
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' data(owid_energy_mix)
#' d <- subset(owid_energy_mix, country == 'United States' & year == max(year))
#'
#' # Default (Coal at bottom)
#' ggplot(d, aes(x=country, y=percentage, fill=source)) +
#'   geom_col(position = position_energy_stack(direction = -1)) +
#'   scale_fill_energy()
#'
#' # Inverted (Coal at top)
#' ggplot(d, aes(x=country, y=percentage, fill=source)) +
#'   geom_col(position = position_energy_stack(direction = 1)) +
#'   scale_fill_energy()
#' }
position_energy_stack <- function(direction = -1, ...) {
  rev_flag <- isTRUE(direction == 1)
  ggplot2::position_stack(reverse = rev_flag, ...)
}

#' Energy column / bar geoms with ordering & stack direction
#'
#' Convenience wrappers around [ggplot2::geom_col()] and [ggplot2::geom_bar()] that:
#' 
#' * Apply canonical energy source ordering (carbon intensity by default)
#' * Allow independent control of legend/source order vs. physical stack order
#' * Optionally add an appropriate energy fill scale automatically
#' * Support palette color sequence reversal without changing label order
#' * Provide duplicate source color variation parameters consistent with scale functions
#'
#' These geoms separate three concepts:
#' 
#' * `direction` (passed to scale) – legend/source ordering and how colors map to sources
#' * `stack_direction` (geom-level) – physical drawing order of stacked columns/bars
#' * `palette_direction` – whether the palette's color sequence itself is reversed while keeping source order constant
#'
#' @param mapping,data,stat,position,... Standard geom aesthetic/data arguments.
#' @param stack_direction Integer (1 or -1). Controls vertical stacking ( -1 = high-carbon at bottom / canonical foundation; 1 = inverted ).
#' @param auto_order Logical; if TRUE (default) reorder factor levels of the fill variable in the supplied `data` according to `order_method` or `custom_order` and `stack_direction`.
#' @param order_method Character; method for canonical order when `auto_order=TRUE`: one of "carbon_intensity", "dispatchability", "palette_order".
#' @param custom_order Character vector giving explicit source order (takes precedence over `order_method`).
#' @param palette Palette name (passed to scale if added) used for ordering context as well.
#' @param direction Integer (1 or -1). Legend/source ordering (affects scale limits order only).
#' @param palette_direction Integer (1 or -1). Reverse only the palette's color sequence (legend order unchanged).
#' @param scale_add Logical; if TRUE (default) automatically add `scale_fill_energy()` when a fill aesthetic is mapped and no energy scale already present.
#' @param apply_variations Logical; forward to scale to enable duplicate source variations.
#' @param variation_type Character; variation strategy (lightness, saturation, hue, mixed) forwarded to scale.
#' @param variation_intensity Numeric (0-1); intensity for variations.
#' @param label_style Character; passed to the automatically added scale to control legend label form when using hierarchy ("default","short","long","id").
#' @param use_hierarchy Logical; if TRUE and a scale is auto-added, the set of fill levels and labels are derived from the hierarchy table instead of just palette names.
#' @param section Character; hierarchy section ("carriers" or "technologies") used when `use_hierarchy=TRUE`.
#'
#' @return A ggplot2 layer (or a list of layer + scale when `scale_add=TRUE`).
#' @examples
#' \dontrun{
#' library(ggplot2)
#' data(owid_energy_mix)
#' recent <- subset(owid_energy_mix, year == max(year))
#'
#' # Canonical ordering & stacking (high-carbon foundation at bottom)
#' ggplot(recent, aes(country, percentage, fill = source)) +
#'   geom_energy_col() +
#'   scale_fill_energy()
#'
#' # Invert physical stack but keep legend order
#' ggplot(recent, aes(country, percentage, fill = source)) +
#'   geom_energy_col(stack_direction = 1) +
#'   scale_fill_energy()
#'
#' # Reverse legend/source order separately
#' ggplot(recent, aes(country, percentage, fill = source)) +
#'   geom_energy_col(direction = -1) +
#'   scale_fill_energy(direction = -1)
#'
#' # Reverse palette color sequence only
#' ggplot(recent, aes(country, percentage, fill = source)) +
#'   geom_energy_col(palette_direction = -1) +
#'   scale_fill_energy(palette_direction = -1)
#'
#' # Custom explicit order
#' ggplot(recent, aes(country, percentage, fill = source)) +
#'   geom_energy_col(custom_order = c("Solar","Wind","Hydro","Coal")) +
#'   scale_fill_energy(custom_order = c("Solar","Wind","Hydro","Coal"))
#' }
#' @export
geom_energy_col <- function(mapping = NULL, data = NULL, stat = "identity",
                            position = "stack", ..., stack_direction = -1,
                            auto_order = TRUE, order_method = "carbon_intensity",
                            custom_order = NULL, palette = NULL, direction = 1,
                            palette_direction = 1, scale_add = TRUE,
                            apply_variations = NULL, variation_type = NULL,
                            variation_intensity = NULL,
                            label_style = c("default","short","long","id"),
                            use_hierarchy = FALSE,
                            section = c("carriers","technologies")) {

  label_style <- match.arg(label_style)
  section <- match.arg(section)

  if (is.null(palette)) palette <- "hierarchy_carriers"

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for this function.")
  }

  # Determine fill aesthetic symbol if present
  fill_var <- NULL
  if (!is.null(mapping) && !is.null(mapping$fill)) {
    fill_var <- rlang::as_label(mapping$fill)
  }

  # Preprocess data factor ordering if requested
  if (auto_order && !is.null(fill_var) && !is.null(data)) {
    if (fill_var %in% names(data)) {
      base_order <- if (!is.null(custom_order)) custom_order else get_canonical_order(palette, order_method)
      present_sources <- unique(data[[fill_var]])
      canonical_present <- intersect(base_order, present_sources)
      non_canonical <- setdiff(present_sources, canonical_present)
      
      # Build final order exactly like the scale does
      if (direction == -1) {
        final_order <- c(non_canonical, rev(canonical_present))
      } else {
        final_order <- c(canonical_present, non_canonical)
      }
      
      # Apply stack_direction only for physical display (reverse if needed)
      if (stack_direction == 1) {
        final_order <- rev(final_order)
      }
      
      data[[fill_var]] <- factor(data[[fill_var]], levels = final_order)
    }
  } else if (auto_order && !is.null(fill_var) && is.null(data)) {
    # Attempt a lightweight fallback: if the fill var exists in the parent frame data (ggplot main data)
    parent_data <- tryCatch(get("data", parent.frame()), error = function(e) NULL)
    if (is.data.frame(parent_data) && fill_var %in% names(parent_data)) {
      base_order <- if (!is.null(custom_order)) custom_order else get_canonical_order(palette, order_method)
      present_sources <- unique(parent_data[[fill_var]])
      canonical_present <- intersect(base_order, present_sources)
      non_canonical <- setdiff(present_sources, canonical_present)
      
      # Build final order exactly like the scale does
      if (direction == -1) {
        final_order <- c(non_canonical, rev(canonical_present))
      } else {
        final_order <- c(canonical_present, non_canonical)
      }
      
      # Apply stack_direction only for physical display (reverse if needed)
      if (stack_direction == 1) {
        final_order <- rev(final_order)
      }
      
      # We cannot mutate parent data safely; instead, create a local copy for this layer
      data <- parent_data
      data[[fill_var]] <- factor(data[[fill_var]], levels = final_order)
    } else if (is.null(getOption("energypal.warned_auto_order_null_data"))) {
      warning("geom_energy_col(auto_order=TRUE) could not determine ordering (no per-layer data and no accessible parent data). Provide data= for deterministic stacking.")
      options(energypal.warned_auto_order_null_data = TRUE)
    }
  }

  # Position handling
  if (identical(position, "stack")) {
    position <- position_energy_stack(direction = stack_direction)
  }

  layer <- ggplot2::geom_col(mapping = mapping, data = data, stat = stat,
                             position = position, ...)

  if (is.null(fill_var) || !isTRUE(scale_add)) {
    return(layer)
  }

  # Add scale after layer to ensure precedence only if not already added (simple heuristic)
  scale <- scale_fill_energy(palette = palette, order_method = order_method,
                             custom_order = custom_order, direction = direction,
                             palette_direction = palette_direction, auto_order = TRUE,
                             data = data,
                             apply_variations = apply_variations,
                             variation_type = variation_type,
                             variation_intensity = variation_intensity,
                             label_style = label_style,
                             use_hierarchy = use_hierarchy,
                             section = section)
  list(layer, scale)
}

#' @rdname geom_energy_col
#' @export
geom_energy_bar <- function(mapping = NULL, data = NULL, stat = "count",
                            position = "stack", ..., stack_direction = -1,
                            auto_order = TRUE, order_method = "carbon_intensity",
                            custom_order = NULL, palette = NULL, direction = 1,
                            palette_direction = 1, scale_add = TRUE,
                            apply_variations = NULL, variation_type = NULL,
                            variation_intensity = NULL,
                            label_style = c("default","short","long","id"),
                            use_hierarchy = FALSE,
                            section = c("carriers","technologies")) {
  label_style <- match.arg(label_style)
  section <- match.arg(section)
  geom_energy_col(mapping = mapping, data = data, stat = stat, position = position,
                  ..., stack_direction = stack_direction, auto_order = auto_order,
                  order_method = order_method, custom_order = custom_order,
                  palette = palette, direction = direction, palette_direction = palette_direction,
                  scale_add = scale_add, apply_variations = apply_variations,
                  variation_type = variation_type, variation_intensity = variation_intensity,
                  label_style = label_style, use_hierarchy = use_hierarchy,
                  section = section)
}
