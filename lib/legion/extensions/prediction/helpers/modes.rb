# frozen_string_literal: true

module Legion
  module Extensions
    module Prediction
      module Helpers
        module Modes
          # Four reasoning modes (spec: prediction-engine-spec.md)
          REASONING_MODES = %i[fault_localization functional_mapping boundary_testing counterfactual].freeze

          PREDICTION_CONFIDENCE_MIN = 0.65
          MAX_PREDICTIONS_PER_TICK  = 5
          PREDICTION_HORIZON        = 3600 # 1 hour default lookahead

          module_function

          def valid_mode?(mode)
            REASONING_MODES.include?(mode)
          end
        end
      end
    end
  end
end
