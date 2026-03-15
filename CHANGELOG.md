# Changelog

## [0.1.1] - 2026-03-14

### Added
- `ExpirePredictions` actor (Every 300s): expires predictions older than `PREDICTION_HORIZON` (3600s) by resolving them as `:expired`, enforcing the previously defined-but-not-enforced constant via `expire_stale_predictions` in `runners/prediction.rb`

## [0.1.0] - 2026-03-13

### Added
- Initial release
