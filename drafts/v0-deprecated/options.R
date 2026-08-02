#' Package Energy Color Options
#'
#' Manage global options controlling automatic color variation, warnings, and thresholds
#' used by the energypal package. These are lightweight runtime (session) options that
#' do not persist between R sessions.
#'
#' @section Available Options:
#' * enable_auto_variations (logical) - Automatically generate color variations for duplicate mappings (default: FALSE)
#' * variation_type (character) - Type of variation to apply: "lightness", "saturation", "hue", or "mixed" (default: "lightness")
#' * variation_intensity (numeric 0-1) - Strength of variation adjustments (default: 0.35)
#' * min_sources_for_variation (integer) - Minimum number of sources sharing a color before variations are generated (default: 2)
#' * warn_auto_variations (logical) - Emit a warning when auto variations are generated (default: TRUE)
#' * warn_duplicate_mappings (logical) - Warn when multiple sources map to the same color and variations off (default: TRUE)
#'
#' @param ... Named options to set. Use a named list or named arguments.
#' @return For `set_energy_options()`, invisibly returns a named list of the previous values
#'   of any options that were set. For `get_energy_options()` returns either the full list of
#'   current option values (if `name` is NULL) or the value of a single option.
#'
#' @examples
#' old <- set_energy_options(enable_auto_variations = TRUE, variation_type = "saturation")
#' get_energy_options()
#' get_energy_options("variation_type")
#' # Restore
#' do.call(set_energy_options, old)
#'
#' @name energy_options
NULL

.energy_options_env <- new.env(parent = emptyenv())

.default_energy_options <- list(
  enable_auto_variations = FALSE,
  variation_type = "lightness",
  variation_intensity = 0.35,
  min_sources_for_variation = 2,
  warn_auto_variations = TRUE,
  warn_duplicate_mappings = TRUE
)

# Initialize defaults on load (defensive; also called in .onLoad if defined elsewhere)
if (!exists(".energy_options_initialized", envir = .energy_options_env, inherits = FALSE)) {
  list2env(.default_energy_options, envir = .energy_options_env)
  assign(".energy_options_initialized", TRUE, envir = .energy_options_env)
}

#' Set energypal global options
#' @rdname energy_options
#' @export
set_energy_options <- function(...) {
  dots <- list(...)
  if (length(dots) == 1 && is.list(dots[[1]]) && is.null(names(dots))) {
    # Allow passing a single named list
    dots <- dots[[1]]
  }
  if (length(dots) == 0) {
    return(invisible(list()))
  }
  # Validate option names
  invalid <- setdiff(names(dots), names(.default_energy_options))
  if (length(invalid) > 0) {
    stop("Unknown energy option(s): ", paste(invalid, collapse = ", "))
  }
  old <- lapply(names(dots), get_energy_options)
  names(old) <- names(dots)
  # Validation per option
  for (nm in names(dots)) {
    val <- dots[[nm]]
    if (nm == "enable_auto_variations" || nm == "warn_auto_variations" || nm == "warn_duplicate_mappings") {
      if (!is.logical(val) || length(val) != 1 || is.na(val)) stop(nm, " must be a single logical value")
    } else if (nm == "variation_type") {
      if (!is.character(val) || length(val) != 1) stop("variation_type must be single character")
      if (!val %in% c("lightness", "saturation", "hue", "mixed")) stop("variation_type must be one of: lightness, saturation, hue, mixed")
    } else if (nm == "variation_intensity") {
      if (!is.numeric(val) || length(val) != 1 || is.na(val) || val < 0 || val > 1) stop("variation_intensity must be numeric in [0,1]")
    } else if (nm == "min_sources_for_variation") {
      if (!is.numeric(val) || length(val) != 1 || val < 1) stop("min_sources_for_variation must be >=1")
      val <- as.integer(val)
    }
    assign(nm, val, envir = .energy_options_env)
  }
  invisible(old)
}

#' Get energypal global options
#' @param name Option name (optional). If NULL returns all options as a named list.
#' @rdname energy_options
#' @export
get_energy_options <- function(name = NULL) {
  if (is.null(name)) {
    vals <- mget(names(.default_energy_options), envir = .energy_options_env, inherits = FALSE)
    return(vals)
  }
  if (!name %in% names(.default_energy_options)) {
    stop("Unknown energy option: ", name)
  }
  get(name, envir = .energy_options_env, inherits = FALSE)
}
