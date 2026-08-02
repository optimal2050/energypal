#' Match Energy Source Names to Palette Entries
#'
#' Robust multi-stage matcher aligning arbitrary data source labels to a palette's
#' canonical source names. Implements:
#' 1. Exact match
#' 2. Canonicalized (case/space/punct/number stripped) match
#' 3. Fuzzy / synonym / regex assisted match with string distance disambiguation
#'
#' @param sources Character vector of (possibly repeated) source labels from data.
#' @param palette_name Character palette identifier (default: current default palette).
#' @param include_full_palette Logical; if TRUE, append unmatched palette rows even if
#'   not present in data (default FALSE).
#' @param max_distance Maximum Levenshtein distance (normalized 0-1) allowed for fuzzy step (default 0.4).
#' @param warn Logical; emit warnings about ambiguous matches (default TRUE).
#'
#' @return data.frame with columns:
#'   original (unique input), matched (palette name or NA), color (hex or NA), method (match stage), candidates (semicolon list if ambiguous)
#' @export
#'
#' @examples
#' match_energy_sources(c("Coal","coal power","  natural   gas ","Solar PV"), palette_name = "iea_primary")
match_energy_sources <- function(sources,
                                 palette_name = NULL,
                                 include_full_palette = FALSE,
                                 max_distance = 0.4,
                                 warn = TRUE) {
  if (is.null(palette_name)) palette_name <- get_default_energy_palette()
  pal <- get_energy_palette(palette_name)
  stopifnot(is.character(sources))
  src_unique <- unique(sources)

  # ---- helpers ----
  canonicalize <- function(x) {
    # lower, remove all non-letters, collapse spaces
    x2 <- tolower(x)
    x2 <- gsub("[[:space:]]+","", x2)
    x2 <- gsub("[^a-z]+","", x2)
    x2
  }

  # Build synonym map (extendable per palette if needed later)
  # Key: palette canonical name -> vector of synonyms/regex tokens
  synonym_list <- list(
    "Coal" = c("coal","coalpower","coalfired","lignite","anthracite","bituminous","subbituminous"),
    "Oil" = c("oil","petroleum","crude","fueloil","diesel","gasoline"),
    "Natural Gas" = c("naturalgas","gas","methane","lng","cng","shalegas"),
    "Nuclear" = c("nuclear","uranium","reactor","pwr","bwr"),
    "Bioenergy" = c("bioenergy","biomass","biogas","biofuel","wood","ethanol","biodiesel","waste"),
    "Geothermal" = c("geothermal","geothermalpower","groundsource"),
    "Hydro" = c("hydro","hydroelectric","waterpower","pumpedstorage","runofriver"),
    "Other Renewables" = c("otherrenewables","renewables","wave","tidal","ocean"),
    "Wind" = c("wind","windpower","windenergy","onshorewind","offshorewind","turbine"),
    "Solar" = c("solar","solarpv","photovoltaic","csp","solarthermal"),
    "Other" = c("other","misc")
  )

  pal_names <- names(pal)
  pal_canon <- canonicalize(pal_names)

  # Optionally pull hierarchy label aliases (long/short) for precedence matching
  hierarchy_aliases <- NULL
  if (requireNamespace("yaml", quietly = TRUE)) {
    # Try carriers + technologies; we only need names that exist in palette to avoid false expansions
    # We'll construct a mapping of alias -> canonical palette name
    alias_map <- list()
    safe_add <- function(tbl) {
      if (!is.null(tbl) && is.data.frame(tbl)) {
        # Filter rows whose 'name' appears in palette
        in_pal <- tbl$name %in% pal_names
        if (any(in_pal)) {
          sub <- tbl[in_pal, , drop = FALSE]
          # Long first
            if ("label_long" %in% names(sub)) {
              valid_long <- !is.na(sub$label_long) & nzchar(sub$label_long)
              if (any(valid_long)) alias_map[sub$label_long[valid_long]] <<- sub$name[valid_long]
            }
            if ("label_short" %in% names(sub)) {
              valid_short <- !is.na(sub$label_short) & nzchar(sub$label_short)
              # Do not overwrite existing long aliases
              if (any(valid_short)) {
                for (i in which(valid_short)) {
                  al <- sub$label_short[i]; canon <- sub$name[i]
                  if (!is.null(alias_map[[al]])) next
                  alias_map[[al]] <<- canon
                }
              }
            }
        }
      }
    }
    # carriers
    h1 <- try(hierarchy_to_table("carriers", include_groups = FALSE), silent = TRUE)
    if (!inherits(h1, "try-error")) safe_add(h1)
    # technologies (non-fatal)
    h2 <- try(hierarchy_to_table("technologies", include_groups = FALSE), silent = TRUE)
    if (!inherits(h2, "try-error")) safe_add(h2)
    if (length(alias_map)) {
      hierarchy_aliases <- data.frame(
        alias = names(alias_map),
        canonical = unlist(alias_map, use.names = FALSE),
        stringsAsFactors = FALSE
      )
      # Build canonicalized form for later canonical stage assistance if needed
      hierarchy_aliases$alias_canon <- canonicalize(hierarchy_aliases$alias)
    }
  }

  df <- data.frame(
    original = src_unique,
    matched = NA_character_,
    color = NA_character_,
    method = NA_character_,
    candidates = NA_character_,
    stringsAsFactors = FALSE
  )

  canon_input <- canonicalize(src_unique)

  # Stage 1: exact (case-sensitive first then insensitive?) -> use direct %in%
  exact_hits <- match(src_unique, pal_names)
  matched_exact <- !is.na(exact_hits)
  if (any(matched_exact)) {
    df$matched[matched_exact] <- pal_names[exact_hits[matched_exact]]
    df$color[matched_exact] <- unname(pal[exact_hits[matched_exact]])
    df$method[matched_exact] <- "exact"
  }

  # Stage 1b: exact long-form alias matches (hierarchy label_long) then short-form
  remaining <- which(is.na(df$matched))
  if (length(remaining) > 0 && !is.null(hierarchy_aliases)) {
    # Long aliases: those that appear in alias list but not identical to canonical name (avoid double marking)
    # We already prioritized long when building alias_map
    for (i in remaining) {
      ali <- hierarchy_aliases$canonical[hierarchy_aliases$alias == src_unique[i]]
      if (length(ali) == 1) {
        df$matched[i] <- ali
        df$color[i] <- unname(pal[ali])
        df$method[i] <- "alias"
      }
    }
  }

  # Remaining indices
  remaining <- which(is.na(df$matched))
  if (length(remaining) > 0) {
    # Stage 2: canonicalized equality
    for (i in remaining) {
      idx <- which(pal_canon == canon_input[i])
      if (length(idx) == 1) {
        df$matched[i] <- pal_names[idx]
        df$color[i] <- unname(pal[idx])
        df$method[i] <- "canonical"
      }
    }
  }

  # Update remaining
  remaining <- which(is.na(df$matched))
  if (length(remaining) > 0) {
    # Prepare fuzzy candidates
    # Build expanded map of canonical token -> canonical palette name
    token_map <- lapply(names(synonym_list), function(k){
      if (k %in% pal_names) synonym_list[[k]] else character(0)
    })
    names(token_map) <- names(synonym_list)

    # Flatten tokens for reverse lookup
    token_reverse <- data.frame(
      token = unlist(token_map, use.names = FALSE),
      canonical = rep(names(token_map), lengths(token_map)),
      stringsAsFactors = FALSE
    )

    # canonicalized tokens
    token_reverse$token_canon <- canonicalize(token_reverse$token)

    # Distance helper (normalized)
    norm_dist <- function(a,b){
      if (!requireNamespace("stringdist", quietly = TRUE)) {
        # fallback simple ad-hoc distance: proportion mismatched after padding
        la <- nchar(a); lb <- nchar(b)
        if (la == 0 && lb == 0) return(0)
        if (la == 0 || lb == 0) return(1)
        # crude: 1 - (length of longest common prefix / maxlen)
        lcp <- 0
        maxl <- min(la,lb)
        while (lcp < maxl && substr(a, lcp+1, lcp+1) == substr(b, lcp+1, lcp+1)) lcp <- lcp + 1
        return(1 - lcp / max(la,lb))
      }
      stringdist::stringdist(a,b, method = "lv") / max(nchar(a), nchar(b), 1)
    }

    for (i in remaining) {
      ci <- canon_input[i]
      # token exact canonical overlap first
      cand_rows <- token_reverse[token_reverse$token_canon == ci,]
      if (nrow(cand_rows) == 0) {
        # fuzzy: compute distance to all tokens
        dists <- vapply(token_reverse$token_canon, norm_dist, numeric(1), b = ci)
        min_d <- min(dists)
        if (!is.infinite(min_d) && min_d <= max_distance) {
          cand_rows <- token_reverse[dists <= min_d + 1e-8,]
        }
      }
      if (nrow(cand_rows) == 0) {
        next
      }
      # Reduce to palette names still in palette
      cand_pal <- unique(cand_rows$canonical[cand_rows$canonical %in% pal_names])
      if (length(cand_pal) == 1) {
        nm <- cand_pal
        df$matched[i] <- nm
        df$color[i] <- unname(pal[nm])
        df$method[i] <- "fuzzy"
      } else if (length(cand_pal) > 1) {
        # Disambiguate by computing distance to canonical names
        d_name <- vapply(cand_pal, norm_dist, numeric(1), b = ci)
        best <- cand_pal[d_name == min(d_name)]
        if (length(best) == 1) {
          nm <- best
          df$matched[i] <- nm
          df$color[i] <- unname(pal[nm])
          df$method[i] <- "fuzzy_disambiguated"
        } else {
          # Ambiguous
            df$matched[i] <- best[1]
            df$color[i] <- unname(pal[best[1]])
            df$method[i] <- "fuzzy_ambiguous"
            df$candidates[i] <- paste(cand_pal, collapse = ";")
            if (warn) warning(sprintf("Ambiguous energy source '%s' could match: %s (selected '%s')", df$original[i], paste(cand_pal, collapse=", "), best[1]), call. = FALSE)
        }
      }
    }
  }

  if (include_full_palette) {
    missing_pal <- setdiff(pal_names, df$matched)
    if (length(missing_pal) > 0) {
      add <- data.frame(
        original = rep(NA_character_, length(missing_pal)),
        matched = missing_pal,
        color = unname(pal[missing_pal]),
        method = "palette_fill",
        candidates = NA_character_,
        stringsAsFactors = FALSE
      )
      df <- rbind(df, add)
    }
  }

  df
}
