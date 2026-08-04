## Matching data labels to palette entries
#
# Real datasets do not use canonical identifiers. They say "Natural Gas",
# "nat gas", "COAL1" or "Solar PV" where the palette says FossilGas, FossilCoal,
# SolarPV. This file resolves the former to the latter through a sequence of
# increasingly permissive strategies, stopping at the first that succeeds for a
# given label and reporting which one it was.
#
#   exact      the label is an entry name
#   canonical  it is, once case, spacing, punctuation and digits are stripped
#   alias      it is a declared `_aliases:` entry, or a _short/_long label
#   fuzzy      it is within `max_distance` of one of the above
#   contains   one of the above appears inside it ("Coal_Plant_2")
#
# Aliases come from the palette YAML, not from code. An earlier version carried
# a hard-coded block of regular expressions here, which meant the spec was in
# two places and the two disagreed.

.match_methods <- c("exact", "canonical", "alias", "fuzzy", "contains")

# The first three establish that a label really does denote an entry; the last
# two are informed guesses. The distinction decides what an entry with no colour
# outranks - see `unpublished` in energypal_match().
.precise_methods <- c("exact", "canonical", "alias")

# Shortest term allowed to match as a substring in the `contains` stage.
.min_contains <- 4L

# lower, then strip everything that is not a letter
.canonicalize <- function(x) {
  x <- tolower(as.character(x))
  gsub("[^a-z]+", "", x)
}

.norm_dist <- function(a, b) {
  stringdist::stringdist(a, b, method = "lv") / pmax(nchar(a), nchar(b), 1)
}

# Every string that may stand for an entry: its name, its labels, its aliases.
# Returns one row per (string, entry) pair, canonicalised.
.lookup_table <- function(tab) {
  add <- function(strings, kind) {
    ok <- !is.na(strings) & nzchar(strings)
    if (!any(ok)) return(NULL)
    data.frame(term = strings[ok], name = tab$name[ok], color = tab$color[ok],
               type = tab$type[ok], kind = kind, stringsAsFactors = FALSE)
  }

  parts <- list(
    add(tab$name, "name"),
    add(tab$label_short, "label"),
    add(tab$label_long, "label")
  )

  # aliases are stored ';'-separated, one row per entry
  has_alias <- !is.na(tab$aliases) & nzchar(tab$aliases)
  if (any(has_alias)) {
    idx <- which(has_alias)
    split_alias <- strsplit(tab$aliases[idx], ";", fixed = TRUE)
    reps <- lengths(split_alias)
    parts[[length(parts) + 1L]] <- data.frame(
      term = trimws(unlist(split_alias, use.names = FALSE)),
      name = rep(tab$name[idx], reps),
      color = rep(tab$color[idx], reps),
      type = rep(tab$type[idx], reps),
      kind = "alias",
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, parts[!vapply(parts, is.null, logical(1))])
  # Colourless rows are kept, flagged. They are what lets the matcher tell "this
  # palette publishes nothing for geothermal" apart from "no idea what that is".
  out$has_color <- !is.na(out$color) & nzchar(out$color)
  out$canon <- .canonicalize(out$term)
  out <- out[nzchar(out$canon), , drop = FALSE]
  rownames(out) <- NULL
  out
}

# Substring matching, for labels like "Coal_Plant_2" or "SOLAR_NY".
#
# Canonicalising strips the separators, so a term found in the middle of a label
# has no boundary to be checked against and is very often an accident: "other"
# sits inside "geothermal", "oil" inside "boiler". Requiring the match to be
# anchored at one end removes those without losing the real cases, which are all
# of the form <carrier><qualifier> or <qualifier><carrier>.
#
# The length floor stays for the other failure mode: short aliases are fine as
# whole labels ("RE", "PV", "NG") and disastrous inside one.
.contains_hits <- function(lut, cs) {
  ok <- nchar(lut$canon) >= .min_contains & nchar(lut$canon) < nchar(cs)
  if (!any(ok)) return(NULL)
  anchored <- ok & (startsWith(cs, lut$canon) | endsWith(cs, lut$canon))
  if (!any(anchored)) return(NULL)
  cand <- lut[anchored, , drop = FALSE]
  # longest match wins: "biogas" should not be taken for "gas"
  cand[nchar(cand$canon) == max(nchar(cand$canon)), , drop = FALSE]
}

# Resolve candidate rows to a single answer.
#
# Two kinds of collision are not user-facing ambiguity and must not warn:
#   - several entries sharing one colour (Nuclear is both a group and the
#     carrier inside it, both #FFD700)
#   - the same *name* at different levels (Other the group vs Other the carrier,
#     which do differ in colour). Here the specific entry is what the data means,
#     so prefer carrier, then subtype, then group.
# Only genuinely different entries are reported as ambiguous.
.type_rank <- c(carrier = 1L, subtype = 2L, group = 3L)

.settle <- function(cands, original, method, warn) {
  if (length(unique(cands$color)) == 1L) {
    return(list(name = cands$name[1], color = cands$color[1], method = method,
                candidates = NA_character_))
  }

  if (length(unique(cands$name)) == 1L) {
    rank <- .type_rank[cands$type]
    rank[is.na(rank)] <- 99L
    pick <- cands[order(rank), , drop = FALSE][1, ]
    return(list(name = pick$name, color = pick$color, method = method,
                candidates = NA_character_))
  }

  choice <- cands[1, ]
  if (warn) {
    warning(sprintf("Ambiguous energy source '%s' could be %s; using '%s'",
                    original, paste(unique(cands$name), collapse = ", "), choice$name),
            call. = FALSE)
  }
  list(name = choice$name, color = choice$color,
       method = paste0(method, "_ambiguous"),
       candidates = paste(unique(cands$name), collapse = ";"))
}

#' Match data labels to palette entries
#'
#' Resolves the source labels found in real datasets to the canonical entries of
#' a palette, and reports how each was resolved. Use this when you want to see or
#' audit the mapping; use [energypal_colors()] when you just want the colours.
#'
#' Matching proceeds in stages and stops at the first that succeeds for a given
#' label: exact, canonicalised (case, spacing, punctuation and digits removed),
#' declared alias, fuzzy (string distance), and finally containment, which
#' catches labels like `"Coal_Plant_2"`.
#'
#' Aliases are declared in the palette file, so a project that supplies its own
#' palette can teach the matcher its own vocabulary without any code.
#'
#' @param sources Character vector of labels from your data. Repeats are allowed;
#'   the result has one row per distinct label.
#' @param palette Name of a built-in or registered palette. Defaults to the
#'   `energypal.palette` option, or `"carriers"`.
#' @param file Path to a palette file, taking precedence over `palette`.
#' @param method Stages to apply, in order. `"auto"` (default) uses all of them;
#'   otherwise any of `"exact"`, `"canonical"`, `"alias"`, `"fuzzy"`,
#'   `"contains"`.
#' @param case_sensitive Logical; if `TRUE` the exact stage respects case
#'   (default `FALSE`). Later stages are case-insensitive by construction.
#' @param max_distance Maximum normalised edit distance for the fuzzy stage,
#'   between 0 and 1 (default `0.4`).
#' @param warn Logical; warn when a label matches entries of differing colours
#'   (default `TRUE`).
#' @param include_full_palette Logical; append palette entries that nothing in
#'   `sources` matched (default `FALSE`).
#'
#' @return A data frame with one row per distinct source and columns `original`,
#'   `matched` (entry name, or `NA`), `color`, `method` (which stage resolved it)
#'   and `candidates` (`;`-separated, when the match was ambiguous).
#' @examples
#' energypal_match(c("Coal", "natural gas", "Solar PV", "COAL1"))
#'
#' # every label the bundled dataset uses resolves
#' energypal_match(unique(owid_energy_mix$source))
#'
#' # restrict to strict matching only
#' energypal_match(c("Coal", "nat gas"), method = c("exact", "canonical"))
#' @seealso [energypal_colors()] for colours directly, [energypal()] for the palette.
#' @export
energypal_match <- function(sources,
                            palette = NULL,
                            file = NULL,
                            method = "auto",
                            case_sensitive = FALSE,
                            max_distance = 0.4,
                            warn = TRUE,
                            include_full_palette = FALSE) {
  sources <- as.character(sources)
  if (identical(method, "auto")) method <- .match_methods
  bad <- setdiff(method, .match_methods)
  if (length(bad)) {
    stop("unknown matching method(s): ", paste(bad, collapse = ", "),
         ". Available: ", paste(.match_methods, collapse = ", "), call. = FALSE)
  }

  # Matching wants the widest lookup table, unlike the plotting default: data
  # may well say "Anthracite" or "Fossil Fuels".
  tab <- energypal_table(palette = palette, file = file, include_groups = TRUE)
  lut <- .lookup_table(tab)

  src <- unique(sources)
  res <- data.frame(original = src,
                    matched = rep(NA_character_, length(src)),
                    color = rep(NA_character_, length(src)),
                    method = rep(NA_character_, length(src)),
                    candidates = rep(NA_character_, length(src)),
                    stringsAsFactors = FALSE)
  if (!length(src)) return(res)

  canon_src <- .canonicalize(src)

  # Entries a precise stage identified but which this palette gives no colour.
  # Held back until the precise stages are exhausted: a colourless subtype must
  # not stop an alias from reaching its coloured parent.
  unpublished <- rep(NA_character_, length(src))

  for (stage in method) {
    if (!stage %in% .precise_methods) {
      settle <- which(is.na(res$matched) & !is.na(unpublished))
      res$matched[settle] <- unpublished[settle]
      res$method[settle] <- "unpublished"
    }

    todo <- which(is.na(res$matched))
    if (!length(todo)) break

    for (i in todo) {
      s <- src[i]
      cs <- canon_src[i]
      if (is.na(s) || !nzchar(s)) next

      hit <- switch(stage,
        exact = {
          if (case_sensitive) lut[lut$kind == "name" & lut$term == s, , drop = FALSE]
          else lut[lut$kind == "name" & tolower(lut$term) == tolower(s), , drop = FALSE]
        },
        canonical = lut[lut$kind == "name" & lut$canon == cs, , drop = FALSE],
        alias     = lut[lut$kind != "name" & lut$canon == cs, , drop = FALSE],
        fuzzy     = {
          col <- lut[lut$has_color, , drop = FALSE]
          if (!nzchar(cs) || !nrow(col)) NULL else {
            d <- .norm_dist(col$canon, cs)
            m <- min(d)
            if (m <= max_distance) col[d <= m + 1e-8, , drop = FALSE] else NULL
          }
        },
        contains  = {
          col <- lut[lut$has_color, , drop = FALSE]
          if (!nzchar(cs) || !nrow(col)) NULL else .contains_hits(col, cs)
        }
      )

      if (is.null(hit) || !nrow(hit)) next

      # A name the palette knows but declares no colour for is an answer, not a
      # miss: the source publishes nothing for it. Remember it, and let the
      # remaining precise stages try for a colour before settling.
      if (!any(hit$has_color)) {
        if (is.na(unpublished[i])) unpublished[i] <- hit$name[1]
        next
      }
      hit <- hit[hit$has_color, , drop = FALSE]

      got <- .settle(hit, s, stage, warn)
      res$matched[i] <- got$name
      res$color[i] <- got$color
      res$method[i] <- got$method
      res$candidates[i] <- got$candidates
    }
  }

  # in case only precise stages were requested, so the loop never settled them
  settle <- which(is.na(res$matched) & !is.na(unpublished))
  res$matched[settle] <- unpublished[settle]
  res$method[settle] <- "unpublished"

  if (include_full_palette) {
    missing <- setdiff(tab$name[!is.na(tab$color) & nzchar(tab$color)], res$matched)
    if (length(missing)) {
      keep <- !duplicated(tab$name)
      extra <- tab[keep & tab$name %in% missing, , drop = FALSE]
      res <- rbind(res, data.frame(
        original = NA_character_, matched = extra$name, color = extra$color,
        method = "palette_fill", candidates = NA_character_,
        stringsAsFactors = FALSE
      ))
    }
  }

  rownames(res) <- NULL
  res
}

#' Colours for a vector of data labels
#'
#' Maps the source labels in your data straight to colours, resolving them
#' against a palette with [energypal_match()]. Labels that cannot be
#' resolved get `unmapped_color`.
#'
#' @inheritParams energypal_match
#' @param unmapped_color Colour for labels that no stage could resolve
#'   (default `"#999999"`).
#' @param gradient Logical; when several labels resolve to the *same* carrier,
#'   spread them into distinct shades of that carrier's colour instead of
#'   drawing them identically (default `FALSE`). Grouping is by resolved carrier,
#'   not by colour, so two carriers that happen to share a hex stay separate.
#' @param spread,along Passed to [energypal_gradient()] when `gradient = TRUE`.
#'
#' @return A character vector of colours, the same length and order as
#'   `sources`, named by the input labels.
#' @examples
#' energypal_colors(c("Coal", "Natural Gas", "Solar", "Wind"))
#'
#' # messy labels resolve too
#' energypal_colors(c("coal power", "nat gas", "solar pv", "COAL1"))
#'
#' # a different published palette, same labels
#' energypal_colors(c("Coal", "Natural Gas"), palette = "ipcc")
#'
#' # several series per carrier: three coal shades, one solar
#' energypal_colors(c("COAL1", "COAL2", "COAL3", "SOLAR_NY"), gradient = TRUE)
#'
#' # anything unresolved is visibly grey rather than silently wrong
#' energypal_colors(c("Coal", "Flux Capacitor"))
#' @seealso [energypal_match()] to see how each label was resolved,
#'   [energypal_gradient()] for the shading itself, [energypal()] for the palette.
#' @export
energypal_colors <- function(sources,
                             palette = NULL,
                             file = NULL,
                             method = "auto",
                             unmapped_color = "#999999",
                             case_sensitive = FALSE,
                             max_distance = 0.4,
                             warn = TRUE,
                             gradient = FALSE,
                             spread = 0.10,
                             along = c("lightness", "chroma")) {
  along <- match.arg(along)
  sources <- as.character(sources)
  m <- energypal_match(sources, palette = palette, file = file, method = method,
                            case_sensitive = case_sensitive, max_distance = max_distance,
                            warn = warn, include_full_palette = FALSE)

  pos <- match(sources, m$original)
  col <- m$color[pos]
  matched <- m$matched[pos]
  col[is.na(col)] <- unmapped_color

  if (gradient) col <- .apply_gradient(col, matched, spread, along)
  stats::setNames(col, sources)
}

#' @rdname energypal_colors
#' @export
energypal_colours <- energypal_colors
