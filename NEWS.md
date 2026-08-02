# energypal (development version)

## Refactored ordering & direction API

- Added `custom_order`, `direction`, and `palette_direction` arguments to `scale_fill_energy()` / `scale_color_energy()`.
- Default `direction` is now `1` (aligns with conventions in `viridis` and `RColorBrewer`). Set `direction = -1` to reverse legend/source order.
- Added `geom_energy_col()` and `geom_energy_bar()` wrappers for automatic ordering and stack direction control.
- Introduced `stack_direction` (geom-level) separating physical stack order from legend/palette direction.
- Added `palette_direction` to flip palette color sequence without altering source order.
- `position_energy_stack()` retained for manual control, now documented in relation to new geoms.

## Testing & infrastructure

- New tests for palette reversal, stack inversion, and custom ordering precedence.

## Documentation

- Updated scale and geom documentation to clarify separation of legend order, palette color direction, and stack direction.

## Removed deprecated mapped scale

- Removed `scale_fill_energy_mapped()` in favor of a unified `scale_fill_energy()` interface with explicit ordering, palette, and mapping controls. Users needing intelligent mapping should first preprocess with `map_energy_colors()` or leverage future helper wrappers.
