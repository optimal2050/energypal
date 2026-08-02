# Helper to ensure package loaded for tests
if (requireNamespace('energypal', quietly = TRUE)) {
  library(energypal)
}

# Fallback: when running tests via test_dir without building/loading the package namespace
# (e.g., local rapid iteration), source R scripts to expose new functions.
if (!exists("hierarchy_to_table")) {
  candidate <- file.path(getwd(), "R", "hierarchy.R")
  if (file.exists(candidate)) {
    sys.source(candidate, envir = topenv())
  }
}
