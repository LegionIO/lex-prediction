# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Prediction
      module Actor
        class ExpirePredictions < Legion::Extensions::Actors::Every
          def runner_class
            Legion::Extensions::Prediction::Runners::Prediction
          end

          def runner_function
            'expire_stale_predictions'
          end

          def time
            300
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
