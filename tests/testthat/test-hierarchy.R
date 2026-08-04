test_that("energypal_table flattens carriers", {
  tab <- energypal_table("carriers")
  expect_true(is.data.frame(tab))
  expect_true(all(c("name","level","parent","color","type","path","branch","palette") %in% names(tab)))
  # Expect at least the known top-level groups
  expect_true(any(tab$name == "FossilFuels"))
  expect_true(any(tab$name == "Renewable"))
  # Subtype presence
  expect_true(any(tab$type == "subtype"))
  coal_subtypes <- tab[tab$parent == "FossilCoal" & tab$type == "subtype","name"]
  expect_true("Anthracite" %in% coal_subtypes)
})

test_that("energypal_table flattens technologies", {
  tabt <- energypal_table("technologies")
  expect_true(is.data.frame(tabt))
  expect_true(any(tabt$name == "ElectricPower"))
  expect_true(any(tabt$name == "Industry"))
  # Check that a technology subtype exists
  expect_true(any(tabt$name == "CombinedCycleCCGT"))
  expect_true(all(tabt$palette == "technologies"))
})
