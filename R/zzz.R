## Package-local state
#
# A single environment for cached palette specifications and for palettes the
# user registers at run time. Declared at top level so it is created when the
# namespace is loaded and is private to it.
#
# This replaces an earlier arrangement that stashed an environment inside
# options() and fell back to assigning into .GlobalEnv during development;
# both mutate state outside the package.

.energypal_cache <- new.env(parent = emptyenv())

# Clear every cached palette specification.
#
# Mostly useful in tests and when editing palette YAML during development.
# Not exported: `energypal_spec(force = TRUE)` is the user-facing way to
# bypass the cache for a single palette.
.cache_clear <- function() {
  rm(list = ls(envir = .energypal_cache, all.names = TRUE), envir = .energypal_cache)
  invisible(NULL)
}

.cache_get <- function(key) {
  if (exists(key, envir = .energypal_cache, inherits = FALSE)) {
    get(key, envir = .energypal_cache, inherits = FALSE)
  } else {
    NULL
  }
}

.cache_set <- function(key, value) {
  assign(key, value, envir = .energypal_cache)
  invisible(value)
}
