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

            actionable = prediction[:confidence] >= Helpers::Modes::PREDICTION_CONFIDENCE_MIN
            Legion::Logging.debug "[prediction] new: mode=#{mode} confidence=#{prediction[:confidence].round(2)} " \
                                  "actionable=#{actionable} id=#{prediction[:prediction_id][0..7]}"

            {
              prediction_id: prediction[:prediction_id],
              mode:          mode,
              confidence:    prediction[:confidence],
              actionable:    actionable
            }
          end

          def resolve_prediction(prediction_id:, outcome:, actual: nil, **)
            pred = prediction_store.resolve(prediction_id, outcome: outcome, actual: actual)
            if pred
              Legion::Logging.info "[prediction] resolved #{prediction_id[0..7]} outcome=#{outcome}"
              record_outcome_trace(pred, outcome)
              { resolved: true, prediction_id: prediction_id, outcome: outcome }
            else
              Legion::Logging.debug "[prediction] resolve failed: #{prediction_id[0..7]} not found"
              { resolved: false, reason: :not_found }
            end
          end

          def pending_predictions(**)
            preds = prediction_store.pending
            Legion::Logging.debug "[prediction] pending count=#{preds.size}"
            { predictions: preds, count: preds.size }
          end

          def prediction_accuracy(window: 100, **)
            acc = prediction_store.accuracy(window: window)
            total = prediction_store.outcomes.size
            Legion::Logging.debug "[prediction] accuracy=#{acc.round(2)} total_outcomes=#{total}"
            { accuracy: acc, total_outcomes: total }
          end

          def expire_stale_predictions(**)
            expired_count = 0

            prediction_store.pending.each do |pred|
              age = Time.now.utc - pred[:created_at]
              next unless age > pred[:horizon]

              prediction_store.resolve(pred[:prediction_id], outcome: :expired, actual: nil)
              expired_count += 1
            end

            remaining = prediction_store.pending.size
            Legion::Logging.debug "[prediction] expire sweep: expired=#{expired_count} remaining=#{remaining}"

            { expired_count: expired_count, remaining_pending: remaining }
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
                   when :fault_localization then 0.7
                   when :functional_mapping then 0.6
                   when :counterfactual     then 0.4
                   else                          0.5
                   end
            richness_bonus = [context.size * 0.02, 0.2].min
            [base + richness_bonus, 1.0].min
          end

          def record_outcome_trace(prediction, outcome)
            return unless defined?(Legion::Extensions::Memory::Runners::Traces)

            trace_params = case outcome
                           when :correct
                             { type: :semantic, valence: 0.3, intensity: 0.3, unresolved: false }
                           when :incorrect
                             { type: :episodic, valence: -0.5, intensity: 0.6, unresolved: true }
                           when :partial
                             { type: :episodic, valence: -0.2, intensity: 0.4, unresolved: true }
                           else
                             return
                           end

            runner = Object.new.extend(Legion::Extensions::Memory::Runners::Traces)
            runner.store_trace(
              type:                trace_params[:type],
              content_payload:     "prediction #{outcome}: mode=#{prediction[:mode]} confidence=#{prediction[:confidence]}",
              domain_tags:         ['prediction', prediction[:mode].to_s],
              origin:              :direct_experience,
              emotional_valence:   trace_params[:valence],
              emotional_intensity: trace_params[:intensity],
              unresolved:          trace_params[:unresolved],
              confidence:          prediction[:confidence]
            )

            store = runner.send(:default_store)
            store.flush if store.respond_to?(:flush)

            Legion::Logging.debug "[prediction] created #{trace_params[:type]} trace for #{outcome} prediction"
          rescue StandardError => e
            Legion::Logging.warn "[prediction] failed to create outcome trace: #{e.message}"
          end
        end
      end
    end
  end
end
