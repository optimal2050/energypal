# testthat.R already attaches the package; nothing further is needed here.
#
# An earlier version of this file sourced R/hierarchy.R directly as a fallback
# for running test_dir() without loading the namespace. That file no longer
# exists, and devtools::test() / testthat::test_local() both load the package
# properly, so the fallback only masked failures.
