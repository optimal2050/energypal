test_that("palette_direction changes color values while keeping legend order", {
  skip_if_not_installed("ggplot2"); library(ggplot2)
  d <- data.frame(source=c("Coal","Solar","Wind"), value=1:3)
  sc1 <- ggplot_build(ggplot(d,aes(x=1,y=value,fill=source))+geom_col()+scale_fill_energy(direction=1,palette_direction=1,data=d))$plot$scales$scales[[1]]
  sc2 <- ggplot_build(ggplot(d,aes(x=1,y=value,fill=source))+geom_col()+scale_fill_energy(direction=1,palette_direction=-1,data=d))$plot$scales$scales[[1]]
  lim1 <- sc1$get_limits(); lim2 <- sc2$get_limits(); expect_equal(lim1, lim2)
  vals1 <- sc1$palette(length(lim1))
  vals2 <- sc2$palette(length(lim2))
  expect_false(identical(vals1, vals2))
  # Ensure at least one source color differs
  diffs <- vals1 != vals2
  expect_true(any(diffs))
})

test_that("stack_direction changes physical stacking order", {
  skip_if_not_installed("ggplot2")
  library(ggplot2)
  d <- data.frame(source = c("Coal","Gas","Wind","Solar"), value = c(4,3,2,1))
  p_bottom <- ggplot(d, aes(x=1, y=value, fill=source)) +
    geom_energy_col(stack_direction = -1)
  p_top <- ggplot(d, aes(x=1, y=value, fill=source)) +
    geom_energy_col(stack_direction = 1)
  b_bottom <- ggplot_build(p_bottom)
  b_top <- ggplot_build(p_top)
  # Order by ymin to get bottom->top sequence of fills
  get_stack_order <- function(b) {
    layer <- b$data[[1]][, c("fill","ymin","ymax")]
    layer <- layer[order(layer$ymin),]
    unique(layer$fill)
  }
  order_bottom <- get_stack_order(b_bottom)
  order_top <- get_stack_order(b_top)
  expect_false(identical(order_bottom, order_top))
})

test_that("custom_order supersedes order_method", {
  skip_if_not_installed("ggplot2")
  library(ggplot2)
   d <- data.frame(source = c("Coal","Natural Gas","Wind","Solar"), value = 1:4)
   custom <- c("Solar","Wind","Natural Gas","Coal")
  p <- ggplot(d, aes(x=1, y=value, fill=source)) +
    geom_energy_col(stack_direction = -1, direction = 1) +
    scale_fill_energy(custom_order = custom, direction = 1, data=d)
  b <- ggplot_build(p)
  limits <- b$plot$scales$scales[[1]]$get_limits()
  expect_equal(limits[1:4], custom)  # Legend order matches custom
})