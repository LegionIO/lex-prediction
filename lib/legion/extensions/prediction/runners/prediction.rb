# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Prediction
      module Runners
        module Prediction
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def predict(mode:, context: {}, confidence: nil, description: nil, **)
            return { error: :invalid_mode, valid_modes: Helpers::Modes::REASONING_MODES } unless Helpers::Modes.valid_mode?(mode)

            prediction = {
              prediction_id: SecureRandom.uuid,
              mode:          mode,
              context:       context,
              confidence:    confidence || estimate_confidence(mode, context),
              description:   description,
              status:        :pending,
              created_at:    Time.now.utc,
              horizon:       Helpers::Modes::PREDICTION_HORIZON
            }

            prediction_store.store(prediction)

            {
              prediction_id: prediction[:prediction_id],
              mode:          mode,
              confidence:    prediction[:confidence],
              actionable:    prediction[:confidence] >= Helpers::Modes::PREDICTION_CONFIDENCE_MIN
            }
          end

          def resolve_prediction(prediction_id:, outcome:, actual: nil, **)
            pred = prediction_store.resolve(prediction_id, outcome: outcome, actual: actual)
            if pred
              { resolved: true, prediction_id: prediction_id, outcome: outcome }
            else
              { resolved: false, reason: :not_found }
            end
          end

          def pending_predictions(**)
            preds = prediction_store.pending
            { predictions: preds, count: preds.size }
          end

          def prediction_accuracy(window: 100, **)
            { accuracy: prediction_store.accuracy(window: window), total_outcomes: prediction_store.outcomes.size }
          end

          def get_prediction(prediction_id:, **)
            pred = prediction_store.get(prediction_id)
            pred ? { found: true, prediction: pred } : { found: false }
          end

          private

          def prediction_store
            @prediction_store ||= Helpers::PredictionStore.new
          end

          def estimate_confidence(mode, context)
            base = case mode
                   when :fault_localization  then 0.7
                   when :functional_mapping  then 0.6
                   when :boundary_testing    then 0.5
                   when :counterfactual      then 0.4
                   else 0.5
                   end
            # Context richness boosts confidence
            richness_bonus = [context.size * 0.02, 0.2].min
            [base + richness_bonus, 1.0].min
          end
        end
      end
    end
  end
end
