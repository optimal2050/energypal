#' Fetch the full OWID energy dataset on demand
#'
#' Downloads and returns the current full Our World in Data energy dataset
#' ("owid-energy-data.csv") as a data frame. This is not bundled with the
#' package due to size; only a curated subset (`owid_energy_mix`) ships with
#' energypal.
#'
#' @param cache Logical; if TRUE (default) store a cached copy in a user cache
#'   directory for the session (tempdir). If FALSE always re-download.
#' @param quiet Logical; suppress message output.
#'
#' @return A data.frame with the full OWID energy dataset columns.
#' @details Source repository: https://github.com/owid/energy-data
#' License: CC-BY 4.0 (provide attribution when using the data).
#'
#' @examples
#' \dontrun{
#' full <- fetch_owid_energy()
#' names(full)
#' }
#' @export
fetch_owid_energy <- function(cache = TRUE, quiet = FALSE) {
	url <- "https://raw.githubusercontent.com/owid/energy-data/master/owid-energy-data.csv"
	cache_path <- file.path(tempdir(), "owid-energy-data.csv")
	if (!cache || !file.exists(cache_path)) {
		if (!quiet) message("Downloading OWID energy dataset ...")
		utils::download.file(url, cache_path, quiet = quiet)
	}
	if (!quiet) message("Reading OWID energy dataset ...")
	utils::read.csv(cache_path, check.names = FALSE)
}
