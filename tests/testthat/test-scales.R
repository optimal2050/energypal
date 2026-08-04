skip_if_not_installed("ggplot2")
library(ggplot2)

dat <- subset(owid_energy_mix, year == max(owid_energy_mix$year))
base_plot <- function(...) {
  ggplot(dat, aes(country, percentage, fill = source)) + geom_col() + ...
}
fills_of <- function(p) unique(ggplot_build(p)$data[[1]]$fill)
scale_of <- function(p) ggplot_build(p)$plot$scales$scales[[1]]

test_that("the discrete scale colours the data's own labels", {
  p <- ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
    scale_fill_energy()
  got <- fills_of(p)
  expected <- unname(energypal_colors(unique(dat$source), warn = FALSE))
  expect_true(all(got %in% expected))
  expect_false(any(got == "#999999"))   # everything resolved
})

test_that("fills agree with energypal_colors for the same labels", {
  p <- ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
    scale_fill_energy()
  sc <- scale_of(p)
  lv <- sc$get_limits()
  expect_identical(unname(sc$palette(length(lv))),
                   unname(energypal_colors(lv, warn = FALSE)))
})

test_that("a factor's own level order is respected", {
  # ggplot2 users control sequence by setting factor levels; the scale must not
  # quietly override that. Only an explicit `order` may.
  lv <- c("Wind", "Solar", "Coal", "Nuclear", "Hydro", "Natural Gas",
          "Oil", "Bioenergy", "Other")
  d2 <- dat
  d2$src <- factor(d2$source, levels = lv)

  p <- ggplot(d2, aes(country, percentage, fill = src)) + geom_col() +
    scale_fill_energy()
  expect_identical(scale_of(p)$get_limits(), lv)

  # direction alone still applies
  p_rev <- ggplot(d2, aes(country, percentage, fill = src)) + geom_col() +
    scale_fill_energy(direction = -1)
  expect_identical(scale_of(p_rev)$get_limits(), rev(lv))

  # ...and an explicit order takes precedence over the factor levels
  p_ord <- ggplot(d2, aes(country, percentage, fill = src)) + geom_col() +
    scale_fill_energy(order = "carbon_intensity")
  expect_identical(scale_of(p_ord)$get_limits()[1:3], c("Coal", "Oil", "Natural Gas"))
})

test_that("order changes the legend but not any carrier's colour", {
  colour_by_source <- function(o) {
    p <- ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
      scale_fill_energy(order = o)
    sc <- scale_of(p)
    lv <- sc$get_limits()
    stats::setNames(sc$palette(length(lv)), lv)
  }
  base <- colour_by_source(NULL)
  for (o in c("carbon_intensity", "merit_order", "alpha")) {
    got <- colour_by_source(o)
    expect_setequal(names(got), names(base))
    expect_identical(base[names(got)], got)      # same colour per label
    expect_false(identical(names(got), names(base)))
  }
})

test_that("carbon_intensity orders the legend sensibly", {
  p <- ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
    scale_fill_energy(order = "carbon_intensity")
  lv <- scale_of(p)$get_limits()
  # the three fossil fuels lead, in descending intensity
  expect_identical(lv[1:3], c("Coal", "Oil", "Natural Gas"))
  expect_lt(match("Coal", lv), match("Wind", lv))
})

test_that("an ordering declared at carrier level covers subtype labels", {
  # "Natural Gas" resolves to the NaturalGas subtype, which carbon_intensity
  # does not name; it must inherit FossilGas's position rather than sort last.
  p <- ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
    scale_fill_energy(order = "carbon_intensity")
  lv <- scale_of(p)$get_limits()
  expect_lt(match("Natural Gas", lv), match("Solar", lv))
})

test_that("direction reverses the legend", {
  fwd <- scale_of(ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
                    scale_fill_energy(order = "carbon_intensity"))$get_limits()
  rev_ <- scale_of(ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
                     scale_fill_energy(order = "carbon_intensity",
                                       direction = -1))$get_limits()
  expect_identical(rev(fwd), rev_)
})

test_that("label_style relabels the legend without changing colours", {
  cols <- function(ls) {
    p <- ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
      scale_fill_energy(label_style = ls)
    sc <- scale_of(p)
    sc$palette(length(sc$get_limits()))
  }
  expect_identical(cols("asis"), cols("id"))
  expect_identical(cols("asis"), cols("long"))

  labs <- function(ls) {
    p <- ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
      scale_fill_energy(label_style = ls)
    scale_of(p)$get_labels()
  }
  expect_true("Natural Gas" %in% labs("asis"))
  expect_true("NaturalGas" %in% labs("id"))
  expect_true("Hydroelectric Power" %in% labs("long"))
})

test_that("switching palette changes the fills", {
  f1 <- fills_of(ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
                   scale_fill_energy(palette = "carriers"))
  f2 <- fills_of(ggplot(dat, aes(country, percentage, fill = source)) + geom_col() +
                   scale_fill_energy(palette = "ipcc"))
  expect_false(identical(sort(f1), sort(f2)))
})

test_that("unresolvable labels get unmapped_color", {
  d2 <- data.frame(x = c("Coal", "Flux Capacitor"), y = c(1, 1))
  p <- ggplot(d2, aes(x, y, fill = x)) + geom_col() +
    scale_fill_energy(unmapped_color = "#123456")
  expect_true("#123456" %in% fills_of(p))
})

test_that("gradient shades labels that share a carrier", {
  d2 <- data.frame(x = c("COAL1", "COAL2", "COAL3"), y = c(1, 1, 1))
  plain <- fills_of(ggplot(d2, aes(x, y, fill = x)) + geom_col() + scale_fill_energy())
  shaded <- fills_of(ggplot(d2, aes(x, y, fill = x)) + geom_col() +
                       scale_fill_energy(gradient = TRUE))
  expect_length(plain, 1)
  expect_length(shaded, 3)
})

test_that("colour and color scales are the same function", {
  expect_identical(scale_color_energy, scale_colour_energy)
  expect_identical(scale_color_energy_c, scale_colour_energy_c)
  expect_identical(scale_color_energy_b, scale_colour_energy_b)
})

test_that("the colour aesthetic works too", {
  p <- ggplot(dat, aes(country, percentage, colour = source)) + geom_point() +
    scale_colour_energy()
  expect_false(inherits(try(ggplot_build(p), silent = TRUE), "try-error"))
})

test_that("a type mismatch is refused with a message naming the alternative", {
  expect_error(scale_fill_energy(palette = "windatlas_speed"),
               "needs a discrete palette")
  expect_error(scale_fill_energy(palette = "windatlas_speed"),
               "scale_\\*_energy_c\\(\\)")
  expect_error(scale_fill_energy_c(palette = "carriers"),
               "needs a continuous palette")
  expect_error(scale_fill_energy_b(palette = "carriers"),
               "needs a continuous palette")
})

test_that("continuous and binned scales build", {
  grid <- expand.grid(x = 1:12, y = 1:8)
  grid$w <- seq(2, 17, length.out = nrow(grid))

  pc <- ggplot(grid, aes(x, y, fill = w)) + geom_raster() +
    scale_fill_energy_c(palette = "windatlas")
  pb <- ggplot(grid, aes(x, y, fill = w)) + geom_raster() +
    scale_fill_energy_b(palette = "windatlas")

  expect_false(inherits(try(ggplot_build(pc), silent = TRUE), "try-error"))
  expect_false(inherits(try(ggplot_build(pb), silent = TRUE), "try-error"))
})

test_that("the binned scale takes its breaks from the palette", {
  grid <- expand.grid(x = 1:12, y = 1:8)
  grid$w <- seq(2, 17, length.out = nrow(grid))
  p <- ggplot(grid, aes(x, y, fill = w)) + geom_raster() +
    scale_fill_energy_b(palette = "windatlas")
  declared <- as.numeric(unlist(energypal_spec("windatlas")$breaks))
  expect_identical(scale_of(p)$breaks, declared)

  # ...and an explicit breaks argument wins
  p2 <- ggplot(grid, aes(x, y, fill = w)) + geom_raster() +
    scale_fill_energy_b(palette = "windatlas", breaks = c(5, 10, 15))
  expect_identical(scale_of(p2)$breaks, c(5, 10, 15))
})

test_that("a family name resolves in the scales", {
  grid <- expand.grid(x = 1:6, y = 1:4)
  grid$w <- seq(2, 17, length.out = nrow(grid))
  p <- ggplot(grid, aes(x, y, fill = w)) + geom_raster() +
    scale_fill_energy_b(palette = "windatlas")
  expect_false(inherits(try(ggplot_build(p), silent = TRUE), "try-error"))
})

test_that("many-bin legends are thinned rather than left unreadable", {
  brk <- as.numeric(unlist(energypal_spec("windatlas")$breaks))
  expect_gt(length(brk), 12)                       # the case that needed thinning
  args <- .thin_labels(brk, list())
  expect_true(is.function(args$labels))
  shown <- args$labels(brk)
  expect_length(shown, length(brk))                # every bin still present
  expect_lte(sum(nzchar(shown)), 10)               # but at most ten labelled

  # a caller-supplied labels argument is left alone
  expect_identical(.thin_labels(brk, list(labels = "mine"))$labels, "mine")
})

test_that("the binned scale uses the palette's declared bins, not a resample", {
  # scale_*_stepsn() positions each bin by where its midpoint falls in the data
  # range, so the declared colours only appeared when the data happened to span
  # the declared breaks. With data running wider, both ends were unreachable:
  # 20 m/s and 27 m/s drew as the 25th of 31 stops instead of the last.
  pal <- energypal("windatlas_speed")
  brk <- as.numeric(unlist(energypal_spec("windatlas_speed")$breaks))
  expect_identical(length(pal), length(brk) + 1L)

  # one value per bin: below the first break, each interior midpoint, above the last
  v <- c(min(brk) - 5, brk[-length(brk)] + diff(brk) / 2, max(brk) + 10)
  d <- data.frame(x = seq_along(v), v = v)
  b <- ggplot2::ggplot_build(
    ggplot2::ggplot(d, ggplot2::aes(x, 1, fill = v)) +
      ggplot2::geom_raster() +
      scale_fill_energy_b(palette = "windatlas")
  )
  fills <- b$data[[1]]$fill

  # below the first break and above the last take the open-ended bins' colours
  expect_identical(fills[1], pal[[1]])
  expect_identical(fills[length(fills)], pal[[length(pal)]])
  # and every bin midpoint takes its own declared colour, in order
  expect_identical(fills, unname(pal))
})

test_that("an explicit breaks argument still maps one colour per bin", {
  pal <- energypal("windatlas_speed")
  b <- ggplot2::ggplot_build(
    ggplot2::ggplot(data.frame(x = 1:3, v = c(0, 6, 40)), ggplot2::aes(x, 1, fill = v)) +
      ggplot2::geom_raster() +
      scale_fill_energy_b(palette = "windatlas", breaks = c(5, 10))
  )
  # three bins from two breaks, taking the first three palette colours
  expect_identical(b$data[[1]]$fill, unname(pal[1:3]))
})
