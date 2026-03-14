# lex-prediction

Forward-model prediction engine for brain-modeled agentic AI. Implements four reasoning modes for generating, tracking, and evaluating predictions about future states.

## Overview

`lex-prediction` gives the agent the ability to reason about what is likely to happen next. Predictions are made in one of four modes, tracked as pending until resolved, and used to build an accuracy record that informs future confidence estimates.

## Reasoning Modes

| Mode | Description | Default Confidence |
|------|-------------|-------------------|
| `fault_localization` | Predict where a system failure is occurring | 0.70 |
| `functional_mapping` | Predict how components relate and interact | 0.60 |
| `boundary_testing` | Predict what will happen at edge conditions | 0.50 |
| `counterfactual` | Reason about what would have happened differently | 0.40 |

Confidence is boosted by up to 0.20 based on context richness (0.02 per context key).

## Installation

Add to your Gemfile:

```ruby
gem 'lex-prediction'
```

## Usage

### Making a Prediction

```ruby
require 'legion/extensions/prediction'

result = Legion::Extensions::Prediction::Runners::Prediction.predict(
  mode: :fault_localization,
  context: { service: "auth", error_rate: 0.45, last_deploy: "2h ago" },
  description: "Auth service failure likely due to recent deploy"
)
# => { prediction_id: "uuid", mode: :fault_localization,
#      confidence: 0.76, actionable: true }

# Predictions with confidence >= 0.65 are flagged as actionable
```

### Resolving Predictions

```ruby
# When the outcome is known
Legion::Extensions::Prediction::Runners::Prediction.resolve_prediction(
  prediction_id: "uuid",
  outcome: :correct,
  actual: { root_cause: "deploy rollback needed" }
)
```

### Querying Predictions

```ruby
# Pending predictions
Legion::Extensions::Prediction::Runners::Prediction.pending_predictions

# Overall accuracy
Legion::Extensions::Prediction::Runners::Prediction.prediction_accuracy(window: 100)
# => { accuracy: 0.73, total_outcomes: 45 }

# Get a specific prediction
Legion::Extensions::Prediction::Runners::Prediction.get_prediction(prediction_id: "uuid")
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
