# lex-prediction

**Level 3 Documentation**
- **Parent**: `extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Forward-model prediction engine for the LegionIO cognitive architecture. Implements four reasoning modes for making, tracking, and resolving predictions. Maintains a rolling accuracy record to calibrate future confidence estimates.

## Gem Info

- **Gem name**: `lex-prediction`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Prediction`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/prediction/
  version.rb
  helpers/
    modes.rb             # REASONING_MODES, PREDICTION_CONFIDENCE_MIN, MAX_PREDICTIONS_PER_TICK, PREDICTION_HORIZON
    prediction_store.rb  # PredictionStore class - pending/resolved predictions, accuracy computation
  runners/
    prediction.rb        # predict, resolve_prediction, pending_predictions, prediction_accuracy, get_prediction
spec/
  legion/extensions/prediction/
    runners/
      prediction_spec.rb
    client_spec.rb
```

## Key Constants (Helpers::Modes)

```ruby
REASONING_MODES           = %i[fault_localization functional_mapping boundary_testing counterfactual]
PREDICTION_CONFIDENCE_MIN = 0.65   # below this, prediction is not actionable
MAX_PREDICTIONS_PER_TICK  = 5
PREDICTION_HORIZON        = 3600   # 1 hour default lookahead in seconds
```

## PredictionStore Class

`Helpers::PredictionStore` holds:
- `@predictions` - Hash of prediction_id => prediction hash
- `@outcomes` - Array of resolved outcomes

Prediction hash structure:
```ruby
{
  prediction_id: "uuid",
  mode:          :fault_localization,
  context:       {},
  confidence:    0.76,
  description:   nil,
  status:        :pending,
  created_at:    Time,
  horizon:       3600
}
```

`resolve(prediction_id, outcome:, actual:)` transitions `status` to `:resolved`, appends to `@outcomes`.

`accuracy(window:)` computes fraction of `:correct` outcomes in the last N resolved predictions.

## Confidence Estimation

`estimate_confidence(mode, context)` computes base confidence per mode, then adds `[context.size * 0.02, 0.2].min` richness bonus. Context richness is a proxy for how much information the agent has to reason with.

## Integration Points

- **lex-tick**: `prediction_engine` phase calls `predict` with current context
- **lex-emotion**: emotional state context passed in prediction context hash
- **lex-memory**: memory retrieval results populate prediction context

## Development Notes

- `MAX_PREDICTIONS_PER_TICK = 5` is defined as a constant but not enforced by the runner (enforcement is the caller's responsibility)
- `PREDICTION_HORIZON` is stored on the prediction but not actively used for expiration in the current implementation
- `prediction_accuracy` returns 0.0 if no outcomes have been resolved yet
