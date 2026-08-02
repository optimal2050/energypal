# Diagnostic script for color mapping issues
source("R/defaults.R")
source("R/palettes.R")
source("R/mapping.R")
source("R/utils.R")
source("R/scales.R")

suppressPackageStartupMessages(library(ggplot2))

palette_name <- "iea_primary"
base_palette <- get_energy_palette(palette_name)

# Simulated data with all palette names and some common variants
sources <- c(names(base_palette),
             "Gas", "Solar PV", "Wind Power", "Hydroelectric", "Biomass")

df <- data.frame(
  source = factor(sources),
  value = seq_along(sources)
)

cat("\n=== BASE PALETTE (", palette_name, ") ===\n", sep="")
print(base_palette)

cat("\n=== INPUT SOURCES ===\n")
print(df$source)

cat("\n=== EXPECTED DIRECT LOOKUP (BY EXACT NAME) ===\n")
expected_direct <- base_palette[as.character(df$source)]
print(expected_direct)

cat("\n=== MAPPED VIA map_energy_colors(auto) ===\n")
mapped_auto <- tryCatch(
  map_energy_colors(as.character(df$source), palette_name = palette_name, method = "auto", unmapped_color = "#999999", apply_variations = FALSE),
  error = function(e){ message("Mapping error: ", e$message); rep("ERROR", length(df$source)) }
)
print(mapped_auto)

cat("\n=== SCALE ASSIGNMENT (scale_fill_energy) ORDER & COLORS ===\n")
# Build plot to capture scale output
p <- ggplot(df, aes(x = source, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy(palette = palette_name) +
  theme_minimal()

pb <- ggplot_build(p)
fill_scale <- pb$plot$scales$get_scales("fill")
palette_func <- fill_scale$palette
# ggplot2 will call palette with number of levels
scale_colors <- palette_func(length(levels(df$source)))
assigned <- setNames(scale_colors, levels(df$source))
print(assigned)

cat("\n=== COMPARISON TABLE ===\n")
comparison <- data.frame(
  source = levels(df$source),
  expected_exact = unname(base_palette[levels(df$source)]),
  mapped_auto = unname(mapped_auto[levels(df$source)]),
  scale_assigned = unname(assigned[levels(df$source)])
)
print(comparison, right=FALSE)

cat("\n=== MISMATCH FLAGS ===\n")
comparison$match_exact_vs_scale <- comparison$expected_exact == comparison$scale_assigned
comparison$match_mapped_vs_scale <- comparison$mapped_auto == comparison$scale_assigned
print(comparison[, c("source","match_exact_vs_scale","match_mapped_vs_scale")], right=FALSE)

# Summaries
cat("\nExact matches:", sum(comparison$match_exact_vs_scale, na.rm=TRUE), "/", nrow(comparison),"\n")
cat("Auto mapping matches:", sum(comparison$match_mapped_vs_scale, na.rm=TRUE), "/", nrow(comparison),"\n")

# Identify problematic sources
problem_sources <- comparison$source[!(comparison$match_exact_vs_scale | comparison$match_mapped_vs_scale)]
cat("\nProblematic sources:", paste(problem_sources, collapse=", "),"\n")